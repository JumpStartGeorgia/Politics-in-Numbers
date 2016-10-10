# Donor class - donation data for parties by give date
class Donor
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  before_save :regenerate_fullname
  embeds_many :donations, after_add: :calculate_donated_amount, after_remove: :calculate_donated_amount

  NATURE_TYPES = ["individual", "organization"]

  field :first_name, type: String, localize: true
  field :last_name, type: String, localize: true
  field :full_name, type: String, localize: true
  field :tin, type: String
  field :donated_amount, type: Float
  field :nature, type: Integer, default: 0
  field :multiple, type: Boolean, default: false # if donated to multiple parties
  field :color, type: String, default: "##{SecureRandom.hex(3)}"

  slug :full_name, history: true, localize: true

  validates_presence_of :first_name, :last_name, :tin

  scope :by_tin, -> v { where("tin" => v) }

  #############################
  # indexes
  index ({ :tin => 1})
  index ({ :first_name => 1, :last_name => 1})
  index ({ :multiple => 1})
  index ({ :'donations.party_id' => 1})
  index ({ :'donations.give_data' => 1})
  index ({ :'donations.amount' => 1})
  index ({ :'donations.monetary' => 1})
  index({_slugs: 1}, { unique: true, sparse: false })



  def permalink
    slug.present? ? slug : id.to_s
  end

  def self.get_ids_by_slugs(id_or_slugs)
    id_or_slugs = [] if !id_or_slugs.present?
    id_or_slugs = id_or_slugs.delete_if(&:blank?)
    if id_or_slugs.class == Array
      x = only(:_id, :_slugs).find(id_or_slugs)
      x.present? ? x.map{ |m| m[:_id].to_s } : []
    else
      []
    end
  end

  def calculate_donated_amount(v)
    self.donated_amount = 0
    tmp_party_ids = []
    donations.each{ |e|
      self.donated_amount += e.amount.round(2)
      tmp_party_ids.push(e.party_id.to_s)
    }
    self.multiple = tmp_party_ids.uniq.size > 1
    save
  end

  def self.sorted
    order_by([[:first_name, :asc], [:last_name, :asc]])
  end

  def self.list
    sorted.map{|t| [t.permalink, t.full_name]}
  end

  def self.list_with_tin
    sorted.map{|t| [t.permalink, t.full_name, t.tin, t.color]}
  end

  def self.filter(params)
    #Rails.logger.debug("****************************************#{params}")
    lang = I18n.locale
    result = []
    options = []
    matches = []
    conditions = []

    matches.push({ "_id": { "$in": params[:donor_ids].map{|m| BSON::ObjectId(m)} } }) if params[:donor_ids].present?
    matches.push({ "multiple": { "$eq": params[:multiple] } }) if params[:multiple] == true

    if params[:parties].present?
      tmp = params[:parties].map{|m| BSON::ObjectId(m) }
      matches.push({ "donations.party_id": { "$in": tmp } })
      ors = []
      tmp.each{|e| ors.push({ "$eq": ["$$donation.party_id", e ] }) }
      conditions.push({ "$or": ors });
    end

    tmp = params[:period][0]
    if tmp.present? && tmp != -1
      matches.push({ "donations.give_date": { "$gte": tmp } })
      conditions.push({"$gte": [ "$$donation.give_date", tmp ]})
    end

    tmp = params[:period][1]
    if tmp.present? && tmp != -1
      matches.push({ "donations.give_date": { "$lte": tmp } })
      conditions.push({"$lte": [ "$$donation.give_date", tmp ]})
    end

    tmp = params[:amount][0]
    if tmp.present? && tmp != -1
      matches.push({ "donations.amount": { "$gte": tmp } })
      conditions.push({"$gte": [ "$$donation.amount", tmp ]})
    end

    tmp = params[:amount][1]
    if tmp.present? && tmp != -1
      matches.push({ "donations.amount": { "$lte": tmp } })
      conditions.push({"$lte": [ "$$donation.amount", tmp ]})
    end

    tmp = params[:monetary]
    if tmp.present? && tmp == true || tmp == false
      matches.push({ "donations.monetary": { "$eq": tmp } })
      conditions.push({"$eq": [ "$$donation.monetary", tmp ]})
    end

    tmp = params[:nature]
    matches.push({ "nature": { "$eq": tmp } }) if tmp == 0 || tmp == 1

    options.push({ "$match": { "$and": matches } }) if !matches.blank?

    #if !conditions.blank?
      options.push({
        "$project": {
          name: { "$concat": ["$first_name.#{lang}", " ", "$last_name.#{lang}"] },
          tin: 1,
          nature: 1,
          donated_amount: 1,
          donations: {
            "$filter": {
              input: "$donations",
              as: "donation",
              cond: { "$and": conditions }
            }

          }
        }
       })
    #end
    options.push({ "$sort": { donated_amount: -1, name: 1 } })
    #if !matches.blank? || !conditions.blank?
      # Rails.logger.debug("-------------------------------------aggregate options-------#{options}")
      result = collection.aggregate(options)
    #end
    result
  end

  def self.date_span
    collection.aggregate(
       [
        { "$unwind": "$donations" },
        {
          "$group": {
          "_id": nil, #"$_id",
          "first_date": { "$min": "$donations.give_date" },
          "last_date": { "$max": "$donations.give_date" }
          }
        }
      ]
    ).first
  end
  def self.explore(params, only_table = false)
    limiter = 5
     # Rails.logger.debug("--------------------------------------------#{}")
    f = {
      donor_ids: nil,
      parties: nil,
      monetary: nil,
      multiple: nil,
      period: [-1,-1],
      amount: [-1,-1],
      nature: nil
    }

    f[:donor_ids] = Donor.get_ids_by_slugs(params[:donor])

    # f[:period] = Period.get_ids_by_slugs(params[:period])

    tmp = params[:period]
    f[:period] = tmp.map{|t| Time.at(t.to_i/1000) } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }
     # Rails.logger.debug("--------------------------------------------#{f[:period]}")

    if f[:period][0] != -1 && f[:period][1] != -1
      chart_subtitle = "#{I18n.l(f[:period][0], format: :date)} - #{I18n.l(f[:period][1], format: :date)}"
    else
      dte = Donor.date_span
      chart_subtitle = "#{I18n.l(dte[:first_date], format: :date)} - #{I18n.l(dte[:last_date], format: :date)}"
    end

    tmp = params[:amount]
    f[:amount] = tmp.map{|t| t.to_i } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.to_i.to_s == t }

    f[:parties] = Party.get_ids_by_slugs(params[:party])

    tmp = params[:monetary]
    f[:monetary] = tmp == "yes" if tmp == "yes" || tmp == "no"

    f[:multiple] = true if params[:multiple] == "yes"

    tmp = params[:nature]
    f[:nature] = tmp == "individual" ? 0 : 1 if tmp == "individual" || tmp == "organization"
    data = filter(f).to_a
    # Rails.logger.debug("---------------------------------------#{params}--#{f}")
    # TODO refactor code to remove ambitious code
    chart1 = []
    chart2 = []
    chart1_n = 0
    chart2_n = 0
    table = []
    total_amount = 0
    total_donations = 0
    monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
    nature_values = [I18n.t("mongoid.attributes.donor.nature_values.individual"), I18n.t("mongoid.attributes.donor.nature_values.organization")]
    parties = {}
    Party.each{|e| parties[e.id] = { value: 0, name: e.title } }

    chart_meta = [
      ["top_5_donors", "top_5_parties"],
      ["top_5_donors_for_party", "last_5_donations_for_party"],
      ["top_5_donors_for_parties", "total_donations_for_parties"],
      ["last_5_donations_for_donor", "top_5_parties_donated_to"],
      ["total_donations_for_each_donor", "top_5_parties_donated_to"],
      ["donors_donations_sorted_by_amount", "parties_donations_sorted_by_amount"]
    ]
    chart1_meta_obj = { n: 0, obj: nil, objb: nil }
    chart2_meta_obj = { n: 0, obj: nil, objb: nil }

    ds = f[:donor_ids].nil? ? 0 : f[:donor_ids].length
    ps = f[:parties].nil? ? 0 : f[:parties].length

    # ds == 0 && ps == 0
    # ds == 0 && ps == 1
    # ds == 0 && ps > 1
    # ds == 1 && ps == 0
    # ds > 1 && ps == 0
    # ds >= 1 && ps >= 1

    chart_type = ds == 0 ? ( ps == 0 ? 0 : ( ps == 1 ? 1 : 2) ) : ( ps == 0 ? ( ds == 1 ? 3 : 4) : 5 )

    recent_donations = []
    parties_list = {}

    data.each{|e|
      e[:partial_donated_amount] = 0
      e[:donations].each { |ee|
        am = ee[:amount]
        parties[ee[:party_id]][:value] += am if chart_type == 0


        if chart_type == 2 || chart_type == 3 || chart_type == 4 || chart_type == 5
          if !parties_list[ee[:party_id]].present?
            parties_list[ee[:party_id]] = { value: 0, name: parties[ee[:party_id]][:name] }
          end
          parties_list[ee[:party_id]][:value] += am
        end

        recent_donations.push({ date: ee[:give_date], out: { name: e[:name], value: am } }) if chart_type == 1
        recent_donations.push({ date: ee[:give_date], out: { name: parties[ee[:party_id]][:name], value: am } }) if chart_type == 3

        e[:partial_donated_amount] += am
        total_amount += am
        total_donations += 1
        table.push(["#{ee[:_id]}", e[:name], e[:tin], nature_values[e[:nature]], I18n.l(ee[:give_date], format: :date), am, parties[ee[:party_id]][:name], monetary_values[ee[:monetary] ? 0 : 1] ])
      }
      e[:partial_donated_amount] = e[:partial_donated_amount].round(2)
    }
    parties.each_pair { |k, v| parties[k][:value] = v[:value].round(2) }
    parties_list.each_pair { |k, v| parties_list[k][:value] = v[:value].round(2) }
    total_amount = total_amount.round(2)

    if chart_type == 0 # If select anything other than party and donor -> charts show the top 5

      chart1 = pull_n(data, limiter, :donated_amount, "shared.chart.label.donors")
      chart2 = pull_n(parties.sort_by { |k, v| -1*v[:value] }.map{|k,v| v }, limiter, :value, "shared.chart.label.parties")

    elsif chart_type == 1 # If select 1 party -> top 5 donors for party, last 5 donations for party

      chart1_meta_obj[:obj], chart2_meta_obj[:obj] = parties[BSON::ObjectId(f[:parties][0])][:name]
      chart1 = pull_n(data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }, limiter, :partial_donated_amount, "shared.chart.label.donors")
      chart2 = pull_n(recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.map{|m| m[:out] }, limiter, :value, "shared.chart.label.donations")

    elsif chart_type == 2 || chart_type == 4 # If select > 1 party -> top 5 donors for parties, total donations for selected parties
      # If select > 1 donor-> total donations for each donor, top 5 parties donated to

      chart1 = pull_n(data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }, limiter, :partial_donated_amount, "shared.chart.label.#{chart_type == 2 ? 'donors' : 'donations'}")
      chart2 = pull_n(parties_list.map{|k,v| v }.sort{ |x,y| y[:name] <=> x[:name] }, limiter, :value, "shared.chart.label.#{chart_type == 2 ? 'donations' : 'parties'}")

      chart1_meta_obj[:obj] = chart1.map{|m| m[0] }.join(", ") if chart_type == 4
      chart2_meta_obj[:obj] = chart2.map{|m| m[0] }.join(", ") if chart_type == 4

    elsif chart_type == 3 # If select 1 donor-> last 5 donations for donor, top 5 parties donated to

      chart1 = pull_n(recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.map{|m| m[:out] }, limiter, :value, "shared.chart.label.donations")
      chart2 = pull_n(parties_list.map{|k,v| v }.sort{ |x,y| y[:name] <=> x[:name] }, limiter, :value, "shared.chart.label.parties")

      chart1_meta_obj[:obj] = chart1.map{|m| m[0] }.join(", ")
      chart2_meta_obj[:obj] = chart2.map{|m| m[0] }.join(", ")

    elsif chart_type == 5 # show selected donors sorted by who donated most and show selected parties sorted by who received most

      chart1 = pull_n(data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }, limiter, :partial_donated_amount, "shared.chart.label.donations")
      chart2 = pull_n(parties_list.map{|k,v| v }.sort{ |x,y| y[:value] <=> x[:value] }, limiter, :value, "shared.chart.label.donations")

      chart1_meta_obj[:obj] = chart1.map{|m| m[0] }.join(", ")
      chart1_meta_obj[:objb] = chart2.map{|m| m[0] }.join(", ")

      chart2_meta_obj[:obj] = chart2.map{|m| m[0] }.join(", ")
      chart2_meta_obj[:objb] = chart1.map{|m| m[0] }.join(", ")

    end
    chart1_meta_obj[:n] = chart1.size
    chart2_meta_obj[:n] = chart2.size

    {
      table: {
        data: table.sort { |x,y| [x[1], x[2]] <=> [y[1], y[2]] },
        header: [human_attribute_name(:id), human_attribute_name(:name), human_attribute_name(:tin),
          human_attribute_name(:nature), Donation.human_attribute_name(:give_date),
          Donation.human_attribute_name(:amount), Donation.human_attribute_name(:party),
          Donation.human_attribute_name(:monetary)],
        classes: ["center", "", "center", "center", "center", "right", "", "center"],
        total_amount: total_amount,
        total_donations: total_donations
      }
    }.merge(only_table ? {} :
      {
        chart1: chart1,
        chart1_title: I18n.t("shared.chart.title.#{chart_meta[chart_type][0]}", chart1_meta_obj),
        chart2: chart2,
        chart2_title: I18n.t("shared.chart.title.#{chart_meta[chart_type][1]}", chart2_meta_obj),
        chart_subtitle: chart_subtitle
      }
    )
  end
  def self.download_filter(params)
    #Rails.logger.debug("****************************************#{params}")
    lang = I18n.locale
    result = []
    options = []
    matches = []
    conditions = []

    tmp = params[:period][0]
    if tmp.present? && tmp != -1
      matches.push({ "donations.give_date": { "$gte": tmp } })
      conditions.push({"$gte": [ "$$donation.give_date", tmp ]})
    end

    tmp = params[:period][1]
    if tmp.present? && tmp != -1
      matches.push({ "donations.give_date": { "$lte": tmp } })
      conditions.push({"$lte": [ "$$donation.give_date", tmp ]})
    end

    options.push({ "$match": { "$and": matches } }) if !matches.blank?

    #if !conditions.blank?
      options.push({
        "$project": {
          first_name: "$first_name.#{lang}",
          last_name: "$last_name.#{lang}",
          tin: 1,
          nature: 1,
          donations: {
            "$filter": {
              input: "$donations",
              as: "donation",
              cond: { "$and": conditions }
            }

          }
        }
       })
    #end
    options.push({ "$sort": { give_date: -1, name: 1 } })
    #if !matches.blank? || !conditions.blank?
      # Rails.logger.debug("-------------------------------------aggregate options-------#{options}")
      result = collection.aggregate(options)
    #end
    result
  end
  def self.download(params, with_zip = false)

    f = { period: [-1,-1] }

    tmp = params[:period]
    f[:period] = tmp.map{|t| Time.at(t.to_i/1000) } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }
     # Rails.logger.debug("--------------------------------------------#{f[:period]}")

    if f[:period][0] != -1 && f[:period][1] != -1
      chart_subtitle = "#{I18n.l(f[:period][0], format: :date)} - #{I18n.l(f[:period][1], format: :date)}"
    else
      dte = Donor.date_span
      chart_subtitle = "#{I18n.l(dte[:first_date], format: :date)} - #{I18n.l(dte[:last_date], format: :date)}"
    end

    data = download_filter(f).to_a
    # Rails.logger.debug("---------------------------------------#{params}--#{f}")
    table = []
    parties = {}
    Party.each{|e| parties[e.id] = { value: 0, name: e.title } }

    recent_donations = []
    parties_list = {}
    monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
    nature_values = [I18n.t("mongoid.attributes.donor.nature_values.individual"), I18n.t("mongoid.attributes.donor.nature_values.organization")]

    workbook = RubyXL::Workbook.new
    worksheet = workbook[0] #.add_worksheet('Sheet2')

    [
      "#",
      Donation.human_attribute_name(:give_date),
      human_attribute_name(:first_name),
      human_attribute_name(:last_name),
      human_attribute_name(:tin),
      Donation.human_attribute_name(:amount),
      Donation.human_attribute_name(:party),
      Donation.human_attribute_name(:comment),
      human_attribute_name(:nature),
      Donation.human_attribute_name(:monetary)
    ].each_with_index { |e,i|
      worksheet.add_cell(0, i, e)
    }
    i = 1
    min_date = Date.new(2050,1,1)
    max_date = Date.new(1970,1,1)
    data.each{|e|
      e[:donations].each { |ee|
        max_date = ee[:give_date] if ee[:give_date] > max_date
        min_date = ee[:give_date] if ee[:give_date] < min_date
        worksheet.add_cell(i, 0, i)
        worksheet.add_cell(i, 1, I18n.l(ee[:give_date], format: :date))
        worksheet.add_cell(i, 2, e[:first_name])
        worksheet.add_cell(i, 3, e[:last_name])
        worksheet.add_cell(i, 4, e[:tin])
        worksheet.add_cell(i, 5, ee[:amount])
        worksheet.add_cell(i, 6, parties[ee[:party_id]][:name])
        worksheet.add_cell(i, 7, ee[:comment])
        worksheet.add_cell(i, 8, nature_values[e[:nature]])
        worksheet.add_cell(i, 9, monetary_values[ee[:monetary] ? 0 : 1])
        i+=1
      }
    }
    filename = "#{I18n.t("root.download.filename_donation")}-#{I18n.l(min_date, format: :filename)}-#{I18n.l(max_date, format: :filename)}.xlsx"
      #send_data workbook.stream.string, filename: "myworkbook.xlsx",disposition: 'attachment'





   compressed_filestream = Zip::OutputStream.write_buffer do |zp|
      zp.put_next_entry filename
      zp.print workbook.stream.string
    end
    compressed_filestream.rewind
    # Rails.logger.fatal("--------------------------------------------#{compressed_filestream.size}")
    #send_data compressed_filestream.read, filename: "animals.zip"
    sz = compressed_filestream.size
    # compressed_filestream.close

    {
      table: {
        header: ["", I18n.t("root.download.filename"), I18n.t("root.download.filename_period")],
        data: [[1, filename, "#{I18n.l(min_date, format: :date)}-#{I18n.l(max_date, format: :date)}"]],
        classes: ["", "", "center"]
      },
      size: ActionController::Base.helpers.number_to_human_size(sz)
    }.merge(with_zip ? { file: compressed_filestream.read } : {})
  end
  private
    def regenerate_fullname
      tmp = {}
      self.first_name_translations.each{|k,v|
        tmp[k] = "#{v} #{self.last_name_translations[k]}"
      }
      self.full_name_translations = tmp
    end

    def self.pull_n (data, n, key, str) # get n rows grouped by key from data, with counting distinct item count and if > 1 than output with str else just name
      grp_h = { }
      grp_a = []
      d_i = 0

      data.each_with_index{ |e, e_i|
        break if d_i >= n
        ek = e[key].round
        if !grp_h.key?(ek)
          break if e_i >= n
          grp_h[ek] = 0
          grp_a << [e[:name], ek]
          d_i += 1
        end
        grp_h[ek] += 1
      }
      str = I18n.t(str)
      grp_a.each_with_index {|e,i|
        if grp_h[e[1]] > 1
          grp_a[i][0] = "#{grp_h[e[1]]} #{str}"
        end
      }
    end
