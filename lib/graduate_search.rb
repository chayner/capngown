# Friendly fuzzy search for graduates.
#
# Routes a single query string to the right strategy:
#   - Looks like a BUID (e.g. "B00610448" or 9-digit number)  → exact match
#   - Looks like an email (contains "@")                      → ILIKE on campusemail
#   - Otherwise treated as a name                             → ranked name search
#
# Name search:
#   1. Exact (accent-insensitive) match on first+last
#   2. Prefix match on first/last
#   3. Contains match on first/last/preferred/full
#   4. Soundex match (sounds-like)
#   5. Trigram similarity (typo tolerance)
#
# Nickname expansion (Bob ↔ Robert) happens transparently inside the name path.
module GraduateSearch
  TRIGRAM_THRESHOLD = 0.3

  # Common Bob/Robert-style nickname pairs. Bidirectional at lookup time.
  NICKNAMES = {
    "alex"     => %w[alexander alexandra alexa alejandro],
    "andy"     => %w[andrew andrea],
    "ben"      => %w[benjamin],
    "beth"     => %w[elizabeth],
    "betty"    => %w[elizabeth],
    "bill"     => %w[william],
    "billy"    => %w[william],
    "bob"      => %w[robert],
    "bobby"    => %w[robert],
    "brad"     => %w[bradley bradford],
    "cathy"    => %w[catherine katherine],
    "chris"    => %w[christopher christine christina christian],
    "dan"      => %w[daniel],
    "danny"    => %w[daniel],
    "dave"     => %w[david],
    "deb"      => %w[deborah debra],
    "dick"     => %w[richard],
    "don"      => %w[donald],
    "ed"       => %w[edward edwin edmund],
    "eddie"    => %w[edward],
    "frank"    => %w[franklin francis],
    "fred"     => %w[frederick alfred],
    "greg"     => %w[gregory],
    "hank"     => %w[henry],
    "jack"     => %w[john jackson],
    "jake"     => %w[jacob],
    "jen"      => %w[jennifer],
    "jenny"    => %w[jennifer],
    "jerry"    => %w[gerald jerome],
    "jim"      => %w[james],
    "jimmy"    => %w[james],
    "joe"      => %w[joseph],
    "joey"     => %w[joseph],
    "jon"      => %w[jonathan],
    "katie"    => %w[katherine kathleen],
    "kate"     => %w[katherine kathleen],
    "kathy"    => %w[katherine kathleen],
    "ken"      => %w[kenneth],
    "kim"      => %w[kimberly],
    "larry"    => %w[lawrence],
    "liz"      => %w[elizabeth],
    "lizzie"   => %w[elizabeth],
    "maggie"   => %w[margaret],
    "matt"     => %w[matthew],
    "meg"      => %w[megan margaret],
    "mike"     => %w[michael],
    "molly"    => %w[mary margaret],
    "nate"     => %w[nathan nathaniel],
    "nick"     => %w[nicholas nicolas],
    "pat"      => %w[patrick patricia],
    "patty"    => %w[patricia],
    "peggy"    => %w[margaret],
    "pete"     => %w[peter],
    "rick"     => %w[richard],
    "rob"      => %w[robert],
    "ron"      => %w[ronald],
    "sam"      => %w[samuel samantha],
    "steve"    => %w[steven stephen],
    "sue"      => %w[susan suzanne],
    "ted"      => %w[theodore edward],
    "terry"    => %w[terrence theresa],
    "tim"      => %w[timothy],
    "tom"      => %w[thomas],
    "tony"     => %w[anthony],
    "trish"    => %w[patricia],
    "vicky"    => %w[victoria],
    "will"     => %w[william],
    "zach"     => %w[zachary]
  }.freeze

  # Reverse map: formal → all known nicknames (built once).
  REVERSE_NICKNAMES = NICKNAMES.each_with_object({}) do |(nick, formals), acc|
    formals.each do |formal|
      (acc[formal] ||= []) << nick
    end
  end.freeze

  # Spelling substitutions applied to the *start* of a name.
  # Catches Kris↔Chris↔Cris, Cathy↔Kathy, Phil↔Fil, Stephen↔Steven, etc.
  # Each entry = list of interchangeable prefixes.
  PREFIX_SUBSTITUTIONS = [
    %w[k kr c ch cr],   # Kris↔Chris↔Cris, Karen↔Caren, Kathy↔Cathy
    %w[k c],            # Kayla↔Cayla, Kim↔Cim
    %w[ph f],           # Phil↔Fil, Phyllis↔Fillis
    %w[st sth],         # Stephen↔Sthephen (rare but harmless)
    %w[s sh],           # Sean↔Shaun (partial)
    %w[j g],            # Jiana↔Giana, Jorge↔Giorge
    %w[x ks],           # Xander↔Ksander
  ].freeze

  # Phonetic substitutions applied *anywhere* in the name (one swap per variant).
  # Curated for first-name spelling drift; kept short to avoid noise.
  # Source: FamilySearch Phonetic Substitutes Table (curated subset).
  INFIX_SUBSTITUTIONS = [
    %w[ay ae ai ei],    # Kayla↔Kaela, Caitlin↔Kaitlyn↔Keitlin, Aydan↔Aidan
    %w[ie y],           # Kiera↔Kyra, Sophie↔Sophy
    %w[ph f],           # Stephanie↔Stefanie (also covered as prefix)
    %w[ks x],           # Alexander↔Aleksander
  ].freeze

  # Public entry point. Returns an ActiveRecord::Relation.
  def self.search(scope, query)
    q = query.to_s.strip
    return scope if q.empty?

    case query_type(q)
    when :buid  then scope.where("UPPER(buid) = UPPER(:q)", q: q)
    when :email then scope.where("LOWER(campusemail) LIKE :q", q: "%#{q.downcase}%")
    else             ranked_name_search(scope, q)
    end
  end

  def self.query_type(q)
    return :email if q.include?("@")
    return :buid  if q.match?(/\AB?\d{6,}\z/i)
    :name
  end

  # Build a ranked relation for a name query.
  #
  # Strategy: try the precise pass first (accent-insensitive ILIKE with
  # nickname expansion). If that returns ANY rows, return only those —
  # we never want to dilute clean matches with sounds-like noise. Only
  # fall back to Soundex + trigram fuzzy matching when the precise pass
  # is empty (likely a typo or mis-spelling).
  def self.ranked_name_search(scope, query)
    parts  = query.downcase.split(/\s+/)
    first  = parts[0]
    last   = parts[1..]&.join(" ")&.presence

    first_variants = expand_nicknames(first)
    last_variants  = last ? [last] : []

    ilike_sql, ilike_binds = build_ilike_condition(first_variants, last_variants, has_last: !last.nil?)
    rank_sql               = build_rank_expression(first, last)

    precise = scope.where(ilike_sql, ilike_binds).order(Arel.sql(rank_sql), :lastname, :firstname)
    return precise if precise.exists?

    fuzzy_search(scope, first, last, rank_sql)
  end

  # Fallback: only invoked when the precise pass found nothing.
  # Skips Soundex/trigram entirely for very short queries (< 4 chars),
  # where both produce too many false positives to be useful.
  def self.fuzzy_search(scope, first, last, rank_sql)
    return scope.none if first.to_s.length < 4 && last.nil?

    fallback_conds = []
    fallback_binds = {}
    if last
      fallback_conds << "(SOUNDEX(graduates.firstname) = SOUNDEX(:sx_first) AND SOUNDEX(graduates.lastname) = SOUNDEX(:sx_last))"
      fallback_binds[:sx_first] = first
      fallback_binds[:sx_last]  = last
      fallback_conds << "(similarity(unaccent(graduates.firstname), unaccent(:tg_first)) > #{TRIGRAM_THRESHOLD} AND similarity(unaccent(graduates.lastname), unaccent(:tg_last)) > #{TRIGRAM_THRESHOLD})"
      fallback_binds[:tg_first] = first
      fallback_binds[:tg_last]  = last
    else
      fallback_conds << "(SOUNDEX(graduates.firstname) = SOUNDEX(:sx_term) OR SOUNDEX(graduates.lastname) = SOUNDEX(:sx_term))"
      fallback_binds[:sx_term] = first
      fallback_conds << "(similarity(unaccent(graduates.firstname), unaccent(:tg_term)) > #{TRIGRAM_THRESHOLD} OR similarity(unaccent(graduates.lastname), unaccent(:tg_term)) > #{TRIGRAM_THRESHOLD})"
      fallback_binds[:tg_term] = first
    end

    sql = fallback_conds.map { |c| "(#{c})" }.join(" OR ")
    scope.where(sql, fallback_binds).order(Arel.sql(rank_sql), :lastname, :firstname)
  end

  # Expand a name into its known variants:
  #   1. The name itself
  #   2. Direct nickname lookups (Bob → Robert, Robert → Bob)
  #   3. Prefix-substitution variants (Kris → Chris/Cris, Cathy → Kathy)
  # Then re-runs nickname lookup on each substitution variant so
  # "Kris" → "Chris" → "Christopher/Christina/Christian".
  def self.expand_nicknames(name)
    return [] if name.blank?
    n = name.downcase
    out = [n]
    out.concat(NICKNAMES[n])         if NICKNAMES[n]
    out.concat(REVERSE_NICKNAMES[n]) if REVERSE_NICKNAMES[n]

    # Apply prefix substitutions, then expand nicknames on each result.
    apply_prefix_substitutions(n).each do |variant|
      out << variant
      out.concat(NICKNAMES[variant])         if NICKNAMES[variant]
      out.concat(REVERSE_NICKNAMES[variant]) if REVERSE_NICKNAMES[variant]
    end

    # Apply infix substitutions (in-word phonetic swaps) on the original name
    # and on each prefix variant. Single-swap only — keeps variant count small.
    seeds = out.dup
    seeds.each do |seed|
      apply_infix_substitutions(seed).each do |variant|
        out << variant
        out.concat(NICKNAMES[variant])         if NICKNAMES[variant]
        out.concat(REVERSE_NICKNAMES[variant]) if REVERSE_NICKNAMES[variant]
      end
    end

    out.uniq
  end

  # For each prefix group, if `name` starts with one prefix, generate
  # versions with each of the other prefixes substituted in.
  def self.apply_prefix_substitutions(name)
    variants = []
    PREFIX_SUBSTITUTIONS.each do |group|
      group.each do |prefix|
        next unless name.start_with?(prefix)
        rest = name[prefix.length..]
        group.each do |sub|
          next if sub == prefix
          variants << "#{sub}#{rest}"
        end
      end
    end
    variants.uniq
  end

  # For each infix group, swap a single occurrence of any group member with
  # each of its alternates (one swap per variant). Skips the leading character
  # so we don't double-cover prefix substitutions.
  def self.apply_infix_substitutions(name)
    variants = []
    INFIX_SUBSTITUTIONS.each do |group|
      group.each do |token|
        # Search starting at index 1 to avoid duplicating prefix work.
        idx = name.index(token, 1)
        next unless idx
        before = name[0...idx]
        after  = name[(idx + token.length)..]
        group.each do |sub|
          next if sub == token
          variants << "#{before}#{sub}#{after}"
        end
      end
    end
    variants.uniq
  end

  # ILIKE pass against firstname/lastname/preferred*/fullname, accent-stripped.
  def self.build_ilike_condition(first_variants, last_variants, has_last:)
    conds = []
    binds = {}

    if has_last
      first_variants.each_with_index do |fv, fi|
        last_variants.each_with_index do |lv, li|
          fkey = "f_#{fi}".to_sym
          lkey = "l_#{li}".to_sym
          binds[fkey] = "%#{fv}%"
          binds[lkey] = "%#{lv}%"
          conds << "(unaccent(graduates.firstname)      ILIKE unaccent(:#{fkey}) AND unaccent(graduates.lastname)     ILIKE unaccent(:#{lkey}))"
          conds << "(unaccent(graduates.preferredfirst) ILIKE unaccent(:#{fkey}) AND unaccent(graduates.preferredlast) ILIKE unaccent(:#{lkey}))"
          conds << "(unaccent(graduates.preferredfirst) ILIKE unaccent(:#{fkey}) AND unaccent(graduates.lastname)     ILIKE unaccent(:#{lkey}))"
          conds << "(unaccent(graduates.firstname)      ILIKE unaccent(:#{fkey}) AND unaccent(graduates.preferredlast) ILIKE unaccent(:#{lkey}))"
        end
      end
      first_variants.each_with_index do |fv, fi|
        last_variants.each_with_index do |lv, li|
          fkey = "ff_#{fi}_#{li}".to_sym
          binds[fkey] = "%#{fv} %#{lv}%"
          conds << "(unaccent(graduates.fullname) ILIKE unaccent(:#{fkey}))"
        end
      end
    else
      # Single-term search: match against given/preferred first/last only.
      # Deliberately skip `fullname` (the diploma name with middle names) so
      # querying "bob" doesn't match anyone whose middle name is Robert.
      first_variants.each_with_index do |fv, idx|
        key = "n_#{idx}".to_sym
        binds[key] = "%#{fv}%"
        conds << "unaccent(graduates.firstname)      ILIKE unaccent(:#{key})"
        conds << "unaccent(graduates.lastname)       ILIKE unaccent(:#{key})"
        conds << "unaccent(graduates.preferredfirst) ILIKE unaccent(:#{key})"
        conds << "unaccent(graduates.preferredlast)  ILIKE unaccent(:#{key})"
      end
    end

    [conds.join(" OR "), binds]
  end

  # Tier-based ORDER BY expression. Lower tier = better match.
  # Quoted literals are pre-escaped — these cannot be bind params in ORDER BY.
  def self.build_rank_expression(first, last)
    fe = escape(first)
    fs = sanitize_like(first)
    if last
      le = escape(last)
      ls = sanitize_like(last)
      <<~SQL
        CASE
          WHEN unaccent(LOWER(graduates.firstname)) = unaccent(LOWER('#{fe}'))
               AND unaccent(LOWER(graduates.lastname)) = unaccent(LOWER('#{le}')) THEN 1
          WHEN unaccent(graduates.firstname) ILIKE unaccent('#{fs}%')
               AND unaccent(graduates.lastname) ILIKE unaccent('#{ls}%') THEN 2
          WHEN unaccent(graduates.fullname) ILIKE unaccent('%#{fs}%#{ls}%') THEN 3
          WHEN SOUNDEX(graduates.firstname) = SOUNDEX('#{fe}')
               AND SOUNDEX(graduates.lastname) = SOUNDEX('#{le}') THEN 4
          ELSE 5
        END
      SQL
    else
      <<~SQL
        CASE
          WHEN unaccent(LOWER(graduates.firstname)) = unaccent(LOWER('#{fe}'))
               OR unaccent(LOWER(graduates.lastname)) = unaccent(LOWER('#{fe}')) THEN 1
          WHEN unaccent(graduates.firstname) ILIKE unaccent('#{fs}%')
               OR unaccent(graduates.lastname) ILIKE unaccent('#{fs}%') THEN 2
          WHEN unaccent(graduates.firstname) ILIKE unaccent('%#{fs}%')
               OR unaccent(graduates.lastname) ILIKE unaccent('%#{fs}%') THEN 3
          WHEN SOUNDEX(graduates.firstname) = SOUNDEX('#{fe}')
               OR SOUNDEX(graduates.lastname) = SOUNDEX('#{fe}') THEN 4
          ELSE 5
        END
      SQL
    end
  end

  def self.escape(str)
    str.to_s.gsub("'", "''")
  end

  def self.sanitize_like(str)
    escape(str).gsub("_", "\\_").gsub("%", "\\%")
  end
end
