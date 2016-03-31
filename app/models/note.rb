# Note class - for detail and detail_schema classes to keep notes
class Note < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :detail

  field :star, type: Integer
  field :text, type: String, localize: true

  validates_presence_of :star, :text
  def text
    get_translation(text_translations)
  end
end
