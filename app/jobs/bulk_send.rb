class BulkSend
  extend RetriedJob, JobHooks

  DOMAIN = ENV['DOMAIN']

  @queue = :bulk_send

  def self.perform(message, to_user_ids, sender_phone = nil)
    puts "********* BulkSend Start #{!sender_phone.nil? ? 'sender: ' + sender_phone : ''} users:#{to_user_ids.count} *********"
    to_users = User.where(id: to_user_ids)
    to_send_count = to_users.length
    messages_sent = 0
    messages_failed = 0
    errors = []
    to_users.each do |user|
      puts "Sending message to #{user.phone}"
      begin
        result = user.messages.create(
          body: message,
          from_us: true)
        if result
          messages_sent += 1
        else
          messages_failed += 1
          errors << {phone: user.phone, messages: user.errors}
          p user.errors
        end
      rescue => e
        if e.try(:code) && e.code == 21610
          Raven.capture_exception(e)
          to_send_count -= 1
        else
          puts "bulk_send >> Exception: #{e}"
          Raven.capture_exception(e)
          messages_failed += 1
          errors << {phone: user.phone, messages: e}
        end
      end
    end
    # Send Slack failure
    if messages_failed > 0
      fields = []
      errors.each do |error|
        fields << {
          "title": error[:phone],
          "value": error[:messages]
        }
      end
      if sender_phone.nil?
        pretext = "Bulk Send failed for to_user_ids: #{to_user_ids}"
      else
        pretext = "Bulk Send failed for sender #{sender_phone}"
      end
      attachment = {
        "pretext": pretext,
        "fallback": "Bulk Send Failure",
        "color": "danger",
        "author_name": "#{DOMAIN}",
        "fields": fields}
      SlackSMSNotify.send_error_attachments([attachment])
    end

    # send summary to slack
    attachment = self.generate_send_summary_attachment(
      message, 
      sender_phone,
      messages_sent,
      messages_failed,
      to_send_count)
    SlackSMSNotify.send(nil, [attachment])

    puts "********* BulkSend Finished #{!sender_phone.nil? ? 'sender: ' + sender_phone : ''} users: #{to_user_ids.count} *********"
  end


  def self.generate_send_summary_attachment(
      message, 
      sender_phone, 
      messages_sent, 
      messages_failed, 
      messages_total)
    fallback = "Bulk Send Summary - #{sender_phone} - sent: #{messages_sent}/#{messages_total}, failed: #{messages_failed}"
    if messages_failed > 0
      color = "danger"
      text = "Messages sent: #{messages_sent}/#{messages_total}. Failed: #{messages_failed}"
    else
      color = "good"
      text = "Messages sent: #{messages_sent}/#{messages_total}"
    end
    truncated_message = message[0..40].gsub(/\s\w+\s*$/, '...')
    if sender_phone
      footer = "#{sender_phone} - \"#{truncated_message}\" - #{DOMAIN}"
    else
      footer = "\"#{truncated_message}\" - #{DOMAIN}"
    end
    return {
      "fallback": fallback,
      "color": color,
      "text": text,
      "footer": footer,
      "ts": Time.now.to_i
    }
  end
end
