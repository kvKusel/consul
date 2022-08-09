class AddExtraFieldsToUsers < ActiveRecord::Migration[5.2]
  def change
    # add_column :users, :first_name, :string
    # add_column :users, :last_name, :string
    # add_column :users, :street_name, :string
    add_column :users, :street_number, :string
    # add_column :users, :plz, :integer
    # add_column :users, :city_name, :string
    add_column :users, :document_last_digits, :string
  end
end
