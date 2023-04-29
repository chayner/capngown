class ChangePrintedToTimestamp < ActiveRecord::Migration[7.0]
  def change
    remove_column :graduates, :printed
    add_column :graduates, :printed, :timestamp
  end
end
