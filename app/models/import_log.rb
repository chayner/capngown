class ImportLog < ApplicationRecord
  belongs_to :user, optional: true

  IMPORT_TYPES = %w[graduates brags cords reset].freeze

  validates :import_type, presence: true, inclusion: { in: IMPORT_TYPES }

  scope :recent, ->(limit = 25) { order(created_at: :desc).limit(limit) }

  serialize :warnings, coder: JSON

  def display_type
    import_type.titleize
  end
end
