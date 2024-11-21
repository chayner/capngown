module GraduatesHelper

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
