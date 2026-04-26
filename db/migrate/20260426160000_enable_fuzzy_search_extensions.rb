class EnableFuzzySearchExtensions < ActiveRecord::Migration[7.1]
  def up
    enable_extension "unaccent"      unless extension_enabled?("unaccent")
    enable_extension "pg_trgm"       unless extension_enabled?("pg_trgm")
    enable_extension "fuzzystrmatch" unless extension_enabled?("fuzzystrmatch")
  end

  def down
    # Leave extensions in place; harmless and may be used elsewhere.
  end
end