end

  # scope :by_donors, -> v { where(:id.in => v) if v.present? }
  #scope :by_party, -> v { where("party_id" => { "$in": v.map{|m| BSON::ObjectId(m) } }) if v.present?}
  # scope :from_date, -> v { where("donations.give_date" => { "$gte":  v}) if v.present? && v != -1 }
  # scope :to_date, -> v { where("donations.give_date" => { "$lte":  v}) if v.present? && v != -1 }
  # scope :from_amount, -> v { where("donations.amount" => { "$gte":  v}) if v.present? && v != -1 }
  # scope :to_amount, -> v { where("donations.amount" => { "$lte":  v}) if v.present? && v != -1 }
  # scope :where_monetary, -> v { where("donations.monetary" => v) if v == true || v == false }
  # scope :only_multiple_donations, -> v { where("donations.1" => { "$exists" => true }) if v == true }
  # d.collection.aggregate([{ "$project": { "name": {"$concat": ["$first_name","-","$last_name"] } }}]).first
  #scope :pair_by_donors, -> v { where(:id.in => v).aggregate([{ "$project": { "name": {"$concat": ["$first_name","-","$last_name"] } }}]) if v.present? }
   # d.collection.aggregate([ { "$match": { tin: "17001006279"}}, { "$project": { "name": {"$concat": ["$first_name","-","$last_name"] } }}])
   #


