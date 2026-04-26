class CreateImportLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :import_logs do |t|
      t.references :user, null: true, foreign_key: true
      t.string  :import_type, null: false
      t.string  :filename
      t.integer :row_count,  default: 0, null: false
      t.integer :inserts,    default: 0, null: false
      t.integer :updates,    default: 0, null: false
      t.integer :skipped,    default: 0, null: false
      t.string  :graduation_term
      t.boolean :succeeded,  default: false, null: false
      t.text    :error_message
      t.text    :warnings

      t.timestamps
    end

    add_index :import_logs, :created_at
    add_index :import_logs, :import_type
  end
end
