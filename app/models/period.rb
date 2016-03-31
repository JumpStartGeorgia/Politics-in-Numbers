# Period class meta information about parties
class Period < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #has_many :party_data

  field :type, type: String
  field :start_date, type: Date
  field :end_date, type: Date
  field :title, type: String, localize: true
  field :description, type: String, localize: true

  validates_presence_of :type, :start_date, :end_date, :title
  validates_inclusion_of :type, in: %w(annual election)

  index({ type: 1, start_date: 1 }, unique: true)
  # rake db:mongoid:create_indexes

  def title
    get_translation(title_translations)
  end

  def description
    get_translation(description_translations)
  end
end
