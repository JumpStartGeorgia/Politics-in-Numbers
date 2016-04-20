# Dataset - trace category and detail data for party
# based on specific period
class Dataset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  embeds_many :category_datas
  embeds_many :detail_datas
  #belongs_to :party

  field :party_id, type: BSON::ObjectId
  field :period_id, type: BSON::ObjectId

  has_mongoid_attached_file :source, :path => ':attachment/:id/:style.:extension'


  validates_presence_of :party_id, :period_id
  validates_attachment :source, presence: true, content_type: { content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }, size: { in: 0..25.megabytes }
  #accepts_nested_attributes_for :category_datas, :detail_datas

  def self.sorted
    order_by([[:created_at, :desc]])
  end

  def party
    Party.find(party_id)
  end

  def period
    Period.find(period_id)
  end

  # def source
  #   Source.find(source_id)
  # end
end
