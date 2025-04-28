class GraduatesController < ApplicationController
  before_action :set_graduate, only: [:show, :update, :checkin, :print], except: [:show_bulk, :bulk_print]

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
    
    @graduates = Graduate.includes(:brags)
    
    
    if fullname.present?
      # Split the input into individual words
      words = fullname.strip.split(/\s+/)
      # Build a query for each word to match across all relevant fields
      words.each do |word|
        @graduates = @graduates.where(
          'lower(lastname) LIKE :word OR lower(firstname) LIKE :word OR lower(preferredlast) LIKE :word OR lower(preferredfirst) LIKE :word',
          word: "%#{word.downcase}%"
        )
      end
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

  def update
    # @graduate = Graduate.find_sole_by(buid: params[:buid])

    if params[:graduate][:height]
      @graduate.height = params[:graduate][:height]

      if @graduate.save
        redirect_to graduate_path(buid: @graduate.buid)
      else
        render :show
      end
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
    @total_undergrad = Graduate.where(levelcode: 'UG').count
    @total_master = Graduate.where(levelcode: 'GR-M').count
    @total_doctorate = Graduate.where(levelcode: 'GR-D').count

    # Students already printed
    @printed_undergrad = Graduate.where.not(printed: nil).where(levelcode: 'UG').count
    @printed_master = Graduate.where.not(printed: nil).where(levelcode: 'GR-M').count
    @printed_doctorate = Graduate.where.not(printed: nil).where(levelcode: 'GR-D').count
  
    # Percentages
    @percent_printed_undergrad = @total_undergrad.zero? ? 0 : (@printed_undergrad * 100.0 / @total_undergrad).round(1)
    @percent_printed_master = @total_master.zero? ? 0 : (@printed_master * 100.0 / @total_master).round(1)
    @percent_printed_doctorate = @total_doctorate.zero? ? 0 : (@printed_doctorate * 100.0 / @total_doctorate).round(1)
    
    # Graduates who have picked up their brag cards
    @total_graduates_with_brag_cards = Graduate.joins(:brags).distinct.count(:buid)
    @graduates_with_brag_cards = Graduate.joins(:brags) # Assuming brags is a relation
                                          .where.not(printed: nil)
                                          .distinct.count(:buid)
    @percent_brag_pickedup = @total_graduates_with_brag_cards.zero? ? 0 : (@graduates_with_brag_cards * 100.0 / @total_graduates_with_brag_cards).round(1)
    

    @college_stats = Graduate.group(:college1).pluck(:college1).map do |college_code|
      full_name = CollegeCodeTranslator.translate_full(college_code)
    
      total = Graduate.where(college1: college_code).count
      printed = Graduate.where(college1: college_code).where.not(printed: nil).count
      percent = total.zero? ? 0 : ((printed.to_f / total) * 100).round(1)
      {
        college_code: college_code,
        college_name: full_name,
        printed: printed,
        total: total,
        percent: percent
      }
    end.sort_by { |college| college[:college_name] }

    # Printed data over time
    @printed_over_time = Graduate.where.not(printed: nil)
                                 .group_by_hour(:printed, format: '%m/%d %l%P', series: false, time_zone: 'Central Time (US & Canada)')
                                 .count

    @printed_undergrad_over_time = Graduate.where.not(printed: nil).where(levelcode: 'UG')
                                 .group_by_hour(:printed, format: '%m/%d %l%P', series: false, time_zone: 'Central Time (US & Canada)')
                                 .count

    @printed_master_over_time = Graduate.where.not(printed: nil).where(levelcode: 'GR-M')
                                .group_by_hour(:printed, format: '%m/%d %l%P', series: false, time_zone: 'Central Time (US & Canada)')
                                .count
    
    @printed_doctorate_over_time = Graduate.where.not(printed: nil).where(levelcode: 'GR-D')
    .group_by_hour(:printed, format: '%m/%d %l%P', series: false, time_zone: 'Central Time (US & Canada)')
    .count

    @brags_over_time = Graduate.joins(:brags)
                        .where.not(printed: nil)
                        .group_by_hour(:printed, format: '%m/%d %l%P', series: false, time_zone: 'Central Time (US & Canada)')
                        .distinct
                        .count(:buid)
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
    params.require(:graduate).permit(:height)
  end

end
