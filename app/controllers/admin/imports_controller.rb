class Admin::ImportsController < Admin::BaseController
  IMPORTERS = {
    "graduates" => GraduateImporter,
    "brags"     => BragImporter,
    "cords"     => CordImporter
  }.freeze

  def index
    @recent_imports = ImportLog.recent
    @existing_terms = Graduate.where.not(graduation_term: nil)
                              .distinct.order(graduation_term: :desc).pluck(:graduation_term)
    @default_term = @recent_imports.find { |l| l.graduation_term.present? }&.graduation_term ||
                    @existing_terms.first
  end

  def preview
    error = validation_error
    if error
      redirect_to admin_imports_path, alert: error
      return
    end

    @import_type = params[:import_type]
    @graduation_term = resolved_graduation_term
    @cord_type = params[:cord_type].to_s.strip
    @preview = build_importer.preview
    @filename = params[:file].original_filename

    render :preview
  rescue SpreadsheetParser::FormatError, SpreadsheetParser::TooManyRowsError => e
    redirect_to admin_imports_path, alert: e.message
  end

  def create
    error = validation_error
    if error
      redirect_to admin_imports_path, alert: error
      return
    end

    result = build_importer.import!(user: current_user)
    if result.succeeded
      redirect_to admin_imports_path,
        notice: "Imported #{params[:import_type]}: #{result.inserts} new, #{result.updates} updated, #{result.skipped} skipped."
    else
      redirect_to admin_imports_path, alert: "Import failed: #{result.error_message}"
    end
  end

  private

  # Returns nil if the params are valid; otherwise a human-readable explanation.
  def validation_error
    return "Choose an import type." if params[:import_type].blank?
    return "Unknown import type: #{params[:import_type]}." unless IMPORTERS.key?(params[:import_type])
    return "Choose a file to upload." if params[:file].blank?
    if params[:import_type] != "cords" && resolved_graduation_term.blank?
      return "Choose a graduation term (or enter a new one)."
    end
    nil
  end

  # graduation_term_new (free-text) wins over the dropdown selection when both are present.
  # The "+ New term…" option uses the sentinel value "__new__" which is treated as blank.
  def resolved_graduation_term
    new_term = params[:graduation_term_new].to_s.strip
    return new_term if new_term.present?
    selected = params[:graduation_term].to_s.strip
    selected == "__new__" ? "" : selected
  end

  def build_importer
    klass = IMPORTERS[params[:import_type]]
    return nil unless klass && params[:file].present?

    if klass == CordImporter
      klass.new(file: params[:file],
                graduation_term: resolved_graduation_term,
                cord_type_override: params[:cord_type])
    else
      klass.new(file: params[:file], graduation_term: resolved_graduation_term)
    end
  end
end
