class AddPatronProductToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :patron_product, :string
  end
end