# "donation"=>{"donor"=>["574d9379fbb6bd0313000007", "574d9379fbb6bd0313000014"],
#  "period"=>["1464724800000", "1464897600000"],
#   "amount"=>["100", "500"],
#    "party"=>["5748093cfbb6bd3781000016", "5748093cfbb6bd3781000027"],
#     "type"=>"monetary",
#      "multiple"=>"yes"},
#       "locale"=>"en"}
#res = Donor.sorted_by_amount.limit(5).map{|m| { value: m.amount, name: "#{m.first_name} #{m.last_name}" } }
# require 'digest'
# { data: donors, id: Digest::MD5.hexdigest(["d",donor_ids,period,amount,parties,monetary,multiple].join(";"))}



  # def self.by_party(v)
  #   if v.present?
  #     v.map!{|m| BSON::ObjectId(m) }
  #     collection.aggregate([
  #       { "$match": { "donations.party_id": { "$in": v } } },
  #       { "$project": {
  #           first_name: 1,
  #           last_name: 1,
  #           tin: 1,
  #           nature: 1,
  #           donations: {
  #             "$filter": {
  #                 input: "$donations",
  #                 as: "donation",
  #                 cond: { "$$donation.party_id": { "$in": v } }
  #             }
  #           }
  #         }
  #       }
  #     ]).collection.criteria
  #   else
  #     self
  #   end
  # end

  # def self.pair_by_donors(ids) #id name
  #   res = {}
  #   collection.aggregate([ { "$match": { "_id": { "$in": ids.map{|m| BSON::ObjectId(m) } } } }, { "$project": { "name": {"$concat": ["$first_name"," ","$last_name"] } }}]).each{|d|
  #     res[d[:_id].to_s] = d[:name]
  #   }
  #   res
  # end


       #Rails.logger.debug("-------------------------------------#{data.to_a}-------#{data.map{|m| m}.length}")
    # donors = Donor
    #         .by_donors(f.donor_ids)
    #         .by_party(f.parties)
    #         .from_date(f.period[0])
    #         .to_date(f.period[1])
    #         .from_amount(f.amount[0])
    #         .to_amount(f.amount[1])
    #         .where_monetary(f.monetary)
    #         .only_multiple_donations(f.multiple)
    #         #.order_by(donated_amount: :desc)
