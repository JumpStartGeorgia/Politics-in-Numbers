# DetailData class - trace party detail data
# It is embed in PartyData class, meta data is taken from Detail class
class DetailData
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :party_data
  # belongs_to :note

  field :table, type: Array
  field :detail_id, type: BSON::ObjectId

  validates_presence_of :table, :detail_id

  def detail
    Detail.find(detail_id)
  end
end
