module GraduatesHelper
  def program_options_grouped_by_college
    programs_by_college = Graduate.all.group_by(&:college1).transform_keys do |college_code|
      CollegeCodeTranslator.translate_full(college_code)
    end
  
    programs_by_college.transform_values do |graduates|
      graduates.map { |g| g.major&.split('/')&.first }
               .compact
               .map(&:strip) # remove extra spaces
               .uniq
               .sort
    end
  end

  def degree_options
    Graduate.where.not(degree1: nil).pluck(:degree1).uniq.sort
  end

  def college_options
    Graduate.where.not(college1: nil)
          .pluck(:college1)
          .uniq
          .map { |code| [CollegeCodeTranslator.translate_full(code), code] }
          .sort_by { |label, _code| label }
  end
  
  # Count the number of graduates in a group who are print
  def printed_graduates_count_for_group(buids)
    Graduate.where(buid: buids)
      .where.not(printed: nil )  # Check if 'printed' is not nil
      .distinct
      .count('buid')
  end

  # Check if there are any graduates remaining to print
  def any_remaining_to_print_for_group?(buids)
    buids.count > printed_graduates_count_for_group(buids)
  end

  # Count the number of graduates in a group who are checked in
  def checked_in_graduates_count_for_group(buids)
    Graduate.where(buid: buids)
      .where.not(checked_in: nil)  # Check if 'checked_in' is not nil
      .distinct
      .count('buid')
  end

  # Check if there are any graduates remaining to check in
  def any_remaining_to_check_in_for_group?(buids)
    buids.count > checked_in_graduates_count_for_group(buids)
  end

end
