# DetailSchema class describes xlsx files
# specific column meta data
class DetailSchema
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
  field :required, type: Symbol, default: :nil
  field :default_value, type: String#, default: "0"

  validates_presence_of :title, :order, :output_order
  validates_inclusion_of :required, in: [:and, :or, :nil]
end
