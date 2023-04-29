class GraduatesController < ApplicationController
  before_action :set_graduate, only: [:show, :update, :checkin, :print]

  def start

  end

  def results
    @graduate = Graduate.find_sole_by(buid: params[:buid], lastname: params[:lastname])

    if @graduate
      redirect_to action: 'confirm', buid: params[:buid]
    else
      redirect_to action: 'index'
    end
  end

  def list
    lastname = params[:lastname]
    checkedin = params[:checkedin]
    @graduates = Graduate.where('lower(lastname) LIKE lower(?)', "%" + lastname + "%").order(:lastname, :firstname)
    if checkedin != "show"
      @graduates = @graduates.where('checked_in IS NULL')
    end
     # buid: buid, firstname: firstname, lastname: lastname)
  end

  def to_print
    printed = params[:printed]
    @graduates = Graduate.where('checked_in IS NOT NULL').order(:checked_in)
    if printed != "show"
      @graduates = @graduates.where('printed IS NULL')
    end
  end

  def show


    # @graduate = Graduate.find_sole_by(buid: params[:buid])
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
    @graduate.update(checked_in: checkval)
    redirect_to graduate_path(@graduate)
  end

  def print
    checkval = params[:print] == "clear" ? nil : Time.now
    @graduate.update(printed: checkval)
    redirect_to graduate_path(@graduate, print: true)
  end

  private

  def set_graduate
    @graduate = Graduate.find_sole_by(buid: params[:buid])
  end

  def graduate_params
    params.require(:graduate).permit(:height)
  end

end
