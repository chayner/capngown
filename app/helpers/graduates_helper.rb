module GraduatesHelper

  def college(abbriviation)
    colleges = {
      'CB' => 'College of Business',
      'CE' => 'Curb College of Entertainment',
      'CH' => 'College of Health Sciences',
      'ED' => 'College of Education',
      'MP' => 'Music Performace'
    }

    return colleges[abbriviation]
  end

  def degree(abbr)
    degrees = {
      'BA' => 'Bachelor of Arts',
      'BBA' => 'Bachelor of Business Administration',
      'MAT' => 'Master of Arts in Teaching',
      'MM' => 'Master of Music'

    }

    return degrees[abbr]
  end
end
