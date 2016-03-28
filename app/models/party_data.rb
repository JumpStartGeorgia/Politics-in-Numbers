class PartyData

  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :category_data
  embeds_many :detail_data  

  field :party_id, type: BSON::ObjectId
  field :period_id, type: BSON::ObjectId

  validates_presence_of :party_id, :period_id

  def party
    Party.find(self.party_id)
  end
  def period
    Period.find(self.period_id)
  end
end
