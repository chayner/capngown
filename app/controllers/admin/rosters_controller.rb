class Admin::RostersController < Admin::BaseController
  CONFIRMATION_PHRASE = "RESET ROSTER"

  def destroy
    if params[:confirmation].to_s.strip != CONFIRMATION_PHRASE
      redirect_to admin_imports_path,
        alert: "Reset cancelled — confirmation phrase did not match (must type '#{CONFIRMATION_PHRASE}')."
      return
    end

    scope = params[:scope]
    term  = params[:graduation_term].to_s.strip

    if scope == "term"
      if term.blank?
        redirect_to admin_imports_path, alert: "Reset cancelled — no term selected."
        return
      end
      destroy_term(term)
    elsif scope == "all"
      destroy_all
    else
      redirect_to admin_imports_path, alert: "Reset cancelled — unknown scope."
      return
    end
  end

  private

  def destroy_term(term)
    counts = nil
    ActiveRecord::Base.transaction do
      buids = Graduate.where(graduation_term: term).pluck(:buid)
      brag_count = Brag.where(buid: buids).delete_all
      cord_count = Cord.where(buid: buids).delete_all
      grad_count = Graduate.where(buid: buids).delete_all
      counts = { graduates: grad_count, brags: brag_count, cords: cord_count }
    end
    log_reset!(scope: "term", graduation_term: term, counts: counts)
    redirect_to admin_imports_path,
      notice: "Reset term #{term}: removed #{counts[:graduates]} graduates, #{counts[:brags]} brags, #{counts[:cords]} cords."
  end

  def destroy_all
    counts = nil
    ActiveRecord::Base.transaction do
      brag_count = Brag.delete_all
      cord_count = Cord.delete_all
      grad_count = Graduate.delete_all
      counts = { graduates: grad_count, brags: brag_count, cords: cord_count }
    end
    log_reset!(scope: "all", graduation_term: nil, counts: counts)
    redirect_to admin_imports_path,
      notice: "Reset all rosters: removed #{counts[:graduates]} graduates, #{counts[:brags]} brags, #{counts[:cords]} cords."
  end

  def log_reset!(scope:, graduation_term:, counts:)
    ImportLog.create!(
      user: current_user,
      import_type: "reset",
      filename: "scope=#{scope}#{graduation_term ? " term=#{graduation_term}" : ""}",
      row_count: counts[:graduates],
      inserts: 0,
      updates: 0,
      skipped: 0,
      graduation_term: graduation_term,
      succeeded: true,
      warnings: ["graduates=#{counts[:graduates]}", "brags=#{counts[:brags]}", "cords=#{counts[:cords]}"]
    )
  end
end
