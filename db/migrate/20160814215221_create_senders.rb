class CreateSenders < ActiveRecord::Migration[5.0]
  def change
    create_table :senders do |t|
      t.string :phone
      t.string :sid
      t.string :friendly_name
      t.string :iso_country
      t.string :region

      t.timestamps
    end
  end
end
