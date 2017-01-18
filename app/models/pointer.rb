# Party class - meta information about parties
class Pointer
  include Mongoid::Document
  embedded_in :category
  # VERSIONS = [:version_lt_2016, :version_greater_2016]
  field :version, type: Integer, default: 0
  field :forms, type: Array
  field :cells, type: Array
  field :codes, type: Array

end
