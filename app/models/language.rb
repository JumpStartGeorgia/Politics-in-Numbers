# Language class
class Language
  include Mongoid::Document

  field :locale, type: String
  field :name, type: String

  ###############################

  # attr_accessible :locale, :name

  #############################
  # indexes
  index locale: 1, unique: true
  index name: 1

  #############################
  # Validations
  validates_presence_of :locale, :name

  # sort the languages with the default first, all available locales after
  # and then the remaining languages in alpha order
  def self.sorted
    default = I18n.default_locale
    available = I18n.available_locales.sort
    available.delete(default)

    # get all languages sorted
    sorted = order_by([[:name, :asc]]).to_a

    # move the default to be first
    lang = sorted.find_by(locale: default.to_s)
    sorted.delete(lang)
    sorted.insert(0, lang)

    # move the availables to be after first
    available.each_with_index do |avail, index|
      lang = sorted.find_by(locale: avail.to_s)
      sorted.delete(lang)
      sorted.insert(index + 1, lang)
    end

    sorted
  end

  # for the provided locale, get the name of the language
  def self.get_name(locale)
    x = only(:name).where(locale: locale).first
    return x.name if x.present?
  end
end
