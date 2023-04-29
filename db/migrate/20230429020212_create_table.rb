class CreateTable < ActiveRecord::Migration[7.0]
  def chgange
    create_table "graduates", primary_key: "buid", id: { type: :string, limit: 50 }, force: :cascade do |t|
      t.string "lastname", limit: 50
      t.string "suffix", limit: 50
      t.string "firstname", limit: 50
      t.string "middlename", limit: 50
      t.string "preferredlast", limit: 50
      t.string "preferredfirst", limit: 50
      t.string "honors", limit: 50
      t.string "levelcode", limit: 50
      t.string "college1", limit: 50
      t.string "collegedesc", limit: 50
      t.string "degree1", limit: 50
      t.string "hoodcolor", limit: 50
      t.string "campusemail", limit: 50
      t.string "fullname", limit: 50
      t.string "buid2", limit: 50
      t.string "orderid", limit: 50
      t.integer "height"
    end
  end
end
