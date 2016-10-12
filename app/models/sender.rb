class Sender < ApplicationRecord
  has_many :users, dependent: :nullify

  scope :recent, -> {order(:created_at)}
end
