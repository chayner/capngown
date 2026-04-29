class GraduatesController < ApplicationController
  before_action :set_graduate, only: [:show, :edit, :update, :checkin, :print], except: [:show_bulk, :bulk_print]

  def start

  end

  def results
    @graduate = Graduate.includes(:brags).find_sole_by(buid: params[:buid], fullname: params[:fullname])
    
    if @graduate
      redirect_to action: 'confirm', buid: params[:buid]
    else
      redirect_to action: 'index'
    end
  end

  def list
    fullname = params[:fullname]
    checkedin = params[:checkedin]
    program = params[:program]
    degree = params[:degree]
    college = params[:college]
    has_brag = params[:has_brag]
    has_cord = params[:has_cord]
    
    @graduates = Graduate.includes(:brags)
    
    
    if fullname.present?
      @graduates = GraduateSearch.search(@graduates, fullname)
    end

     # Program filter
    if program.present?
      @graduates = @graduates.where('major ILIKE ?', "%#{params[:program]}%")
    end
  
    # degree filter
    if degree.present?
      @graduates = @graduates.where(degree1: degree)
    end

    # College filter
    if college.present?
      @graduates = @graduates.where(college1: college)
    end

    # Filter by graduates who have at least one brag card
    if has_brag == "true"
      @graduates = @graduates.joins(:brags)
    end

    # Filter by graduates who have at least one cord
    if has_cord == "true"
      @graduates = @graduates.joins("INNER JOIN cords ON cords.buid = graduates.buid")
    end
  
    @graduates = @graduates.order(:lastname, :firstname)
    
    if checkedin != "show"
      @graduates = @graduates.where('checked_in IS NULL')
    end
     # buid: buid, firstname: firstname, lastname: lastname)

    # Preload all cords for the graduates
    @cords_by_buid = Cord.where(buid: @graduates.pluck(:buid)).index_by(&:buid)
  end

  def to_print
    printed = params[:printed]
    @graduates = Graduate.where('checked_in IS NOT NULL').order(:checked_in)
    if printed != "show"
      @graduates = @graduates.where('printed IS NULL')
    end
  end

  #B00610448,B00489639

  def show
    # @graduate = Graduate.find_sole_by(buid: params[:buid])
  end

  def show_bulk
    # Split the BUIDs by commas and trim whitespace
    @buids = params[:buids]&.split(',')
    
    # Fetch graduates matching the provided BUIDs
    @graduates = Graduate.where(buid: @buids).order(:lastname, :firstname)
    # @graduates = Graduate.where(buid: params[:buid]) # Fetch graduates by IDs passed in params
  end

  def bulk_print
    checkval = params[:print] == "clear" ? nil : Time.now

    @buids = params[:buids]&.split(',')
    @graduates = Graduate.where(buid: @buids)

    updated_count = 0

    @graduates.each do |graduate|
      updated_count += 1 if update_graduate(graduate, :printed, checkval)
    end
  
    if params[:print] == "clear"
      message = "#{updated_count} graduates successfully marked as not printed."
    else
      message = "#{updated_count} graduates successfully marked as printed."
    end
    
    redirect_to show_bulk_path(buids: params[:buids]), notice: message
  end

  def edit
  end

  def update
    # Height-only update from the badge modal keeps its legacy behavior
    # (no flash, no extra fields). Anything else goes through the general
    # edit form (name fields, etc.).
    if params[:graduate].keys == ["height"]
      if @graduate.update(height: params[:graduate][:height])
        redirect_to graduate_path(buid: @graduate.buid)
      else
        render :show, status: :unprocessable_entity
      end
      return
    end

    if @graduate.update(graduate_params)
      redirect_to graduate_path(buid: @graduate.buid), notice: "Graduate updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def checkin
    checkval = params[:checkin] == "clear" ? nil : Time.now
    update_graduate(@graduate, :checked_in, checkval)

    redirect_to graduate_path(@graduate)

  end

  def print
    checkval = params[:print] == "clear" ? nil : Time.now
    update_graduate(@graduate, :printed, checkval)

    redirect_to graduate_path(@graduate, print: true)
  end

  def get_print_html
    printed = params[:printed]
    @graduates = Graduate.where('checked_in IS NOT NULL').order(:checked_in)
    if printed != "show"
      @graduates = @graduates.where('printed IS NULL')
    end
    html_string = render_to_string partial: 'print_list', locals: { graduates: @graduates }
    render html: html_string
  end

  def stats
    # Total counts for undergraduates and graduates
    @total_undergrad = Graduate.undergraduate.count
    @total_master = Graduate.master.count
    @total_doctorate = Graduate.doctorate.count

    # Students already printed
    @printed_undergrad = Graduate.undergraduate.where.not(printed: nil).count
    @printed_master = Graduate.master.where.not(printed: nil).count
    @printed_doctorate = Graduate.doctorate.where.not(printed: nil).count

    # Percentages
    @percent_printed_undergrad = @total_undergrad.zero? ? 0 : (@printed_undergrad * 100.0 / @total_undergrad).round(1)
    @percent_printed_master = @total_master.zero? ? 0 : (@printed_master * 100.0 / @total_master).round(1)
    @percent_printed_doctorate = @total_doctorate.zero? ? 0 : (@printed_doctorate * 100.0 / @total_doctorate).round(1)

    @total_printed = Graduate.where.not(printed: nil).count
    @total_graduates = Graduate.count
    @percent_printed = @total_graduates.zero? ? 0 : (@total_printed * 100.0 / @total_graduates).round(1)

    # Graduates who have picked up their brag cards
    @total_graduates_with_brag_cards = Graduate.joins(:brags).distinct.count(:buid)
    @graduates_with_brag_cards = Graduate.joins(:brags)
                                         .where.not(printed: nil)
                                         .distinct.count(:buid)
    @percent_brag_pickedup = @total_graduates_with_brag_cards.zero? ? 0 : (@graduates_with_brag_cards * 100.0 / @total_graduates_with_brag_cards).round(1)

    # Graduates receiving cords
    @total_with_cords = Cord.distinct.count(:buid)
    @printed_with_cords = Graduate.where.not(printed: nil).where(buid: Cord.select(:buid)).distinct.count(:buid)
    @percent_printed_with_cords = @total_with_cords.zero? ? 0 : (@printed_with_cords * 100.0 / @total_with_cords).round(1)
    
    # College-level stats with program breakdown
    @college_stats = Graduate.group(:college1).pluck(:college1).map do |college_code|
      full_name = CollegeCodeTranslator.translate_full(college_code)
      total = Graduate.where(college1: college_code).count
      printed = Graduate.where(college1: college_code).where.not(printed: nil).count
      percent = total.zero? ? 0 : ((printed.to_f / total) * 100).round(1)

      # Program breakdown within each college
      programs = Graduate.where(college1: college_code).group(:major).pluck(:major).compact.map do |major|
        program_total = Graduate.where(college1: college_code, major: major).count
        program_printed = Graduate.where(college1: college_code, major: major).where.not(printed: nil).count
        program_percent = program_total.zero? ? 0 : ((program_printed.to_f / program_total) * 100).round(1)
        {
          major: major,
          printed: program_printed,
          total: program_total,
          percent: program_percent
        }
      end.sort_by { |p| -p[:percent] }

      {
        college_code: college_code,
        college_name: full_name,
        printed: printed,
        total: total,
        percent: percent,
        programs: programs
      }
    end.sort_by { |college| -college[:percent] }

    # Printed stats over time
    interval_param = params[:interval] == "15min" ? :group_by_minute : :group_by_hour
    format_str = interval_param == :group_by_minute ? "%m/%d %l:%M %P" : "%m/%d %l %P"

    @printed_over_time = Graduate.where.not(printed: nil)
                                 .public_send(interval_param, :printed, time_zone: "Central Time (US & Canada)")
                                 .count

    @printed_undergrad_over_time = Graduate.undergraduate.where.not(printed: nil)
                                           .public_send(interval_param, :printed, time_zone: "Central Time (US & Canada)")
                                           .count

    @printed_master_over_time = Graduate.master.where.not(printed: nil)
                                        .public_send(interval_param, :printed, time_zone: "Central Time (US & Canada)")
                                        .count

    @printed_doctorate_over_time = Graduate.doctorate.where.not(printed: nil)
                                           .public_send(interval_param, :printed, time_zone: "Central Time (US & Canada)")
                                           .count

    @brags_over_time = Brag.joins(:graduate)
                           .where.not(graduates: { printed: nil })
                           .public_send(interval_param, "graduates.printed", time_zone: "Central Time (US & Canada)")
                           .count

    if params[:interval] == "15min"
      @printed_over_time = @printed_over_time.group_by do |time, _|
        Time.at((time.to_i / 900) * 900) # round down to nearest 15 min
      end.transform_values { |entries| entries.sum { |_, count| count } }

      @printed_undergrad_over_time = @printed_undergrad_over_time.group_by do |time, _|
        Time.at((time.to_i / 900) * 900) # round down to nearest 15 min
      end.transform_values { |entries| entries.sum { |_, count| count } }

      @printed_master_over_time = @printed_master_over_time.group_by do |time, _|
        Time.at((time.to_i / 900) * 900) # round down to nearest 15 min
      end.transform_values { |entries| entries.sum { |_, count| count } }

      @printed_doctorate_over_time = @printed_doctorate_over_time.group_by do |time, _|
        Time.at((time.to_i / 900) * 900) # round down to nearest 15 min
      end.transform_values { |entries| entries.sum { |_, count| count } }

      @brags_over_time = @brags_over_time.group_by do |time, _|
        Time.at((time.to_i / 900) * 900) # round down to nearest 15 min
      end.transform_values { |entries| entries.sum { |_, count| count } }
    end
  end

  private

  def update_graduate(graduate, field, value)
    graduate.update(field => value)
  rescue StandardError => e
    Rails.logger.error "Failed to update Graduate #{graduate.buid}: #{e.message}"
    false
  end
  
  def set_graduate
    @graduate = Graduate.find_sole_by(buid: params[:buid])
  end

  def graduate_params
    params.require(:graduate).permit(:height, :firstname, :lastname, :preferredfirst, :preferredlast, :notes)
  end

end
