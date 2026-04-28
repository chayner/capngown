namespace :graduates do
  desc "Backfill missing preferredfirst from campus email (pref_first.last@bruins.belmont.edu). " \
       "Usage: bin/rails graduates:backfill_nicknames [DRY_RUN=true]"
  task backfill_nicknames: :environment do
    dry_run = ENV["DRY_RUN"].to_s.downcase == "true"

    scope = Graduate.where("preferredfirst IS NULL OR preferredfirst = ''")
                    .where.not(campusemail: [nil, ""])

    total = scope.count
    updated = 0
    skipped = 0
    examples = []

    scope.find_each(batch_size: 500) do |grad|
      candidate = Graduate.preferred_first_from_email(grad.campusemail, grad.firstname)
      if candidate.blank?
        skipped += 1
        next
      end

      examples << "#{grad.buid}: #{grad.firstname.inspect} -> #{candidate.inspect} (email: #{grad.campusemail})" if examples.size < 10

      unless dry_run
        grad.update_column(:preferredfirst, candidate)
      end
      updated += 1
    end

    puts "Examined #{total} graduates with blank preferredfirst and a campus email."
    puts "Would update #{updated} (#{skipped} skipped)." if dry_run
    puts "Updated #{updated} (#{skipped} skipped)." unless dry_run
    puts "Examples:" if examples.any?
    examples.each { |line| puts "  #{line}" }
  end

  desc "Strip duplicated surname from preferredfirst (e.g. 'Cameron Bateman' when lastname is 'Bateman'). " \
       "Usage: bin/rails graduates:sanitize_preferred_names [DRY_RUN=true]"
  task sanitize_preferred_names: :environment do
    dry_run = ENV["DRY_RUN"].to_s.downcase == "true"

    updated = 0
    examples = []

    Graduate.where.not(preferredfirst: [nil, ""])
            .or(Graduate.where.not(preferredlast: [nil, ""]))
            .find_each(batch_size: 500) do |grad|
      new_first = Graduate.sanitize_preferred_first(grad.preferredfirst, grad.lastname, grad.preferredlast)
      new_last  = Graduate.sanitize_preferred_last(grad.preferredlast,  grad.firstname, grad.preferredfirst)

      changes = {}
      changes[:preferredfirst] = new_first if grad.preferredfirst.present? && new_first != grad.preferredfirst
      changes[:preferredlast]  = new_last  if grad.preferredlast.present?  && new_last  != grad.preferredlast
      next if changes.empty?

      examples << "#{grad.buid}: #{grad.preferredfirst.inspect}/#{grad.preferredlast.inspect} -> #{(changes[:preferredfirst] || grad.preferredfirst).inspect}/#{(changes[:preferredlast] || grad.preferredlast).inspect}" if examples.size < 10
      grad.update_columns(changes) unless dry_run
      updated += 1
    end

    puts(dry_run ? "Would clean #{updated} graduates." : "Cleaned #{updated} graduates.")
    puts "Examples:" if examples.any?
    examples.each { |line| puts "  #{line}" }
  end

  desc "Backfill degree1 codes (e.g. 'Master of Sport Administration' -> 'MSA') and hoodcolor. " \
       "Usage: bin/rails graduates:backfill_degree_codes [DRY_RUN=true]"
  task backfill_degree_codes: :environment do
    dry_run = ENV["DRY_RUN"].to_s.downcase == "true"

    updated = 0
    examples = []

    Graduate.where.not(degree1: [nil, ""]).find_each(batch_size: 500) do |grad|
      raw = grad.degree1.to_s.strip
      upper = raw.upcase
      changes = {}

      code = if DegreeHoodTranslator::DEGREE_HOOD_MAP.key?(upper)
               upper
             else
               DegreeHoodTranslator.code_from_name(raw)
             end

      next unless code

      changes[:degree1] = code if grad.degree1 != code

      mapped = DegreeHoodTranslator.translate(code)
      hood = mapped[:hood_color]
      hood = nil if hood == "Unknown"
      changes[:hoodcolor] = hood if hood.present? && grad.hoodcolor != hood

      next if changes.empty?

      examples << "#{grad.buid}: degree1 #{grad.degree1.inspect} -> #{(changes[:degree1] || grad.degree1).inspect}, hood #{grad.hoodcolor.inspect} -> #{(changes[:hoodcolor] || grad.hoodcolor).inspect}" if examples.size < 10
      grad.update_columns(changes) unless dry_run
      updated += 1
    end

    puts(dry_run ? "Would update #{updated} graduates." : "Updated #{updated} graduates.")
    puts "Examples:" if examples.any?
    examples.each { |line| puts "  #{line}" }
  end
end
