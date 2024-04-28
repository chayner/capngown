class Graduate < ApplicationRecord
  self.primary_key = "buid"
  has_many :brags, primary_key: "buid", foreign_key: "buid"
end