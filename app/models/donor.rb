# Donor class data about donors
class Donor
  include Mongoid::Document
  include Mongoid::Timestamps

  # belongs_to :party
end
