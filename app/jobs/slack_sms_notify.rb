require "uri"
require "net/http"

class SlackSMSNotify

  SLACK_SMS_WEBHOOK = ENV['SLACK_SMS_WEBHOOK']
  SLACK_ERRORS_WEBHOOK = ENV['SLACK_ERRORS_WEBHOOK']
  DOMAIN = ENV['DOMAIN']

  def self.send_error(text)
    self.send("#{DOMAIN} - #{text}", [], 'error')
  end

  def self.send_error_attachments(attachments)
    self.send(nil, attachments, 'error')
  end

  def self.send(text, attachments=[], channel=nil)
    return unless Rails.env.production?
    payload = {text:text, 
      attachments: attachments}
    self.send_payload(payload, channel)
  end

  def self.send_payload(payload, channel)
    if channel == 'error'
      slack_webhook = SLACK_ERRORS_WEBHOOK
    else
      slack_webhook = SLACK_SMS_WEBHOOK
    end
    uri = URI.parse(slack_webhook)

    params = { payload: payload.to_json }
    req = Net::HTTP::Post.new uri.request_uri
    req.set_form_data params

    # send request
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true
    http.request req
  end
end