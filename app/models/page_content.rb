class PageContent
  include Mongoid::Document
  include Mongoid::Timestamps

  #############################

  field :name, type: String
  field :title, type: String, localize: true
  field :content, type: String, localize: true

  #############################

  # indexes
  index ({ :name => 1})

  #############################
  # Validations
  validates_presence_of :name
  validates_uniqueness_of :name

  # validate the translation fields
  # title need to be validated for presence

  #############################
  # Callbacks
  before_save :set_to_nil

  # if title or content are '', reset value to nil so fallback works
  def set_to_nil
    self.title_translations.keys.each do |key|
      self.title_translations[key] = nil if !self.title_translations[key].nil? && self.title_translations[key].empty?
    end

    self.content_translations.keys.each do |key|
      self.content_translations[key] = nil if !self.content_translations[key].nil? && self.content_translations[key].empty?
    end
  end

  #############################

  def self.by_name(name)
    find_by(name: name)
  end

end
