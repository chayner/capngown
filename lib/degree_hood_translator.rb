module DegreeHoodTranslator
  DEGREE_HOOD_MAP = {
    'DNP' => { hood_color: 'Apricot', degree: 'Doctor of Nursing Practice', level: 'Doctoral' },
    'DOT' => { hood_color: 'Slate Blue', degree: 'Doctor of Occupational Therapy', level: 'Doctoral' },
    'DPT' => { hood_color: 'Teal', degree: 'Doctor of Physical Therapy', level: 'Doctoral' },
    'EDS' => { hood_color: 'Light Blue', degree: 'Education Specialist (EDS)', level: 'Doctoral' },
    'JD' => { hood_color: 'Purple', degree: 'Juris Doctor (Law)', level: 'Doctoral' },
    'JD/MBA' => { hood_color: 'Purple + Light Brown/ Drab (2)', degree: 'Law / Professional MBA', level: 'Doctoral/Masters' },
    'MACC' => { hood_color: 'Light Brown/ Drab', degree: 'Master of Accountancy', level: 'Masters' },
    'MAE' => { hood_color: 'White', degree: 'Master of Art (English)', level: 'Masters' },
    'MA' => { hood_color: 'White', degree: 'Master of Art', level: 'Masters' },
    'MAT' => { hood_color: 'Light Blue', degree: 'Master of Arts in Teaching', level: 'Masters' },
    'MBA' => { hood_color: 'Light Brown/ Drab', degree: 'Master of Business Administration', level: 'Masters' },
    'MED' => { hood_color: 'Light Blue', degree: 'Master of Education', level: 'Masters' },
    'MFA' => { hood_color: 'Brown', degree: 'Master of Fine Arts', level: 'Masters' },
    'MHC' => { hood_color: 'White', degree: 'Master of Art (Mental Health Counseling)', level: 'Masters' },
    'MM' => { hood_color: 'Pink', degree: 'Master of Music', level: 'Masters' },
    'MS' => { hood_color: 'Golden Yellow', degree: 'Master of Science', level: 'Masters' },
    'MSA' => { hood_color: 'Golden Yellow', degree: 'Master of Sport Administration', level: 'Masters' },
    'MSN' => { hood_color: 'Apricot', degree: 'Master of Science in Nursing', level: 'Masters' },
    'MSOT' => { hood_color: 'Slate Blue', degree: 'Master of Science in Occupational Therapy', level: 'Masters' },
    'MSW' => { hood_color: 'Citron Yellow', degree: 'Master of Social Work', level: 'Masters' },
    'PHARMD' => { hood_color: 'Olive Green', degree: 'Doctor of Pharmacy', level: 'Doctoral' },
    'PHARMD/MBA' => { hood_color: 'Olive Green + Light Brown/ Drab (2)', degree: 'Pharmacy / Professional MBA', level: 'Doctoral/Masters' },
    'PHD' => { hood_color: 'Dark Blue', degree: 'Doctor of Philosophy', level: 'Doctoral' },
    'MD' => { hood_color: 'Green', degree: 'Doctor of Medicine', level: 'Doctoral' }
  }

  # Additional full-name → code mappings for degree descriptions that don't
  # exactly match the canonical `degree:` text in DEGREE_HOOD_MAP. Add new
  # entries here whenever an import surfaces a description we don't recognize.
  DEGREE_NAME_ALIASES = {
    'juris doctor'                                       => 'JD',
    'master of arts'                                     => 'MA',
    'post professional doctor of occupational therapy'   => 'DOT'
  }.freeze

  def self.translate(degree_code)
    DEGREE_HOOD_MAP[degree_code] || { hood_color: 'Unknown', degree: 'Unknown', level: 'Unknown' }
  end

  # Reverse-lookup a degree code from a full degree name. Tries exact match
  # against DEGREE_HOOD_MAP[:degree] first, then DEGREE_NAME_ALIASES. Returns
  # nil when no match. Case-insensitive.
  def self.code_from_name(name)
    s = name.to_s.strip
    return nil if s.empty?

    lower = s.downcase
    DEGREE_HOOD_MAP.each { |code, info| return code if info[:degree].downcase == lower }
    DEGREE_NAME_ALIASES[lower]
  end
end