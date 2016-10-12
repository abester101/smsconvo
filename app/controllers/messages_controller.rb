class MessagesController < ApplicationController

  http_basic_authenticate_with name: "hb", password: "sup3rs3cr3t", only: [:new]

  skip_before_action :verify_authenticity_token
  respond_to :json, only: ['send_all']

  def inbound
    $stderr.puts params
    user = User.find_by(phone: params['From'])
    if user
      user.update_attributes(
        zip: params['FromZip'].to_i,
        state: params['FromState'],
        city: params['FromCity'],
        country: params['FromCountry']
      )
      body = params['Body']

      if opt_out?(body)
        user.update(subscribed: false)
        return head :ok
      elsif opt_in?(body)
        user.update(subscribed: true)
        SlackSMSNotify.send("#{user.phone} subscribed")
        return head :ok
      end

      msg = user.messages.build(body: body, from_us: false)
      if params['NumMedia'] == '1'
        msg.media_type = params['MediaContentType0']
        msg.media_url = params['MediaUrl0']
      end
      if msg.save
        # user.messages.create(body: "Got it 👌\n\nWe'll get back to you ASAP (real humans are behind this).", from_us: true)
        user.update_attribute :needs_response, true
        if MailSubscriber.is_email_address?(body)
          MailSubscriber.move_user_to_email(user, body)
        else
          link = "<#{ENV['DOMAIN']}/users/#{user.id}>"
          SlackSMSNotify.send("#{user.phone} replied: #{link}\n```#{body}\n```")
        end
      end
    else
      # Todo - in the future, just create a user
      $stderr.puts 'Couldnt find user ' + params['From']
    end

    head :ok
  end

  def create
    user = User.find(params[:user_id])
    user.messages.create(body: params['message']['body'], from_us: true, delivered: false)
    user.update_attribute :needs_response, false
    redirect_to user
  end

  def new
    @all_user_count = User.subscribed.count
    @patron_user_count = User.patronage.subscribed.count
  end

  def send_to_patrons
    message = params['message']['body']
    Resque.enqueue(SendToPatrons, message)
    render json: {success: message}
  end

  def send_to_all
    message = params['message']['body']
    Resque.enqueue(SendToAll, message)
    render json: {success: message}
  end

  private 

  def opt_out?(body)
    ['STOP','STOPALL','UNSUBSCRIBE','CANCEL','END','QUIT','NONE'].select{ |a| a.casecmp(body) == 0 }.count > 0
  end

  def opt_in?(body)
    ['START','YES','UNSTOP'].select{ |a| a.casecmp(body) == 0 }.count > 0
  end
end
