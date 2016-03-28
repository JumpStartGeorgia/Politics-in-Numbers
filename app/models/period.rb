class Party

  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :party_data
end
