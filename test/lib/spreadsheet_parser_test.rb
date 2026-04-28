require "test_helper"
require "tempfile"

class SpreadsheetParserTest < ActiveSupport::TestCase
  test "when two columns alias to the same canonical key, the higher-priority alias wins" do
    # `Degree1` and `Degree Description` both alias to canonical "degree1".
    # Regression: previously the LAST column read overwrote the first, so
    # "Legal Studies" (description) clobbered "BS" (the actual code).
    csv = Tempfile.new(["alias_priority", ".csv"])
    csv.write("BUID,Degree1,Degree Description\n")
    csv.write("B1,BS,Legal Studies\n")
    csv.flush

    parser = SpreadsheetParser.new(csv.path, aliases: {
      "buid"    => ["buid"],
      "degree1" => ["degree1", "degree", "degree description"]
    })

    row = parser.rows.first
    assert_equal "BS", row["degree1"], "the higher-priority alias 'degree1' should win"
    assert_equal "Legal Studies", row["degree description"],
                 "the demoted column keeps its normalized header so its value isn't lost"
  ensure
    csv&.close!
  end

  test "alias priority follows the order in the alias list, not the column order in the file" do
    # Header order in file is reversed; "degree1" should still win because it
    # comes first in the alias list.
    csv = Tempfile.new(["alias_order", ".csv"])
    csv.write("BUID,Degree Description,Degree1\n")
    csv.write("B1,Legal Studies,BS\n")
    csv.flush

    parser = SpreadsheetParser.new(csv.path, aliases: {
      "buid"    => ["buid"],
      "degree1" => ["degree1", "degree", "degree description"]
    })

    assert_equal "BS", parser.rows.first["degree1"]
  ensure
    csv&.close!
  end
end
