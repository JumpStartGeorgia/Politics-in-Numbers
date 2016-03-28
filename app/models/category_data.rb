class CategoryData

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :party_data

  field :ctype, type: Integer
  value :value, type: Float
  field :category_id, type: BSON::ObjectId
  validates_presence_of :ctype, :value, :category_id
  def category
    Category.find(self.category_id)
  end
end
