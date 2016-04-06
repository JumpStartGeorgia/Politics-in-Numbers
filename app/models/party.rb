# Party class - meta information about parties
class Party < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  #has_many :party_data

  field :title, type: String, localize: true
  field :name, type: String, localize: true
  field :summary, type: String, localize: true
  field :tmp_id, type: Integer

  def title
    get_translation(title_translations)
  end

  def name
    get_translation(name_translations)
  end

  def summary
    get_translation(summary_translations)
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

  def self.id_by_name(party_name)
    Party.where({name: Party.clean_name(party_name)}).first
  end
end
