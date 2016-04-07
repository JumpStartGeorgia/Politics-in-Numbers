# Detail class describes xlsx files specific sheet meta data
class Detail < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :notes
  embeds_many :detail_schemas
  embeds_many :terminators

  field :code, type: String
  field :orig_code, type: String
  field :title, type: String, localize: true
  field :header_row, type: Integer
  field :content_row, type: Integer
  field :fields_count, type: Integer
  # field :required_fields, type: Hash
  field :footer, type: Integer, default: 0

  validates_presence_of :code, :header_row, :content_row, :fields_count

  def title
    get_translation(title_translations)
  end

  def self.by_code(code)
    Detail.where({code: code }).first
  end
end
