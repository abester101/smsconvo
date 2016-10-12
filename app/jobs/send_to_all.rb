class SendToAll
  extend RetriedJob, JobHooks

  BATCH_SEND_USER_COUNT = ENV['BATCH_SEND_USER_COUNT']
  BATCH_SEND_INTERVAL = ENV['BATCH_SEND_INTERVAL']

  @queue = :send_to_all

  def self.perform(message)
    puts "********* SendToAll Start message: #{message} *********"
    Sender.all.each do |sender|
      users = sender.users.subscribed
      step = BATCH_SEND_USER_COUNT.to_i
      interval = BATCH_SEND_INTERVAL.to_i
      start_index = 0
      i = 0
      (start_index..(users.length - 1)).step(step).each do |index|
        to_index = (index + step - 1)
        batched_users = users[index..to_index]
        to_user_ids = batched_users.map{|u| u.id}
        enqueue_in = (i * interval).seconds
        i += 1
        p "batch #{index}/#{to_index} enqueue_in: #{enqueue_in}"
        Resque.enqueue_in(
          enqueue_in, 
          BulkSend, 
          message,
          to_user_ids, 
          sender.phone)
      end
    end
    puts "********* SendToAll Finished message: #{message} *********"
  end
end

