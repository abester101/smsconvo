class MailSubscriber
  def initialize(args)
    mailchimp = Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
  end
  
  def self.is_email_address?(text)
    !(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match(text.strip)).nil?
  end

  def self.move_user_to_email(user, email)
    begin
      mailchimp = Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
      mailchimp.lists.subscribe(ENV['MAILCHIMP_LIST_ID'], email: email)
    rescue Mailchimp::Error => e
      Raven.capture_exception(e)
    end
    user.update(subscribed: false)
  end
end