class DetailSchema < CustomTranslation

  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :notes
  embedded_in :detail

  field :title, type: String, localize: true
  field :orig_title, type: String
  field :field_type, type: String
  field :order, type: Integer
  field :output_order, type: Integer
  field :footer, type: String
  field :skip, type: Boolean, default: false

  validates_presence_of :title, :order, :output_order

  def title
    get_translation(self.title_translations)
  end

end
