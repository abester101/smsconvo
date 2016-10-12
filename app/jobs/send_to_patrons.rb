class SendToPatrons
  extend RetriedJob, JobHooks

  BATCH_SEND_USER_COUNT = ENV['BATCH_SEND_USER_COUNT']
  BATCH_SEND_INTERVAL = ENV['BATCH_SEND_INTERVAL']

  @queue = :send_to_patrons

  def self.perform(message)
    puts "********* SendToPatrons Start message: #{message} *********"
    patrons = User.patronage.subscribed
    step = BATCH_SEND_USER_COUNT.to_i
    interval = BATCH_SEND_INTERVAL.to_i
    start_index = 0
    i = 0
    (start_index..(patrons.length - 1)).step(step).each do |index|
      to_index = (index + step - 1)
      batched_patrons = patrons[index..to_index]
      puts "batched_patrons: #{batched_patrons.map{|patron| patron.phone}}"
      to_user_ids = batched_patrons.map{|u| u.id}
      enqueue_in = (i * interval).seconds
      i += 1
      p "batch \##{index} to \##{to_index} enqueue_in: #{enqueue_in}"
      Resque.enqueue_in(
        enqueue_in, 
        BulkSend, 
        message,
        to_user_ids,
        nil)
    end
    puts "********* SendToPatrons Finished message: #{message} *********"
  end
end

