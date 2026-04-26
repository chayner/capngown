# Brag importer.
#
# Strategy: delete-all-by-buid then insert. The brags table currently has no
# differentiator column to support per-row upsert; until that lands (see
# docs/BACKLOG.md "Brag differentiator column"), each upload replaces every
# brag row whose buid appears in the file with the rows from the file.
class BragImporter < BaseImporter
  HEADER_ALIASES = {
    "buid"      => ["buid", "student buid"],
    "firstname" => ["student first", "first name", "firstname"],
    "lastname"  => ["student last", "last name", "lastname"],
    "message"   => ["message", "brag", "brag message", "notes"]
  }.freeze

  def import_type
    "brags"
  end

  private

  def build_plan
    valid_rows = []
    skipped = 0
    samples = []

    valid_grad_buids = Graduate.where(buid: rows.map { |r| r["buid"].to_s.strip }.reject(&:blank?))
                               .pluck(:buid).to_set

    rows.each_with_index do |raw, idx|
      buid = raw["buid"].to_s.strip
      first = raw["firstname"].to_s.strip
      last  = raw["lastname"].to_s.strip
      name = [first, last].reject(&:empty?).join(" ").presence

      if buid.blank?
        skipped += 1
        warn!("Row #{idx + 2}: skipped (missing BUID)")
        next
      end

      unless valid_grad_buids.include?(buid)
        @gap_buids << buid
        skipped += 1
        warn!("Row #{idx + 2} (BUID #{buid}): no matching graduate; row skipped")
        next
      end

      attrs = { buid: buid, name: name, message: presence(raw["message"]) }
      valid_rows << attrs
      samples << attrs if samples.size < 5
    end

    # All "valid_rows" are inserts (we delete by buid first), but for the UI
    # we report which buids already had brags as "updates" and the rest as
    # "inserts".
    pre_existing = Brag.where(buid: valid_rows.map { |r| r[:buid] }).distinct.pluck(:buid).to_set
    insert_count = valid_rows.count { |r| !pre_existing.include?(r[:buid]) }
    update_count = valid_rows.count { |r| pre_existing.include?(r[:buid]) }

    {
      insert_count: insert_count,
      update_count: update_count,
      skipped_count: skipped,
      rows: valid_rows,
      samples: samples
    }
  end

  def presence(v)
    s = v.to_s.strip
    s.empty? ? nil : s
  end

  def write_records!(plan)
    return if plan[:rows].empty?

    buids = plan[:rows].map { |r| r[:buid] }.uniq
    Brag.where(buid: buids).delete_all
    Brag.insert_all(plan[:rows], record_timestamps: false)
  end
end
