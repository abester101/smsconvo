class CreateMessages < ActiveRecord::Migration[5.0]
  def change
    create_table :messages do |t|
      t.text     "body"
      t.boolean  "from_us"
      t.integer  "user_id"
      t.boolean  "delivered"
      t.text     "media_url"
      t.string   "media_type"

      t.timestamps null: false
    end
  end
end
