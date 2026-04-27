# Imports the main term roster, 3+3 UG list, and late-add list.
# All variants converge on the same columns via header aliases.
class GraduateImporter < BaseImporter
  HEADER_ALIASES = {
    "buid"              => ["buid"],
    "lastname"          => ["shbgapp lastname", "lastname", "last name"],
    "firstname"         => ["shbgapp firstname", "firstname", "first name"],
    "middlename"        => ["shbgapp middle", "middlename", "middle name", "middle"],
    "suffix"            => ["shbgapp suffix", "suffix", "namesuffix", "name suffix"],
    "preferredfirst"    => ["preferred name"],
    "preferredlast"     => ["preferred last"],
    "honors"            => ["honors"],
    "levelcode"         => ["levelcode", "effectlevel", "effect level"],
    "college1"          => ["college1", "degreecollege1", "degree college1", "degree college 1"],
    "collegedesc"       => ["collegedesc", "college desc", "collegename", "college name"],
    "degree1"           => ["degree1", "degree", "degree description"],
    "degree_for_hood"   => ["degree for hood", "degree for hood (if graduate)"],
    "campusemail"       => ["camp email", "campusemail", "emailcampus", "email campus"],
    "fullname"          => ["diploma name", "fullname", "full name"],
    "major"             => ["major1deg1desc", "major1deg1 desc", "major", "major1deg1"],
    "height"            => ["totalheight", "total height"],
    "jostens_height"    => ["jostens height"],
    "height_ft"         => ["height ft"],
    "height_in"         => ["height in"],
    "graduation_term"   => ["graduationterm", "graduation term", "yeargraduating", "year graduating"]
  }.freeze

  REQUIRED_COLUMNS = %w[buid].freeze

  def import_type
    "graduates"
  end

  def detect_file_term
    rows.each do |r|
      term = r["graduation_term"].to_s.strip
      return term if term.match?(/\A\d{6}\z/)
    end
    nil
  end

  private

  def build_plan
    inserts = []
    updates = []
    skipped = 0
    samples = []

    existing = Graduate.where(buid: rows.map { |r| r["buid"].to_s.strip }.reject(&:blank?))
                       .pluck(:buid).to_set

    rows.each_with_index do |raw, idx|
      # Silently skip wholly-empty rows (Excel often pads files with thousands of blank rows).
      if raw.values.all? { |v| v.to_s.strip.empty? }
        skipped += 1
        next
      end

      attrs = normalize_row(raw)
      buid = attrs[:buid]

      if buid.blank?
        skipped += 1
        warn!("Row #{idx + 2}: skipped (missing BUID)")
        next
      end

      college = attrs[:college1]
      if college.present? && CollegeCodeTranslator::COLLEGE_CODE_MAP[college].nil?
        skipped += 1
        warn!("Row #{idx + 2} (BUID #{buid}): skipped (unknown college code: #{college.inspect})")
        next
      end

      attrs[:graduation_term] = graduation_term if graduation_term.present?

      record = { buid: buid, attrs: attrs }
      if existing.include?(buid)
        updates << record
      else
        inserts << record
      end

      samples << attrs.slice(:buid, :firstname, :lastname, :levelcode, :college1, :graduation_term) if samples.size < 5
    end

    {
      insert_count: inserts.size,
      update_count: updates.size,
      skipped_count: skipped,
      inserts: inserts,
      updates: updates,
      samples: samples
    }
  end

  def normalize_row(raw)
    suffix = raw["suffix"].to_s.strip
    suffix = nil if suffix.blank?

    jostens_height = presence(raw["jostens_height"])
    height = parse_height(raw["height"]) ||
             parse_height(jostens_height) ||
             parse_feet_inches(raw["height_ft"], raw["height_in"])
    orderid = build_order_id(raw["buid"], jostens_height)

    college_code = resolve_college_code(raw["college1"])
    college_desc = raw["collegedesc"].to_s.strip.presence ||
                   (college_code ? CollegeCodeTranslator.translate_full(college_code) : nil)

    degree_code = raw["degree1"].to_s.strip.presence
    degree_code ||= reverse_degree_code(raw["degree_for_hood"])
    hood_color = nil
    if degree_code.present?
      mapped = DegreeHoodTranslator.translate(degree_code.upcase)
      hood_color = mapped[:hood_color] unless mapped[:hood_color] == "Unknown"
    end

    firstname      = presence(raw["firstname"])
    lastname       = presence(raw["lastname"])
    campusemail    = presence(raw["campusemail"])
    preferredlast  = Graduate.sanitize_preferred_last(presence(raw["preferredlast"]), firstname)
    preferredfirst = presence(raw["preferredfirst"]) ||
                     Graduate.preferred_first_from_email(campusemail, firstname)
    preferredfirst = Graduate.sanitize_preferred_first(preferredfirst, lastname, preferredlast)

    {
      buid: raw["buid"].to_s.strip,
      firstname: firstname,
      lastname:  lastname,
      middlename: presence(raw["middlename"]),
      suffix: suffix,
      preferredfirst: preferredfirst,
      preferredlast: preferredlast,
      fullname: presence(raw["fullname"]),
      honors: presence(raw["honors"]),
      levelcode: presence(raw["levelcode"]),
      college1: college_code,
      collegedesc: college_desc,
      degree1: degree_code,
      hoodcolor: hood_color,
      campusemail: campusemail,
      major: presence(raw["major"]),
      height: height,
      orderid: orderid,
      graduation_term: presence(raw["graduation_term"])
    }
  end

  # Jostens orderid = last 6 digits of BUID + "-" + jostens_height value.
  # Returns nil if either piece is missing.
  def build_order_id(buid, jostens_height)
    jh = jostens_height.to_s.strip
    return nil if jh.blank?

    digits = buid.to_s.gsub(/\D/, "")
    return nil if digits.empty?

    "#{digits.last(6)}-#{jh}"
  end

  def parse_feet_inches(ft, inches)
    f = ft.to_s.strip
    i = inches.to_s.strip
    return nil if f.empty? && i.empty?
    return nil unless f.match?(/\A\d+\z/) || i.match?(/\A\d+\z/)

    (f.to_i * 12) + i.to_i
  end

  COLLEGE_NAME_ALIASES = {
    "CB" => ["college of business", "massey college of business",
             "business", "businesss", "massey"],
    "CE" => ["college of entertainment", "college of entertainment & music business",
             "college of entrmnt/musc busnes", "curb college", "curb",
             "curb college of entertainment & music business",
             "mike curb college of entertainment and music business",
             "entertainment", "entertainment & music business"],
    "CI" => ["interdisciplinary studies", "interdisciplinary"],
    "CL" => ["college of law", "law"],
    "CM" => ["college of sciences & math", "college of sciences and math",
             "college of science and mathematics", "sciences & math",
             "sci & math", "sciences and math"],
    "CN" => ["college of nursing", "inman college of nursing",
             "gordon e. inman college of nursing", "nursing"],
    "CS" => ["college of liberal arts and social sciences",
             "college of lib. arts & soc sci",
             "college of liberal arts & social sciences",
             "liberal arts & social sciences",
             "liberal arts and social sciences", "class"],
    "ED" => ["college of education", "education"],
    "MP" => ["college of music & performing arts", "college of music and performing arts",
             "music & performing arts", "music and performing arts"],
    "OM" => ["o'more college architecture & design",
             "o'more college of architecture & design",
             "o'more"],
    "PH" => ["college of pharmacy & health sciences",
             "college of pharmacy and health sciences",
             "pharmacy & health sciences", "pharmacy", "pharm & health sci"],
    "UC" => ["university college"],
    "WC" => ["college of art", "watkins college of art", "art", "watkins"]
  }.freeze

  # College1 may already be a code (e.g. "MB"), or in late-add files it may be
  # the full or short college name. Try direct match first, then reverse-lookup.
  def resolve_college_code(value)
    s = value.to_s.strip
    return nil if s.blank?
    return s if CollegeCodeTranslator::COLLEGE_CODE_MAP.key?(s)

    normalized = s.downcase
    CollegeCodeTranslator::COLLEGE_CODE_MAP.each do |code, info|
      return code if info[:full_name].downcase == normalized
      return code if info[:short_name].downcase == normalized
    end
    COLLEGE_NAME_ALIASES.each do |code, names|
      return code if names.include?(normalized)
    end
    s
  end

  def reverse_degree_code(value)
    s = value.to_s.strip
    return nil if s.blank?
    DegreeHoodTranslator::DEGREE_HOOD_MAP.each do |code, info|
      return code if info[:degree].downcase == s.downcase
    end
    nil
  end

  def presence(value)
    s = value.to_s.strip
    s.empty? ? nil : s
  end

  def parse_height(value)
    return nil if value.blank?

    s = value.to_s.strip
    return s.to_i if s.match?(/\A\d+\z/)

    if (m = s.match(/(\d+)\D+(\d+)/))
      return (m[1].to_i * 12) + m[2].to_i
    end
    nil
  end

  def write_records!(plan)
    rows_to_write = (plan[:inserts] + plan[:updates]).map do |entry|
      entry[:attrs].merge(buid: entry[:buid])
    end

    return if rows_to_write.empty?

    # upsert_all requires every row to share the same keys, so do not .compact;
    # let nils carry through to nullable columns.
    Graduate.upsert_all(rows_to_write, unique_by: :buid, record_timestamps: false)
  end
end
