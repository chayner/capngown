class AddCheckedIn < ActiveRecord::Migration[7.0]
  def change
    add_column :graduates, :checked_in, :boolean
    add_column :graduates, :printed, :boolean
  end
end
