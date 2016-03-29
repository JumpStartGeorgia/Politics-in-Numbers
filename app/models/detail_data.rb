class DetailData

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :party_data
  #belongs_to :note

  field :table, type: Array
  field :detail_id, type: BSON::ObjectId

  validates_presence_of :table, :detail_id

  def detail
    Detail.find(self.detail_id)
  end
end
