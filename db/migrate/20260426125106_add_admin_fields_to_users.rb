class AddAdminFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :active, :boolean, default: true, null: false
    add_column :users, :must_change_password, :boolean, default: false, null: false
  end
end
