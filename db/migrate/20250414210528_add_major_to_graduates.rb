class AddMajorToGraduates < ActiveRecord::Migration[7.1]
  def change
    add_column :graduates, :major, :string
  end
end
