class ChangeCheckedinToTimestamp < ActiveRecord::Migration[7.0]
  def change
    remove_column :graduates, :checked_in
    add_column :graduates, :checked_in, :timestamp
  end
end
