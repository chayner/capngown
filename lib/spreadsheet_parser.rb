# Wraps CSV/XLSX reading with case-insensitive, whitespace-tolerant header
# matching and known aliases.
#
# Usage:
#   parser = SpreadsheetParser.new(uploaded_file, aliases: { "buid" => %w[buid student\ buid] })
#   parser.headers          # => ["levelcode", "buid", ...] (canonical, lowercased)
#   parser.original_headers # => actual headers from file (untouched)
#   parser.each_row { |row_hash| ... }
class SpreadsheetParser
  MAX_ROWS = 2_500
  CSV_EXT = %w[.csv].freeze
  XLSX_EXT = %w[.xlsx].freeze

  class FormatError < StandardError; end
  class TooManyRowsError < StandardError; end

  attr_reader :original_headers, :rows, :filename

  # @param uploaded_file [ActionDispatch::Http::UploadedFile, String] file or path
  # @param aliases [Hash] canonical_key => [aliases...] (all lowercased, whitespace stripped)
  def initialize(uploaded_file, aliases: {})
    @aliases = aliases.transform_values { |v| Array(v).map { |a| normalize(a) } }
    @canonical_keys = @aliases.keys.map(&:to_s)
    extract_file(uploaded_file)
    parse
  end

  def each_row(&block)
    rows.each(&block)
  end

  def row_count
    rows.size
  end

  private

  def normalize(str)
    str.to_s.downcase.strip.gsub(/[\s_]+/, " ")
  end

  def extract_file(file)
    if file.respond_to?(:original_filename)
      @filename = file.original_filename
      @path = file.tempfile.path
      @ext = File.extname(@filename).downcase
    else
      @filename = File.basename(file)
      @path = file
      @ext = File.extname(@path).downcase
    end
  end

  def parse
    if CSV_EXT.include?(@ext)
      parse_csv
    elsif XLSX_EXT.include?(@ext)
      parse_xlsx
    else
      raise FormatError, "Unsupported file format: #{@ext}. Use CSV or XLSX."
    end
  end

  def parse_csv
    require "csv"
    @original_headers = nil
    @rows = []
    CSV.foreach(@path, headers: true, encoding: "bom|utf-8") do |csv_row|
      if @original_headers.nil?
        @original_headers = csv_row.headers.map { |h| h.to_s }
        @canonical_lookup = build_canonical_lookup(@original_headers)
      end
      add_row(csv_row.to_h)
    end
    @original_headers ||= []
  end

  def parse_xlsx
    require "roo"
    sheet = Roo::Spreadsheet.open(@path)
    rows_iter = sheet.parse(headers: true, clean: true)
    # Roo's first parsed row is the header row itself when using headers: true (kept for reference).
    if rows_iter.any?
      @original_headers = rows_iter.first.keys.map(&:to_s)
      @canonical_lookup = build_canonical_lookup(@original_headers)
      data_rows = rows_iter.drop(1)
      data_rows.each { |h| add_row(h) }
    else
      @original_headers = []
      @rows = []
    end
  end

  # Builds a hash: original_header_string => canonical_key (or original normalized if no canonical match)
  def build_canonical_lookup(headers)
    lookup = {}
    headers.each do |raw|
      norm = normalize(raw)
      canonical = @aliases.find { |_k, vs| vs.include?(norm) }&.first
      lookup[raw] = (canonical || norm).to_s
    end
    lookup
  end

  def add_row(hash)
    raise TooManyRowsError, "File exceeds the #{MAX_ROWS}-row maximum." if @rows && @rows.size >= MAX_ROWS

    canonical = {}
    hash.each do |k, v|
      key = @canonical_lookup[k.to_s] || normalize(k)
      canonical[key] = v
    end
    @rows ||= []
    @rows << canonical
  end
end
