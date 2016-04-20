# Source class that have path to xlsx files
class Source
  include Mongoid::Document
  include Mongoid::Timestamps

  field :path, type: String
  validates_presence_of :path
end
