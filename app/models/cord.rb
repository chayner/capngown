class Cord < ApplicationRecord
  self.primary_key = nil
  belongs_to :graduate, primary_key: "buid", foreign_key: "buid"

  # Validations (optional)
  validates :buid, presence: true
  validates :cord_type, presence: true
end
