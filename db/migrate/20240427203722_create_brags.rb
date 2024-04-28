class CreateBrags < ActiveRecord::Migration[7.0]
  def change
    create_table :brags do |t|
      t.string :name
      t.string :buid
      t.text :message
    end
  end
end
