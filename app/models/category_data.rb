# Trace party categories and sub categories data
# It is embed in Dataset class, meta data is taken from Category class
class CategoryData
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :dataset

  #field :type, type: Integer
  field :value, type: Float
  field :category_id, type: BSON::ObjectId
  validates_presence_of :value, :category_id

  def category
    @category = Category.find(category_id)

  end

  def category_name
    @category = category if @category.nil?
    if @category.present?
      @category.title
    else
      I18n.t("shared.common.unknown")
    end
  end
end
