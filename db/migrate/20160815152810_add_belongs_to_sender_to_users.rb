class AddBelongsToSenderToUsers < ActiveRecord::Migration[5.0]
  def change
    add_reference :users, :sender, foreign_key: true
  end
end
