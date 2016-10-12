class GenerateSender
  extend RetriedJob, JobHooks

  MAX_SENDER_USERS = ENV['MAX_SENDER_USERS']
  TWILIO_SID = ENV['TWILIO_SID']
  TWILIO_TOKEN = ENV['TWILIO_TOKEN']
  INCOMING_SMS_URL = ENV['INCOMING_SMS_URL']

  @queue = :generate_sender
  @client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_TOKEN)

  def self.needs_new_sender(sender)
    puts "sender.users.count: #{sender.users.count}"
    puts "MAX_SENDER_USERS: #{MAX_SENDER_USERS}"
    sender.users.count >= MAX_SENDER_USERS.to_i
  end

  # returns bool if this country can have its own sender
  def self.is_sender_enabled_country_code(country_code)
    filters = {sms_enabled: true,
      exclude_local_address_required: true}
    @available_phone_numbers = get_available_phone_numbers(country_code, filters)
    return !@available_phone_numbers.nil? && @available_phone_numbers.count > 0
  end

  def self.perform(country_code)
    puts "GenerateSender: country_code: #{country_code}"

    # Find available phone numbers 
    filters = {sms_enabled: true,
      exclude_local_address_required: true}
    if country_code == 'US' || country_code == 'CA'
      country_code = 'US'
      filters.merge!(area_code: 646, region: 'NY')
    end

    @available_phone_numbers = get_available_phone_numbers(country_code, filters)

    if @available_phone_numbers.nil? || @available_phone_numbers.count == 0
      # no available numbers found for this country code (possibly not enabled on twilio yet)
      # use US instead
      country_code = 'US'
      filters.merge!(area_code: 646, region: 'NY')
      @available_phone_numbers = get_available_phone_numbers(country_code, filters)
    end
    puts "GenerateSender: found #{@available_phone_numbers.count} #{country_code} available_phone_numbers"

    # Provision a new number
    @phone_number = @available_phone_numbers.first.phone_number
    @provisioned_number = @client.incoming_phone_numbers.create(
      phone_number: @phone_number,
      sms_url: INCOMING_SMS_URL)
    
    # Persist to Sender
    sender = Sender.new(
      phone: @provisioned_number.phone_number,
      sid: @provisioned_number.sid,
      friendly_name: @provisioned_number.friendly_name,
      country_code: country_code)
    if !sender.save
      SlackSMSNotify.send_error("Could not create Sender for 
        provisioned phone number: #{@provisioned_number.phone_number}")
    end
    message = "Provisioned new Twilio number: `#{sender.phone}` (`#{country_code}`)"
    puts message
    SlackSMSNotify.send(message)
    return sender
  end

  # first try to get mobile phone numbers, then local
  def self.get_available_phone_numbers(country_code, filters)
    if country_code == 'US'
      available_phone_numbers = @client.account.available_phone_numbers.get(country_code).local.list(filters)
      return available_phone_numbers
    end
    # catch twilio exception
    begin
      available_phone_numbers = @client.account.available_phone_numbers.get(country_code).mobile.list(filters)
    rescue Twilio::REST::RequestError => e
      Raven.capture_exception(e, level: :warning)
      begin
        available_phone_numbers = @client.account.available_phone_numbers.get(country_code).local.list(filters)
      rescue Twilio::REST::RequestError => e
        Raven.capture_exception(e, level: :warning)
        return nil
      end
    end
    return available_phone_numbers
  end
end

