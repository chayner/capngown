class CreateCords < ActiveRecord::Migration[7.1]
  def change
    create_table :cords, id: false do |t|
      t.string :buid, null: false
      t.string :cord_type, null: false
    end
    
    # Optionally, add a composite primary key or unique index if needed
    add_index :cords, [:buid, :cord_type], unique: true
  end
end
