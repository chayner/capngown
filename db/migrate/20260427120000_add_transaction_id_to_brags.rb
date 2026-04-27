class AddTransactionIdToBrags < ActiveRecord::Migration[7.1]
  def change
    add_column :brags, :transaction_id, :string unless column_exists?(:brags, :transaction_id)
    add_index :brags, :transaction_id, unique: true unless index_exists?(:brags, :transaction_id)
    add_index :brags, :buid unless index_exists?(:brags, :buid)
  end
end
