class AddNotesToGraduates < ActiveRecord::Migration[7.1]
  def change
    add_column :graduates, :notes, :text unless column_exists?(:graduates, :notes)
  end
end
