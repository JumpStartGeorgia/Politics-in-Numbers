# Party class - meta information about parties
class Party# < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  #before_update :check_changed_attributes


  #has_many :party_data
  TYPES = [:party, :initiative]

  field :name, type: String
  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :color, type: String, default: "##{SecureRandom.hex(3)}"
  field :tmp_id, type: Integer
  field :type, type: Integer, default: 0 # 0 - party, 1 - initiative
  field :permalink, type: String, localize: true
  slug :permalink, :title, history: true, localize: true do |d|
    puts "------------#{d.inspect}"
    if d.permalink_changed?
      d.permalink.to_url
    elsif d.title_changed?
      d.title.to_url
    else
      d.id.to_s
    end
  end
  # rake mongoid_slug:set this is not working

  validate :validate_translations
  validates_presence_of :color, :type, :name
  # def title
  #   get_translation(title_translations)
  # end

  # # def name
  # #   get_translation(name_translations)
  # # end

  # def description
  #   get_translation(description_translations)
  # end

  # def check_changed_attributes
  #   puts "***************************"
  #   puts "***************************#{changes.inspect}" if _slugs?
  # end

  def validate_translations
    default = I18n.default_locale
    locales = [:ka, :en, :ru]
#    puts "validating --------------------------------#{_slugs_translations.inspect}"
    [title_translations, description_translations].each{|f|
      #f.delete_if{|k,v| !v.present? }
      if f[default].blank?
        errors.add(:base, I18n.t('errors.messages.translation_default_lang',
          field_name: self.class.human_attribute_name(f),
          language: Language.name_by_locale(I18n.default_locale),
          msg: I18n.t('errors.messages.blank')) )
      end
    }
  end

  def self.clean_name(name)
    name.gsub!("მოქალაქეთა პოლიტიკური გაერთიანება","")
    name.gsub!("პოლიტიკური გაერთიანება","")
    name.gsub!("პოლიტიკური პარტია","")
    name.gsub!("მ.პ.გ.","")
    name.gsub!("მ,პ.გ.","")
    name.gsub!("მ.პ.გ","")
    name.gsub!("მ.პ. გ ","")
    name.gsub!("პ.გ.","")
    name.gsub!("პ.პ","")
    name.gsub!("ა.ა.ი.პ","")
    name.gsub!("ა(ა)იპ","")
    name.gsub!("- ","")
    name.gsub!("  ","")
    name.gsub!("\"","")

    return name.strip
  end

  def self.sorted
    order_by([[:title, :asc]]).limit(3)
  end

  # def self.by_permalink(permalink)
  #   find_by(permalink: permalink)
  # end

  def self.by_name(party_name)
    puts "-------------------------party_name1----#{Party.clean_name(party_name)}"
    Party.where({name: Party.clean_name(party_name)}).first
  end

  def self.is_initiative(party_name)
    patterns = [
      "საინიციატივო ჯგუფი",
      "საინიციატივოს ჯგუფი",
      "საინიციატიცო ჯგუფი",
      "საინიციაივო ჯგუფი",
      "საინიციტივო ჯგუფი",
      "საინციატივო ჯგუფი",
      "საინიციატივო"
    ]
    is_initiative = false
    patterns.each {|d|
      is_initiative = true if party_name.include?(d)
    }
    is_initiative
  end

  def self.types
    col = {}
    TYPES.each_with_index{|d, i|
      col[I18n.t("mongoid.options.party.type.#{d}")] = i
    }
    col
  end

  def self.is_type(tp)
    begin
      tp.to_i < TYPES.length
    rescue
      false
    end
  end
end
