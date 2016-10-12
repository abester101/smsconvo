class AddCreatedFromToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :created_from, :string
  end
end
