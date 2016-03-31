# Terminator class, save point where file parser should stop,
# table last line catcher
class Terminator
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :detail

  field :term, type: String
  field :field_index, type: Integer

  validates_presence_of :term, :field_index
end
