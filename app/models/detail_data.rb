# DetailData class - trace party detail data
# It is embed in Dataset class, meta data is taken from Detail class
class DetailData
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :dataset
  # belongs_to :note

  field :table, type: Array
  field :detail_id, type: BSON::ObjectId

  validates_presence_of :table, :detail_id

  def detail
    @detail = Detail.find(detail_id)

  end

  def detail_name
    @detail = detail if @detail.nil?
    if @detail.present?
      @detail.title
    else
      I18n.t("shared.common.unknown")
    end
  end
end
