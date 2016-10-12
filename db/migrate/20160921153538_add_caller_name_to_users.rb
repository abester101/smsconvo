class AddCallerNameToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :caller_name, :string
  end
end
