require "csv"

class Admin::ReportsController < Admin::BaseController
  EXPORT_COLUMNS = %w[
    buid lastname firstname middlename suffix preferredfirst
    levelcode college1 collegedesc degree1 hoodcolor major honors
    campusemail height checked_in printed graduation_term
  ].freeze

  def graduates
    @scope = params[:scope].presence_in(%w[all checked_in not_checked_in]) || "all"
    @term  = params[:graduation_term].to_s.strip
    @existing_terms = Graduate.where.not(graduation_term: nil)
                              .distinct.order(graduation_term: :desc).pluck(:graduation_term)

    relation = filtered_relation

    respond_to do |format|
      format.html do
        @count = relation.count
      end
      format.csv do
        send_data build_csv(relation),
          type: "text/csv",
          filename: "graduates_#{@scope}#{@term.present? ? "_#{@term}" : ""}_#{Time.current.strftime("%Y%m%d_%H%M")}.csv"
      end
    end
  end

  private

  def filtered_relation
    relation = Graduate.all
    relation = relation.where(graduation_term: @term) if @term.present?
    case @scope
    when "checked_in"
      relation = relation.where.not(checked_in: nil)
    when "not_checked_in"
      relation = relation.where(checked_in: nil)
    end
    relation
  end

  def build_csv(relation)
    CSV.generate do |csv|
      csv << EXPORT_COLUMNS
      relation.find_each(batch_size: 500) do |grad|
        csv << EXPORT_COLUMNS.map { |c| grad.public_send(c) }
      end
    end
  end
end
