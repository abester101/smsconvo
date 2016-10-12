class RenameIsoCountry < ActiveRecord::Migration[5.0]
  def change
    rename_column :senders, :iso_country, :country_code
  end
end
