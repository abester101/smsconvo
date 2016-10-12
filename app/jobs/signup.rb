
class Signup
  extend RetriedJob, JobHooks

  DOMAIN = ENV['DOMAIN']
  @queue = :signup

  def self.perform(user_id, send_app_link)
    user = User.find(user_id)
    phone_number = URI::encode(user.sender.phone)
    puts "send_app_link: #{send_app_link}"
    if send_app_link
      message_body = 
        "Welcome to Hardbound! Here's how this works: every Thursday morning we'll text "\
        "you our new story. Text us back! A real human (named Nathan) will respond. "\
        "He'd love to hear from you.\n\n"\
        "If you want email instead of sms, just text us your email and we'll move you "\
        "over. If you don't want any notifs, just text \"none\" and we'll unsubscribe you.\n\n"\
        "PS - here's our app, so you can read our stories in fullscreen. "\
        "It's \*way\* better https://appsto.re/i6hK9DL"
    else
      message_body = 
        "Welcome to Hardbound! Here's how this works: every Thursday morning we'll text "\
        "you our new story. Text us back! A real human (named Nathan) will respond. "\
        "He'd love to hear from you.\n\n"\
        "If you want email instead of sms, just text us your email and we'll move you "\
        "over. If you don't want any notifs, just text \"none\" and we'll unsubscribe you."
    end
    user.messages.create(
      body: message_body,
      from_us: true
    )
    user.update(sent_welcome: true)
  end
end

