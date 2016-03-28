class Party
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :party_data

  field :name, type: String
  field :summary, type: String
end
