class RemoveSenderIdFromUsers < ActiveRecord::Migration[5.0]
  def change
    remove_column :users, :sender_id, :string
  end
end
