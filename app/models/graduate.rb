class Graduate < ApplicationRecord
  self.primary_key = "buid"
  has_many :brags, primary_key: "buid", foreign_key: "buid"
  has_many :cords, primary_key: "buid", foreign_key: "buid"

  # Belmont campus emails follow `pref_first.last@bruins.belmont.edu`. The local
  # part before the first dot is what the student answers to. We use this to
  # backfill `preferredfirst` when the spreadsheet didn't include one.
  #
  # Returns nil when:
  #   - email is blank or unparseable
  #   - the local part is too short to be a real nickname (initials, e.g. "j")
  #   - the derived name matches `formal_first` (case-insensitive) — no nickname
  def self.preferred_first_from_email(email, formal_first = nil)
    return nil if email.blank?

    local = email.to_s.split("@", 2).first.to_s.split(".", 2).first.to_s.strip
    return nil if local.length < 2

    candidate = local.split("-").map { |part| part.downcase.capitalize }.join("-")
    return nil if formal_first.present? && candidate.casecmp(formal_first.to_s.strip) == 0

    candidate
  end

  # Some rosters put the full preferred name ("Cameron Bateman") in the
  # `preferredfirst` column. When we then concatenate `preferredlast` we get
  # the surname twice on the sticker ("BATEMAN, CAMERON BATEMAN"). Strip a
  # trailing surname token (case-insensitive) when present.
  #
  # Returns the cleaned string, or the original (stripped of whitespace) if
  # nothing matched. Returns nil for blank input.
  def self.sanitize_preferred_first(value, *surnames)
    s = value.to_s.strip
    return nil if s.empty?

    surnames.map { |n| n.to_s.strip }.reject(&:empty?).uniq.each do |surname|
      # Match " Surname" at end of string, case-insensitive, with optional trailing punctuation.
      pattern = /\s+#{Regexp.escape(surname)}\.?\z/i
      if s =~ pattern
        cleaned = s.sub(pattern, "").strip
        return cleaned unless cleaned.empty?
      end
    end
    s
  end

  # Mirror of `sanitize_preferred_first` for `preferredlast`: strip a leading
  # given-name token (e.g. preferredlast "Cameron Bateman" with firstname
  # "Cameron").
  def self.sanitize_preferred_last(value, *given_names)
    s = value.to_s.strip
    return nil if s.empty?

    given_names.map { |n| n.to_s.strip }.reject(&:empty?).uniq.each do |given|
      pattern = /\A#{Regexp.escape(given)}\.?\s+/i
      if s =~ pattern
        cleaned = s.sub(pattern, "").strip
        return cleaned unless cleaned.empty?
      end
    end
    s
  end

  # Display helpers used by the sticker view. Always go through these so a
  # stray full-name in `preferredfirst` can't double-print the surname.
  def display_preferred_first
    self.class.sanitize_preferred_first(preferredfirst.presence || firstname, lastname, preferredlast)
  end

  def display_preferred_last
    self.class.sanitize_preferred_last(preferredlast.presence || lastname, firstname, preferredfirst)
  end

  # True when the formal first/last differs from the preferred first/last
  # in any user-visible way (case-insensitive). Used by the sticker view to
  # decide whether to print the formal name as a smaller secondary line.
  def formal_name_differs_from_preferred?
    pref_first = display_preferred_first.to_s.strip
    pref_last  = display_preferred_last.to_s.strip
    formal_first = firstname.to_s.strip
    formal_last  = lastname.to_s.strip

    first_diff = pref_first.present? && pref_first.casecmp(formal_first) != 0
    last_diff  = pref_last.present?  && pref_last.casecmp(formal_last)  != 0
    first_diff || last_diff
  end
end