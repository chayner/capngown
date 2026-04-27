# Brag importer.
#
# Strategy: upsert by `transaction_id`. Each row in the Bruin Brag export has
# a unique Transaction ID, so the same row uploaded twice updates in place
# instead of duplicating, and a row removed from the latest export does NOT
# get nuked (we never delete on import).
#
# Rows missing a Transaction ID are skipped with a warning. Rows whose BUID
# is not in the graduates table are skipped and reported as gaps so the user
# can re-upload after loading the missing graduate.
class BragImporter < BaseImporter
  HEADER_ALIASES = {
    "buid"           => ["buid", "student buid"],
    "firstname"      => ["student first", "first name", "firstname"],
    "lastname"       => ["student last", "last name", "lastname"],
    "message"        => ["note", "message", "brag", "brag message", "notes"],
    "transaction_id" => ["transaction id", "transactionid", "txn id", "txnid"]
  }.freeze

  def import_type
    "brags"
  end

  private

  def build_plan
    valid_rows = []
    skipped = 0
    samples = []
    seen_txn_ids = {}

    valid_grad_buids = Graduate.where(buid: rows.map { |r| r["buid"].to_s.strip }.reject(&:blank?))
                               .pluck(:buid).to_set

    rows.each_with_index do |raw, idx|
      buid  = raw["buid"].to_s.strip
      first = raw["firstname"].to_s.strip
      last  = raw["lastname"].to_s.strip
      name  = [first, last].reject(&:empty?).join(" ").presence
      txn   = presence(raw["transaction_id"])

      if buid.blank?
        skipped += 1
        warn!("Row #{idx + 2}: skipped (missing BUID)")
        next
      end

      if txn.blank?
        skipped += 1
        warn!("Row #{idx + 2} (BUID #{buid}): skipped (missing Transaction ID)")
        next
      end

      if seen_txn_ids.key?(txn)
        skipped += 1
        warn!("Row #{idx + 2} (BUID #{buid}): skipped (duplicate Transaction ID #{txn} also on row #{seen_txn_ids[txn] + 2})")
        next
      end
      seen_txn_ids[txn] = idx

      unless valid_grad_buids.include?(buid)
        @gap_buids << buid
        skipped += 1
        warn!("Row #{idx + 2} (BUID #{buid}): no matching graduate; row skipped")
        next
      end

      attrs = { buid: buid, name: name, message: presence(raw["message"]), transaction_id: txn }
      valid_rows << attrs
      samples << attrs if samples.size < 5
    end

    pre_existing = Brag.where(transaction_id: valid_rows.map { |r| r[:transaction_id] })
                       .pluck(:transaction_id).to_set
    insert_count = valid_rows.count { |r| !pre_existing.include?(r[:transaction_id]) }
    update_count = valid_rows.count { |r|  pre_existing.include?(r[:transaction_id]) }

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

    Brag.upsert_all(plan[:rows], unique_by: :index_brags_on_transaction_id, record_timestamps: false)
  end
end
