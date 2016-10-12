class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :phone
      t.boolean :subscribed
      t.string :state
      t.string :country
      t.integer :zip
      t.string :city
      t.boolean :needs_response

      t.timestamps null: false
    end
  end
end
