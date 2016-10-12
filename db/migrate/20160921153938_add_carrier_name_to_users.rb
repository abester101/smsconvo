class AddCarrierNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :carrier_name, :string
  end
end
