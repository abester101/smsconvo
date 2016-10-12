class UsersController < ApplicationController
  http_basic_authenticate_with name: "hb", password: "sup3rs3cr3t"
  
  def index
    @needs_response = User.subscribed.needs_response.order(:updated_at)
    @recent = User.subscribed.responded.order(:updated_at)
    @unsubscribed = User.unsubscribed.order(:updated_at)
  end

  def show
    @user = User.find(params[:id])
    @messages = @user.messages.order(:created_at)
  end

  def new
  end

  def create
    user = User.new(user_params)
    if user.save
      user.send_welcome_message(true)
      head :created
    else 
      SlackSMSNotify.send_error("User sign up failed for phone: #{user_params[:phone]}\n#{user.errors.messages}")
      puts "user sign up failed: #{user.errors.messages}"
      head :bad_request
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      head :ok
    end
  end
  
  private

  def user_params
    params.permit(:phone, :needs_response, :subscribed)
  end
end
