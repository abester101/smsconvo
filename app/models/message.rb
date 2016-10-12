class Message < ApplicationRecord
  belongs_to :user
  after_create :deliver

  TWILIO_SID = ENV['TWILIO_SID']
  TWILIO_TOKEN = ENV['TWILIO_TOKEN']

  def deliver
    # p "Will deliver: #{self.body}"    
    if self.from_us
      if self.user && self.user.sender
        client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)
        message = {from: self.user.sender.phone, to: self.user.phone, body: self.body}
        if self.media_url
          message[:media_url] = self.media_url
        end
        client.messages.create(message)
        self.update_attribute :delivered, true
        # p "Delivered: #{self.body}"    
      else
        message = "Could not deliver message ##{self.id}. Missing data - user: #{self.user}, sender: #{self.user.sender}"
        SlackSMSNotify.send_error(message)
      end
    end
  end
end
