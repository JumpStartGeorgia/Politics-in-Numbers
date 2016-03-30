class Detail < CustomTranslation
  #1, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 8.1, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7 
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
  field :fields_to_skip, type: Array, default: []
  field :footer, type: Integer, default: 0
  
  validates_presence_of :code, :header_row, :content_row, :fields_count

  def title
    get_translation(self.title_translations)
  end
end  
