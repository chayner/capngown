class AddGraduationTermToGraduates < ActiveRecord::Migration[7.1]
  def change
    add_column :graduates, :graduation_term, :string
    add_index :graduates, :graduation_term
  end
end
