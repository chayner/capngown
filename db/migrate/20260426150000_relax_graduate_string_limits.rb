class RelaxGraduateStringLimits < ActiveRecord::Migration[7.1]
  COLUMNS = %i[
    lastname suffix firstname middlename
    preferredlast preferredfirst
    honors levelcode
    college1 collegedesc
    degree1 hoodcolor
    campusemail fullname
    buid2 orderid
    degstatus degstatusdesc
  ].freeze

  def up
    COLUMNS.each do |col|
      change_column :graduates, col, :string, limit: nil
    end
  end

  def down
    COLUMNS.each do |col|
      change_column :graduates, col, :string, limit: 50
    end
  end
end
