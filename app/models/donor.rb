# Donor class - donation data for parties by give date
class Donor
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  before_save :regenerate_fullname
  after_create  :prune_share_images

  embeds_many :donations, after_add: :calculate_donated_amount, after_remove: :calculate_donated_amount
  accepts_nested_attributes_for :donations
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

  validates_presence_of :first_name
  # validates_presence_of :tin, :if => :last_name?

  # scope :by_tin, -> v { where("tin" => v) }
  # scope :by_tin, -> v { where("tin" => v) }
  # scope :by_tin, -> v { where("tin" => v) }

  #############################
  # indexes
  index ({ :tin => 1})
  index ({ :first_name => 1, :last_name => 1, :tin => 1 })
  index ({ :multiple => 1})
  index ({ :'donations.party_id' => 1})
  index ({ :'donations.give_data' => 1})
  index ({ :'donations.amount' => 1})
  index ({ :'donations.monetary' => 1})
  index({_slugs: 1}, { unique: true, sparse: false })

  def permalink
    id.to_s #slug.present? ? slug : id.to_s
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
    da = 0 # donated amount
    tmp_party_ids = []
    donations.each{ |e|
      da += e.amount.round(2)
      tmp_party_ids.push(e.party_id.to_s)
    }
    # self.update_attributes!(
    #   donated_amount: da,
    #   multiple:
    # )
    self.set(donated_amount: da)
    self.set(multiple: tmp_party_ids.uniq.size > 1)
    # save
  end

  def self.sorted
    order_by([[:first_name, :asc], [:last_name, :asc]])
  end

  def self.list
    sorted.map{|t| [t.permalink, t.full_name]}
  end

  def self.list_with_tin
    # map = %Q{
    #   function() {
    #     emit(this.name, { likes: this.likes });
    #   }
    # }

    # reduce = %Q{
    #   function(key, values) {
    #     var result = { likes: 0 };
    #     values.forEach(function(value) {
    #       result.likes += value.likes;
    #     });
    #     return result;
    #   }
    # }
    # Band.map_reduce(map, reduce).out(inline: 1).each do |document|
    #   p document # { "_id" => "Tool", "value" => { "likes" => 200 }}
    # end

    sorted.map{|t| [t.permalink, t.full_name, t.tin]}
  end

  def self.filter(params)
    #Rails.logger.debug("****************************************#{params}")
    lang = I18n.locale
    result = []
    options = []
    matches = []
    conditions = []

    matches.push({ "_id": { "$in": params[:donor].map{|m| BSON::ObjectId(m)} } }) if params[:donor].present?
    matches.push({ "multiple": { "$eq": params[:multiple] } }) if params[:multiple].present? && params[:multiple] == true

    if params[:party].present?
      tmp = params[:party].map{|m| BSON::ObjectId(m) }
      matches.push({ "donations.party_id": { "$in": tmp } })
      ors = []
      tmp.each{|e| ors.push({ "$eq": ["$$donation.party_id", e ] }) }
      conditions.push({ "$or": ors });
    end

    if params[:period].present?
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
    end

    if params[:amount].present?
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
    end

    tmp = params[:monetary]
    if tmp.present? && tmp == true || tmp == false
      matches.push({ "donations.monetary": { "$eq": tmp } })
      conditions.push({"$eq": [ "$$donation.monetary", tmp ]})
    end

    tmp = params[:nature]
    matches.push({ "nature": { "$eq": tmp } }) if tmp.present? && tmp == 0 || tmp == 1

    options.push({ "$match": { "$and": matches } }) if !matches.blank?

    #if !conditions.blank?
      options.push({
        "$project": {
          name: { "$concat": ["$first_name.#{lang}", " ", "$last_name.#{lang}"] },
          first_name: "$first_name.#{lang}",
          last_name: "$last_name.#{lang}",
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

  def self.explore(params, type = "a", inner_pars = false)
    limiter = 5
     # Rails.logger.debug("--------------------------------------------#{}")
    default_f = {
      donor: nil,
      party: nil,
      monetary: nil,
      multiple: nil,
      period: [-1,-1],
      amount: [-1,-1],
      nature: nil
    }

    if inner_pars
      f = params
    else
      f = default_f.dup
      f[:donor] = Donor.get_ids_by_slugs(params[:donor])

      # f[:period] = Period.get_ids_by_slugs(params[:period])

      tmp = params[:period]
      if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }
        f[:period] = tmp.map { |t|
            n = Time.at(t.to_i/1000)
            Time.utc(n.year, n.month, n.day, 0, 0, 0)
          }
      end

      tmp = params[:amount]
      f[:amount] = tmp.map{|t| t.to_i } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.to_i.to_s == t }

      f[:party] = Party.get_ids_by_slugs(params[:party])

      tmp = params[:monetary]
      f[:monetary] = tmp == "true" if tmp == "true" || tmp == "false"

      f[:multiple] = true if params[:multiple] == "true"

      tmp = params[:nature]
      f[:nature] = tmp == "0" ? 0 : 1 if tmp == "0" || tmp == "1"
    end

     Rails.logger.fatal("---------------------232-----------------------#{f.inspect}")
    chart_subtitle = ""
    if f[:period].present? && f[:period][0] != -1 && f[:period][1] != -1
      chart_subtitle = "#{I18n.l(f[:period][0], format: :date)} - #{I18n.l(f[:period][1], format: :date)}"
    else
      dte = Donor.date_span
      chart_subtitle = "#{I18n.l(dte[:first_date], format: :date)} - #{I18n.l(dte[:last_date], format: :date)}" if dte.present?
    end


    data = filter(f).to_a
    # Rails.logger.debug("---------------------------------------#{params}--#{f}")
    # TODO refactor code to remove ambitious code
    ca = []
    cb = []
    ca_n = 0
    cb_n = 0
    table = []
    total_amount = 0
    total_donations = 0
    monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
    nature_values = [I18n.t("mongoid.attributes.donor.nature_values.individual"), I18n.t("mongoid.attributes.donor.nature_values.organization")]
    parties = {}
    Party.each{ |e| parties[e.id] = { value: 0, name: e.title } }


    ca_meta_obj = { n: 0, obj: nil, objb: nil }
    cb_meta_obj = { n: 0, obj: nil, objb: nil }

    ds = f[:donor].nil? ? 0 : f[:donor].length
    ps = f[:party].nil? ? 0 : f[:party].length

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
        nm = "#{e[:first_name]} #{e[:last_name]}"

        if chart_type == 2 || chart_type == 3 || chart_type == 4 || chart_type == 5
          if !parties_list[ee[:party_id]].present?
            parties_list[ee[:party_id]] = { value: 0, name: parties[ee[:party_id]][:name] }
          end
          parties_list[ee[:party_id]][:value] += am
        end

        recent_donations.push({ date: ee[:give_date], out: { name: nm, value: am } }) if chart_type == 1
        recent_donations.push({ date: ee[:give_date], out: { name: parties[ee[:party_id]][:name], value: am } }) if chart_type == 3

        e[:partial_donated_amount] += am
        total_amount += am
        total_donations += 1
        table.push(["#{ee[:_id]}", nm, e[:tin], nature_values[e[:nature]], I18n.l(ee[:give_date], format: :date), am, parties[ee[:party_id]][:name], monetary_values[ee[:monetary] ? 0 : 1] ])
      }
      e[:partial_donated_amount] = e[:partial_donated_amount].round(2)
    }
    parties.each_pair { |k, v| parties[k][:value] = v[:value].round(2) }
    parties_list.each_pair { |k, v| parties_list[k][:value] = v[:value].round(2) }
    total_amount = total_amount.round(2)

    if chart_type == 0 # If select anything other than party and donor -> charts show the top 5

      ca = pull_n(data, limiter, :donated_amount, "shared.chart.label.donors")
      cb = pull_n(parties.sort_by { |k, v| -1*v[:value] }.map{|k,v| v }, limiter, :value, "shared.chart.label.parties")

    elsif chart_type == 1 # If select 1 party -> top 5 donors for party, last 5 donations for party

      ca_meta_obj[:obj], cb_meta_obj[:obj] = parties[BSON::ObjectId(f[:party][0])][:name]
      ca = pull_n(data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }, limiter, :partial_donated_amount, "shared.chart.label.donors")
      cb = pull_n(recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.map{|m| m[:out] }, limiter, :value, "shared.chart.label.donations")

    elsif chart_type == 2 || chart_type == 4 # If select > 1 party -> top 5 donors for parties, total donations for selected parties
      # If select > 1 donor-> total donations for each donor, top 5 parties donated to

      ca = pull_n(data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }, limiter, :partial_donated_amount, "shared.chart.label.#{chart_type == 2 ? 'donors' : 'donations'}")
      cb = pull_n(parties_list.map{|k,v| v }.sort{ |x,y| y[:name] <=> x[:name] }, limiter, :value, "shared.chart.label.#{chart_type == 2 ? 'donations' : 'parties'}")

      ca_meta_obj[:obj] = ca.map{|m| m[0] }.join(", ") if chart_type == 4
      cb_meta_obj[:obj] = cb.map{|m| m[0] }.join(", ") if chart_type == 4

    elsif chart_type == 3 # If select 1 donor-> last 5 donations for donor, top 5 parties donated to

      ca = pull_n(recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.map{|m| m[:out] }, limiter, :value, "shared.chart.label.donations")
      cb = pull_n(parties_list.map{|k,v| v }.sort{ |x,y| y[:name] <=> x[:name] }, limiter, :value, "shared.chart.label.parties")

      ca_meta_obj[:obj] = ca.map{|m| m[0] }.join(", ")
      cb_meta_obj[:obj] = cb.map{|m| m[0] }.join(", ")

    elsif chart_type == 5 # show selected donors sorted by who donated most and show selected parties sorted by who received most

      ca = pull_n(data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }, limiter, :partial_donated_amount, "shared.chart.label.donations")
      cb = pull_n(parties_list.map{|k,v| v }.sort{ |x,y| y[:value] <=> x[:value] }, limiter, :value, "shared.chart.label.donations")

      ca_meta_obj[:obj] = ca.map{|m| m[0] }.join(", ")
      ca_meta_obj[:objb] = cb.map{|m| m[0] }.join(", ")

      cb_meta_obj[:obj] = cb.map{|m| m[0] }.join(", ")
      cb_meta_obj[:objb] = ca.map{|m| m[0] }.join(", ")

    end
    ca_meta_obj[:n] = ca.size
    cb_meta_obj[:n] = cb.size

     Rails.logger.fatal("fatal----------------------#{f.keys}")
    if ["a"].index(type).present?
      f.keys.each{|e|
        if f[e] == default_f[e]
          f.delete(e)
        else
          if f[e].class == Array
            if f[e].empty?
              f.delete(e)
            else
              f[e].each_with_index{|ee,ii|
                f[e][ii] = ee.to_s if ee.class == BSON::ObjectId
              }
            end
          end
        end
      }
      # Rails.logger.fatal("fatal----------------------#{f.keys}")
      sid = ShortUri.explore_uri(f.merge({filter: "donation"}))
    end

     # Rails.logger.fatal("fatal----------------------#{table.select{|f| f[1].nil? || f[2].nil? }.map {|m| [m[1], m[2]]}}")
    res = {}
    if ["t", "a"].index(type).present?
      res = {
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
      }
    end
    if ["ca", "a", "co", "coa"].index(type).present?
      res.merge!({
        ca: {
          series: ca,
          title: generate_title(ca_meta_obj, [chart_type, 0]),
          subtitle: chart_subtitle
        }
      })
    end
    if ["cb", "a", "co", "cob"].index(type).present?
      res.merge!({
        cb: {
          series: cb,
          title: generate_title(cb_meta_obj, [chart_type, 1]),
          subtitle: chart_subtitle
        }
      })
    end
    if ["a"].index(type).present?
      res.merge!({
        sid: sid,
        pars: f
      })
    end
    res
  end

  def self.download_filter(params)

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
    options.push({ "$sort": { give_date: -1, name: 1 } })
    collection.aggregate(options)
  end

  def self.download(params, type="table")

    f = { period: [-1,-1] }

    tmp = params[:period]
    f[:period] = tmp.map{|t| Time.at(t.to_i/1000) } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }

    data = download_filter(f).to_a

    parties = {}
    Party.each{|e| parties[e.id] = { value: 0, name: e.title } }
    min_date = Date.new(2050,1,1)
    max_date = Date.new(1970,1,1)
    filename_donation = I18n.t("root.download.filename_donation")
    if type == "table"
      data.each{|e|
        e[:donations].each { |ee|
          max_date = ee[:give_date] if ee[:give_date] > max_date
          min_date = ee[:give_date] if ee[:give_date] < min_date
        }
      }

      {
        table: {
          header: ["", I18n.t("root.download.filename"), I18n.t("root.download.filename_period")],
          data: [[1, filename_donation, "#{I18n.l(min_date, format: :date)} - #{I18n.l(max_date, format: :date)}"]],
          classes: ["", "", "center"]
        }
      }
    elsif type == "file" || type == "info"
      monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
      nature_values = [I18n.t("mongoid.attributes.donor.nature_values.individual"), I18n.t("mongoid.attributes.donor.nature_values.organization")]

      workbook = RubyXL::Workbook.new
      worksheet = workbook[0]

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
      ].each_with_index { |e,e_i|
        worksheet.add_cell(0, e_i, e)
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

    compressed_filestream = Zip::OutputStream.write_buffer do |zp|
      zp.put_next_entry "%s%s.xlsx" % [Helper.sanitize("#{filename_donation} ("), "#{I18n.l(min_date, format: :filename)}_#{I18n.l(max_date, format: :filename)})"]
      zp.print workbook.stream.string
    end
    compressed_filestream.rewind # not sure if close is needed compressed_filestream.close

    { size: ActionController::Base.helpers.number_to_human_size(compressed_filestream.size) }
    .merge(type == "file" ? {
      file: compressed_filestream.read,
      filename: "#{filename_donation}_#{I18n.l(min_date, format: :filename)}_#{I18n.l(max_date, format: :filename)}_(pins.ge).zip" } : {})
    end
  end

  private

    def prune_share_images
      begin
        I18n.available_locales.each { |lang|
          path = "#{Rails.root}/public/system/share_images/donation/#{lang}"
          if File.directory?(path)
            FileUtils.remove_entry_secure(path, force = true)
            FileUtils.mkdir_p(path)
          end
        }
        return true
      rescue
        return false
      end
    end

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

    def generate_title(data, indexes)

      title = []

      template_names = [
        ["top_5_donors", "top_5_parties"],
        ["top_5_donors_for_party", "last_5_donations_for_party"],
        ["top_5_donors_for_parties", "total_donations_for_parties"],
        ["last_5_donations_for_donor", "top_5_parties_donated_to"],
        ["total_donations_for_each_donor", "top_5_parties_donated_to"],
        ["donors_donations_sorted_by_amount", "parties_donations_sorted_by_amount"]
      ]

      templates = {
        top_5_donors:                       [ :for_parties, :block ],
        top_5_parties:                      [ :receiving_monetary_amount, :from_donors ],
        top_5_donors_for_party:             [ :block ],
        last_5_donations_for_party:         [ :block ],
        top_5_donors_for_parties:           [ :block ],
        total_donations_for_parties:        [ :block ],
        last_5_donations_for_donor:         [ :block ],
        top_5_parties_donated_to:           [ :block ],
        total_donations_for_each_donor:     [ :block ],
        donors_donations_sorted_by_amount:  [ :block ],
        parties_donations_sorted_by_amount: [ :block ],
      }
      template_name = template_names[indexes[0]][indexes[1]]
      template = templates[template_name]
      title << I18n.t("shared.chart.title.#{template_name}", data)
      template.each { |t|
        if t == :block
          title << I18n.t("shared.chart.title.to_multiple") if data[:multiple].present?

          tmp = []
          if data[:monetary].present?
            tmp = [I18n.t("shared.chart.title.monetary_donation",
             { s: I18n.t("shared.chart.title.monetary_#{data[:monetary].to_s}") })]
          end
          if data[:amount].present?
            if tmp.present?
              tmp << I18n.t("shared.chart.title.of_amount", { s: data[:amount] })
            else
              tmp [I18n.t("shared.chart.title.donation_of_amount", { s: data[:amount] })]
            end
          end
          title << tmp.join(" ") if tmp.present?
        # elsif t == :multiple && data[:multiple].present?
          # title << I18n.t("shared.chart.title.to_multiple")
        else t == :for_parties && data[:parties].present?
          title << I18n.t("shared.chart.title.for_parties", { s: data[:parties].join(", ") })
        elsif t == :receiving_monetary_amount
          tmp = ["", ""]
          if data[:monetary].present?
            tmp[0] = I18n.t("shared.chart.title.monetary_#{data[:monetary].to_s}")
          end
          if data[:amount].present?
            tmp[1] = I18n.t("shared.chart.title.of_amount", { s: data[:amount] })
          end
          title << I18n.t("shared.chart.title.receiving_monetary_amount", { m: tmp[0] , a: tmp[1] }
        elsif t == :from_donors
          tmp = nil
          if data[:nature].present?
            tmp = I18n.t("shared.chart.title.from_donors#{data[:multiple].present? ? '_who' : ''}",
             { s: I18n.t("shared.chart.title.nature_#{data[:nature]}") }
          end
          title << tmp if tmp.present?
          title << I18n.t("shared.chart.title.to_multiple") if data[:multiple].present?
        end
      }

      title.join("\n")


      # todo
        # top_5_donors: Top %{n}%{cs} Donors
        # top_5_parties: Top %{n} Parties/Candidates
        # top_5_donors_for_party: Top %{n} Donors for %{obj}
        # last_5_donations_for_party: Last %{n} Donations for %{obj}
        # top_5_donors_for_parties: Top %{n} Donors for %{obj}
        # total_donations_for_parties: Total Donations for %{obj}
        # last_5_donations_for_donor: Last %{n} Donations for %{obj}
        # top_5_parties_donated_to: Top %{n} Parties Donated to by %{obj}
        # total_donations_for_each_donor: Total Donations for %{obj}
        # donors_donations_sorted_by_amount: Top Donations by %{obj} to %{objb}
        # parties_donations_sorted_by_amount: Top Donations to %{objb} by %{obj}

        # templates = {
        #   top_5_donors:                       [ title: [:n, :nature], :for_parties, :block ],
        #   top_5_parties:                      [ title: [:n], :receiving_monetary_amount, :from_donors ],
        #   top_5_donors_for_party:             [ title: [:n, :parties], :block ],
        #   last_5_donations_for_party:         [ title: [:n, :party], :block ],
        #   top_5_donors_for_parties:           [ title: [:n, :for_parties], :block ],
        #   total_donations_for_parties:        [ title: [:for_parties], :block ],
        #   last_5_donations_for_donor:         [ title: [:n, :for_donor], :block ],
        #   top_5_parties_donated_to:           [ title: [:n, :donor], :block ],
        #   total_donations_for_each_donor:     [ title: [:donors], :block ],
        #   donors_donations_sorted_by_amount:  [ title: [:donors, :parties], :block ],
        #   parties_donations_sorted_by_amount: [ title: [:parties, :donors], :block ],
        # }

        #-------------------------------------------------------------------------------
        #--------------------------- top_5_donors

          # Top {{n}} {{nature}} Donors
          # {{for_parties}}
          # {{block}}

        #--------------------------- top_5_parties

          # Top {{n}} Parties/Candidates
          # Receiving {{monetary}} donation {{amount}}
          # from {{nature}} Donors {{who}}
          # {{multiple}}

        #--------------------------- top_5_donors_for_party

          # Top {{n}} Donors for {{parties}}
          # {{block}}

        #--------------------------- last_5_donations_for_party

          # Last {{n}} Donations for {{party}}
          # {{block}}

        #--------------------------- top_5_donors_for_parties

          # Top {{n}} Donors for {{parties}}
          # {{block}}

        #--------------------------- total_donations_for_parties

          # Total Donations for {{parties}}
          # {{block}}

        #--------------------------- last_5_donations_for_donor

          # Last {{n}} Donations for {{donor}}
          # {{block}}

        #--------------------------- top_5_parties_donated_to

          # Top {{n}} Parties Donated to by {{donor}}
          # {{block}}

        #--------------------------- total_donations_for_each_donor

          # Total Donations for {{donors}}
          # {{block}}

        #--------------------------- donors_donations_sorted_by_amount

          # Top Donations by {{donors}} to {{parties}}
          # {{block}}

        #--------------------------- parties_donations_sorted_by_amount

          # Top Donations to {{parties}} by {{donors}}
          # {{block}}

        #---------------------------

    end
end
