# Cord importer.
#
# The supplied cord files do NOT include BUID or cord_type. We resolve them via:
#   - cord_type: from the uploaded file's basename (e.g. "Honors Cords.xlsx" -> "Honors").
#                Admin can override via `cord_type_override` at construction.
#   - BUID:      look up via Graduate#campusemail; fall back to firstname+lastname; warn otherwise.
class CordImporter < BaseImporter
  HEADER_ALIASES = {
    "buid"      => ["buid"],
    "firstname" => ["first name", "firstname"],
    "lastname"  => ["last name", "lastname"],
    "email"     => ["email", "campus email", "camp email"]
  }.freeze

  def initialize(file:, graduation_term: nil, cord_type_override: nil)
    super(file: file, graduation_term: graduation_term)
    @cord_type_override = cord_type_override.to_s.strip.presence
  end

  def import_type
    "cords"
  end

  def cord_type
    @cord_type ||= (@cord_type_override || derive_cord_type_from_filename)
  end

  private

  def derive_cord_type_from_filename
    return nil unless file.respond_to?(:original_filename)

    base = File.basename(file.original_filename, File.extname(file.original_filename))
    # Strip "SAMPLE - " prefix and trailing "Cord(s)" word
    base.sub(/\ASAMPLE\s*-\s*/i, "")
        .sub(/\s*cords?\z/i, "")
        .strip
        .presence
  end

  def build_plan
    if cord_type.blank?
      warn!("Cord type could not be determined from filename. Provide a Cord Type override.")
      return { insert_count: 0, update_count: 0, skipped_count: rows.size, rows: [], samples: [] }
    end

    inserts = []
    updates = []
    skipped = 0
    samples = []

    existing_pairs = Cord.where(cord_type: cord_type).pluck(:buid).to_set

    rows.each_with_index do |raw, idx|
      buid = resolve_buid(raw)
      if buid.nil?
        skipped += 1
        next
      end

      attrs = { buid: buid, cord_type: cord_type }
      if existing_pairs.include?(buid)
        updates << attrs
      else
        inserts << attrs
      end
      samples << attrs.merge(name: [raw["firstname"], raw["lastname"]].compact.join(" ")) if samples.size < 5
    end

    {
      insert_count: inserts.size,
      update_count: updates.size,
      skipped_count: skipped,
      rows: (inserts + updates),
      samples: samples
    }
  end

  def resolve_buid(raw)
    buid = raw["buid"].to_s.strip
    return buid if buid.present? && Graduate.where(buid: buid).exists?

    email = raw["email"].to_s.strip.downcase
    if email.present?
      grad = Graduate.where("LOWER(campusemail) = ?", email).first
      return grad.buid if grad
    end

    first = raw["firstname"].to_s.strip
    last  = raw["lastname"].to_s.strip
    if first.present? && last.present?
      grad = Graduate.where("LOWER(firstname) = ? AND LOWER(lastname) = ?", first.downcase, last.downcase).first
      if grad
        warn!("Matched #{first} #{last} to BUID #{grad.buid} by name (email lookup missed)")
        return grad.buid
      end
    end

    @gap_buids << "#{first} #{last} <#{email}>".strip
    warn!("No matching graduate for #{first} #{last} <#{email}>; row skipped")
    nil
  end

  def write_records!(plan)
    return if plan[:rows].empty?

    Cord.upsert_all(plan[:rows], unique_by: %i[buid cord_type], record_timestamps: false)
  end
end
