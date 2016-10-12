class User < ApplicationRecord

  has_many :messages, dependent: :destroy
  belongs_to :sender
  
  before_validation :assign_phone_details, :assign_sender

  validates :phone, presence: true, uniqueness: true

  scope :subscribed, -> { where(subscribed: true) }
  scope :unsubscribed, -> { where(subscribed: false) }
  scope :needs_response, -> { where(needs_response: true) }
  scope :responded, -> { where(needs_response: false) }
  scope :patronage, -> { where('patron_product IS NOT NULL') }

  TWILIO_SID = ENV['TWILIO_SID']
  TWILIO_TOKEN = ENV['TWILIO_TOKEN']

  def initialize(attr={})
    super
    @phone ||= attr[:phone]
    self.subscribed = true
    self.needs_response = false
  end

  def label
    if self.city
      "#{self.city}, #{self.state} (##{self.id})"
    else
      "#{self.phone} (##{self.id})"
    end
  end

  def patron?
    return !self.patron_product.nil?
  end

  def send_welcome_message(send_app_link)
    Resque.enqueue(Signup, self.id, send_app_link)
  end

  def assign_phone_details
    return unless self.country_code.nil?
    return if self.phone.nil?
    @lookups_client = Twilio::REST::LookupsClient.new TWILIO_SID, TWILIO_TOKEN
    lookup_number = @lookups_client.phone_numbers.get(self.phone, type: 'carrier')
    country_code = lookup_number.country_code
    return if country_code.nil?
    self.country_code = country_code
    self.carrier_name = lookup_number.carrier['name']
  end

  def assign_sender
    return unless self.sender.nil?
    return if self.country_code.nil?
    # find sender with same country code
    country_code = self.country_code
    if GenerateSender.is_sender_enabled_country_code(country_code)
      sender_country_code = country_code
    else
      # default to US sender if this user's country code not able to to have its own sender
      # see https://support.twilio.com/hc/en-us/articles/223183068-Twilio-international-phone-number-availability-and-their-capabilities
      sender_country_code = 'US'
    end
    puts "assign_sender sender_country_code: #{sender_country_code}"
    senders = Sender.where(country_code: sender_country_code)
    if senders.count == 0
      # generate a sender with this country code + assign
      sender = GenerateSender.perform(sender_country_code)
      self.sender = sender
    else
      # assign to most recently created sender
      most_recent_sender = senders.order(created_at: :desc).first
      self.sender = most_recent_sender
      # check if sender has reached max user limit
      if GenerateSender.needs_new_sender(most_recent_sender)
        # generate new sender for this country code in bg thread
        Resque.enqueue(GenerateSender, sender_country_code)
      end
    end
  end
end
