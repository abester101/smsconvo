require 'uri'

class Api::V1::UsersController < ApplicationController
  protect_from_forgery with: :null_session
  # before_action :restrict_access
  after_action :set_cors
  respond_to :json

  def create
    if params[:needs_verification]
      create_user_with_verify_code(params)
    else
      create_user(params)
    end
  end

  def welcome
    phone = params[:phone]
    send_app_link = params[:send_app_link]
    user = User.find_by(phone: phone)
    if user
      if send_app_link == "false"
        send_app_link = false
      end
      if !user.sent_welcome
        user.send_welcome_message(send_app_link)
      end
      render json: user
    else
      render json: nil
    end
  end

  def update_patron
    phone = params[:phone]
    user = User.find_by(phone: phone)
    if user 
      patron_product = params[:patron_product]
      return bad_request("Missing patron product") if patron_product.nil?
      if user.update(patron_product: patron_product)
        render json: user
      else
        return server_error("Could not update patron")
      end
    else
      return not_found("User")
    end
  end

  private

  def create_user(params)
    user = User.new(user_params)
    if user.save
      user.send_welcome_message(true)
      render json: user
    else 
      render json: {error: "Could not save phone number."}
    end
  end

  def create_user_with_verify_code(params)
    phone = params[:phone]
    # find or create user with phone
    user = User.find_or_initialize_by(phone: phone)
    if user.new_record?
      begin
        if !user.save!
          return verify_error(phone, user.errors.inspect)
        end
      rescue ActiveRecord::RecordInvalid => invalid
        return verify_error(phone, invalid.record.errors.inspect)
      rescue => e
        return verify_error(phone, e.inspect)
      end
    end
    # send verification code to user
    verify_code = generate_verify_code
    verify_message = "Your Hardbound verification code is #{verify_code}"
    begin
      message = user.messages.create(body: verify_message, from_us: true)
    rescue => e
      puts "Caught exception when trying to create message: #{e.inspect}"
      return verify_error(phone, e)
    end
    if message
      user_json = user.attributes.merge!({"verify_code": verify_code})
      render json: user_json
    else
      verify_error(phone, "Message not created")
    end
  end

  def verify_error(phone, error)
    SlackSMSNotify.send_error("Create user w/ verification failed for phone: #{phone}\n#{error}")
    render json: { errors: error }, :status => 400
  end

  def generate_verify_code
    "#{rand(0..9)}#{rand(0..9)}#{rand(0..9)}#{rand(0..9)}"
  end

  def user_params
    params.permit(:needs_verification, :phone, :created_from, :send_app_link)
  end

  def set_cors
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def restrict_access
    access_token = request.headers['authorization']
    api_key = ApiKey.find_by_access_token(access_token)
    head :unauthorized unless api_key
  end

  # Error Handlers

  def not_found(model_name)
    render json: {error: "#{model_name} not found"}.to_json, status: 404
  end

  def bad_request(message)
    render json: {error: message}.to_json, status: 400
  end

  def server_error(message)
    render json: {error: mesage}.to_json, status: 500
  end
end