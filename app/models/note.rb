# Note class - for detail and detail_schema classes to keep notes
class Note
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :detail

  field :star, type: Integer
  field :text, type: String, localize: true

  validates_presence_of :star, :text
end
