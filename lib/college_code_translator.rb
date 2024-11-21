module CollegeCodeTranslator
  COLLEGE_CODE_MAP = {
    'CB' => { full_name: 'Massey College of Business', short_name: 'Business', icon: 'monitoring' },
    'CE' => { full_name: 'Curb College of Entertainment & Music Business', short_name: 'Curb', icon: 'album' },
    'CL' => { full_name: 'College of Law', short_name: 'Law', icon: 'gavel' },
    'CM' => { full_name: 'College of Sciences & Math', short_name: 'Sci & Math', icon: 'biotech' },
    'CN' => { full_name: 'Inman College of Nursing', short_name: 'Nursing', icon: 'ecg' },
    'CS' => { full_name: 'College of Lib. Arts & Soc Sci', short_name: 'CLASS', icon: 'history_edu' },
    'ED' => { full_name: 'College of Education', short_name: 'Education', icon: 'school' },
    'MP' => { full_name: 'College of Music & Performing Arts', short_name: 'Music & Perf Arts', icon: 'music_cast' },
    'OM' => { full_name: 'O\'More College Architecture & Design', short_name: 'O\'More', icon: 'domain' },
    'PH' => { full_name: 'College of Pharmacy & Health Sciences', short_name: 'Pharm & Health Sci', icon: 'local_pharmacy' },
    'UC' => { full_name: 'University College', short_name: 'Univ College', icon: 'home_work' },
    'WC' => { full_name: 'Watkins College of Art', short_name: 'Watkins', icon: 'palette' }
  }.freeze

  def self.translate_full(college_code)
    COLLEGE_CODE_MAP[college_code]&.dig(:full_name) || 'Unknown College'
  end

  def self.translate_short(college_code)
    COLLEGE_CODE_MAP[college_code]&.dig(:short_name) || 'Unknown College'
  end

  def self.icon(college_code)
    COLLEGE_CODE_MAP[college_code]&.dig(:icon) || 'help_outline' # Default icon if not found
  end
end