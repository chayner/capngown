class Brag < ApplicationRecord
    belongs_to :graduate, primary_key: "buid", foreign_key: "buid", optional: true
end
