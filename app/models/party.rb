# Party class - meta information about parties
class Party < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  #has_many :party_data

  field :title, type: String, localize: true
  field :name, type: String, localize: true
  field :summary, type: String, localize: true
  field :color, type: String
  field :tmp_id, type: Integer
  field :type, type: Integer, default: 0 # 0 - party, 1 - initiative
  slug :title, history: true, localize: true # rake mongoid_slug:set this is not working

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

  def self.sorted
    order_by([[:title, :asc]])
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
end
