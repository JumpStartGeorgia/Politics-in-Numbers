# Party class - meta information about parties
class Party < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #has_many :party_data

  field :name, type: String, localize: true
  field :summary, type: String, localize: true

  def name
    get_translation(name_translations)
  end

  def summary
    get_translation(summary_translations)
  end
end
