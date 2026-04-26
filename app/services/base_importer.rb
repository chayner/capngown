class BaseImporter
  attr_reader :file, :graduation_term, :rows, :warnings, :parser

  Result = Struct.new(:succeeded, :inserts, :updates, :skipped, :warnings, :error_message, keyword_init: true)

  def initialize(file:, graduation_term: nil)
    @file = file
    @graduation_term = graduation_term.to_s.strip.presence
    @warnings = []
    @gap_buids = []
  end

  # @return [Hash] :row_count, :inserts, :updates, :skipped, :sample_rows, :warnings, :gaps, :file_term
  def preview
    parse!
    plan = build_plan
    {
      row_count: rows.size,
      inserts: plan[:insert_count],
      updates: plan[:update_count],
      skipped: plan[:skipped_count],
      sample_rows: plan[:samples],
      warnings: warnings,
      gaps: @gap_buids.uniq,
      file_term: detect_file_term
    }
  rescue SpreadsheetParser::TooManyRowsError, SpreadsheetParser::FormatError => e
    @fatal_error = e.message
    {
      row_count: 0, inserts: 0, updates: 0, skipped: 0,
      sample_rows: [], warnings: [], gaps: [], file_term: nil,
      error: e.message
    }
  end

  # Subclasses implement #write_records!(plan) inside the transaction.
  def import!(user:)
    parse!
    plan = build_plan
    inserts = plan[:insert_count]
    updates = plan[:update_count]
    skipped = plan[:skipped_count]

    ActiveRecord::Base.transaction do
      write_records!(plan)
    end

    log_success!(user: user, inserts: inserts, updates: updates, skipped: skipped)
    Result.new(succeeded: true, inserts: inserts, updates: updates,
               skipped: skipped, warnings: warnings, error_message: nil)
  rescue StandardError => e
    log_failure!(user: user, error: e.message)
    Result.new(succeeded: false, inserts: 0, updates: 0, skipped: 0,
               warnings: warnings, error_message: e.message)
  end

  private

  def parse!
    return if @parser

    @parser = SpreadsheetParser.new(file, aliases: self.class::HEADER_ALIASES)
    @rows = @parser.rows
  end

  def import_type
    raise NotImplementedError
  end

  def build_plan
    raise NotImplementedError
  end

  def write_records!(_plan)
    raise NotImplementedError
  end

  def detect_file_term
    nil
  end

  def filename
    parser&.filename
  end

  def warn!(message)
    @warnings << message
  end

  def log_success!(user:, inserts:, updates:, skipped:)
    ImportLog.create!(
      user: user,
      import_type: import_type,
      filename: filename,
      row_count: rows.size,
      inserts: inserts,
      updates: updates,
      skipped: skipped,
      graduation_term: graduation_term,
      succeeded: true,
      warnings: warnings
    )
  end

  def log_failure!(user:, error:)
    ImportLog.create!(
      user: user,
      import_type: import_type,
      filename: filename,
      row_count: rows&.size || 0,
      graduation_term: graduation_term,
      succeeded: false,
      error_message: error,
      warnings: warnings
    )
  end
end
