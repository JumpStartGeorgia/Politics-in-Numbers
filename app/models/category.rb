# Category class - trace party categories and sub categories
class Category < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :category_data

  field :code, type: String
  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :sub, type: Boolean, default: false
  field :parent_id, type: BSON::ObjectId
  field :simple, type: Boolean, default: false
  field :detail_id, type: BSON::ObjectId
  field :cells, type: String
  field :languages, type: Array
  field :default_language, type: String

  index code: 1
  index title: 1
  index parent_id: 1
  index simple: 1
end
