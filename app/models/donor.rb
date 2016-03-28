class Donor

  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :party
end
