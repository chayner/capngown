class RestoreDegstatusToGraduates < ActiveRecord::Migration[7.1]
  # Production has these columns (carried over from the original Belmont data
  # imports), but they were never represented in a Rails migration, so the
  # dev DB never grew them. Adding idempotently so dev/test/prod all match.
  def change
    add_column :graduates, :degstatus, :string, limit: 50 unless column_exists?(:graduates, :degstatus)
    add_column :graduates, :degstatusdesc, :string, limit: 50 unless column_exists?(:graduates, :degstatusdesc)
  end
end
