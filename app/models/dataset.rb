# Dataset - trace category and detail data for party
# based on specific period
class Dataset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip


  STATES = [:pending, :processed, :discontinued]  # 0 pending 1 processed 2 discontinued
  SYMS = [ :income, :income_campaign, :expenses, :expenses_campaign, :reform_expenses, :property_assets, :financial_assets, :debts ]

  embeds_many :category_datas
  embeds_many :detail_datas

  field :party_id, type: BSON::ObjectId
  field :period_id, type: BSON::ObjectId
  field :state, type: Integer, default: 0
  field :del, type: Boolean, default: false

  default_scope ->{ where(del: false) }

  has_mongoid_attached_file :source,
    :path => ':rails_root/public/system/:class/:attachment/:id/:style.:extension',
    :url => '/system/:class/:attachment/:id/:style.:extension'


  validates_presence_of :party_id, :period_id
  validates_attachment :source, presence: true, content_type: { content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }, size: { in: 0..25.megabytes }
  validates_inclusion_of :state, in: [0, 1, 2]

  def self.sorted
    order_by([[:created_at, :desc]])
  end

  def party
    @party = Party.find(party_id)
  end

  def period
    @period = Period.find(period_id)
  end

  def party_name
    @party = party if @party.nil?
    @party.title
  end

  def period_name
    @period = period if @period.nil?
    @period.title
  end

  def current_state
    I18n.t("mongoid.options.dataset.state.#{STATES[state].to_s}")
  end

  def current_state_sym
    STATES[state].to_s
  end

  def set_state(st)
    st = STATES.index(st.to_sym)
    if st.present?
      self.state = st
      self.save
    end
  end

  def self.has_state(st)
    begin
      st.to_i < STATES.length
    rescue
      false
    end
  end

  def is_state(st)
    self.state == STATES.index(st)
  end

  def self.by_period(per_id)
    where({period_id: per_id})
  end
  def self.filter(params)
    Rails.logger.debug("***filter*************************************#{params}")

    result = []
    options = []
    matches = []
    conditions = []

    matches.push({ "party_id": { "$in": params[:parties].map{|m| BSON::ObjectId(m)} } }) if params[:parties].present?
    matches.push({ "period_id": { "$in": params[:period].map{|m| BSON::ObjectId(m)} } }) if params[:period].present?

    SYMS.each { |e|
      if params[e].present?
        tmp = params[e].map{|m| BSON::ObjectId(m) }
        matches.push({ "category_datas.category_id": { "$in": tmp } })
        ors = []
        tmp.each{|e| ors.push({ "$eq": ["$$category_datas.category_id", e ] }) }
        conditions.push({ "$or": ors });
      end
    }

    options.push({ "$match": { "$and": matches } }) if !matches.blank?

    #if !conditions.blank?
      options.push({
        "$project": {
          party_id: 1,
          period_id: 1,
          # name: { "$concat": ["$first_name", " ", "$last_name"] },
          # tin: 1,
          # nature: 1,
          # donated_amount: 1,
          category_datas: {
            "$filter": {
              input: "$category_datas",
              as: "category_datas",
              cond: { "$and": conditions }
            }

          }
        }
       })
      # If one category > page 1 of design
    # If multiple categories selected > page 3 of design
    #end
    #options.push({ "$sort": { donated_amount: -1, name: 1 } })
    # #if !matches.blank? || !conditions.blank?
    #   Rails.logger.debug("-------------------------------------aggregate options-------#{options}")
      result = collection.aggregate(options)
    #end
    result
  end
  def self.explore(params)
    limiter = 5
    Rails.logger.debug("--------------------------------------------#{params}")

    f = {
      parties: nil,
      period: nil
    }

    tmp = params[:party]
    f[:parties] = tmp if tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 }

    tmp = params[:period]
    f[:period] = tmp if tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 }

    #{ category: Category.tree(false) }
    ln = 0
    SYMS.each { |e|
      tmp = params[e]
      f[e] = tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 } ? tmp : nil
      ln += f[e].size if f[e].present?
    }


    data = filter(f).to_a
    #Rails.logger.debug("-----------------------------------------return size---#{data.size}")
    chart1 = []
    # table = []
    # total_amount = 0
    # total_donations = 0
    # monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
    # nature_values = [I18n.t("mongoid.attributes.donor.nature_values.private"), I18n.t("mongoid.attributes.donor.nature_values.organization")]
    parties = {}
    periods = {}
    categories = {}
    Party.each{|e| parties[e.id] = { value: 0, name: e.title } }
    Period.each{|e| periods[e.id] = { name: e.title, date: e.start_date, type: e.type } }
    Category.each{|e| categories[e.id.to_s] = { title: e.title, parent_id: e.parent_id.to_s } }

    cs = ln
    ps = f[:parties].nil? ? 0 : f[:parties].length


    chart_type = cs == 1 ? 0 : 1

    # recent_donations = []
    parties_list = {}
    period_list = {}
    chart1 = []
    chart1_categories = []

    data.each{|e|
    #   e[:partial_donated_amount] = 0
      if !period_list[e[:period_id]].present?
        per = periods[e[:period_id]]
        period_list[e[:period_id]] = { id: e[:period_id], name: per[:name], date: per[:date], type: per[:type]  }
      end

      if !parties_list[e[:party_id]].present?
        parties_list[e[:party_id]] = { name: parties[e[:party_id]][:name], data: [] }
      end


      #e[:category_datas].each { |ee|
        #Rails.logger.debug("2================#{parties_list}=====================#{e[:party_id]} #{[e[:period_id]}")
        #parties_list[e[:party_id]][:data][e[:period_id]] = ee[:value]
    #     parties[ee[:party_id]][:value] += ee[:amount] if chart_type == 0


    #     if chart_type == 2 || chart_type == 3 || chart_type == 4 || chart_type == 5
    #       if !parties_list[ee[:party_id]].present?
    #         parties_list[ee[:party_id]] = { value: 0, name: parties[ee[:party_id]][:name] }
    #       end
    #       parties_list[ee[:party_id]][:value] += ee[:amount]
    #     end

    #     recent_donations.push({ date: ee[:give_date], out: [e[:name], ee[:amount]] }) if chart_type == 1
    #     recent_donations.push({ date: ee[:give_date], out: [parties[ee[:party_id]][:name], ee[:amount]] }) if chart_type == 3

    #     e[:partial_donated_amount] += ee[:amount]
    #     total_amount += ee[:amount]
    #     total_donations += 1
    #     table.push(["#{ee[:_id]}", e[:name], nature_values[e[:nature]], I18n.l(ee[:give_date]), ee[:amount], parties[ee[:party_id]][:name], monetary_values[ee[:monetary] ? 0 : 1] ])
      # }
    }
    tmp = []
    period_list.each{|k,v| tmp.push({ id: v[:id], name: v[:name], date: v[:date], type: v[:type] }) }
    period_list = tmp
    tmp.sort!{ |x,y| y[:date] <=> x[:date] }

     #Rails.logger.debug("--------------------------------------------#{period_list.length}")
    parties_list.each{|k,v| parties_list[k][:data] = Array.new(period_list.size, 0) }

    data.each{|e|

      pp = period_list.index{ |s| s[:id] == e[:period_id] }
      e[:category_datas].each { |ee|
       #Rails.logger.debug("3==================#{period_list}===================#{parties_list[e[:party_id]][:data]} #{pp}")
         #Rails.logger.debug("--------------------------------------------#{parties_list[e[:party_id]][:data][pp]}") if parties_list[e[:party_id]][:data][pp].present?
        parties_list[e[:party_id]][:data][pp] = ee[:value]
      }
    }

    chart_title = ""
    chart_title += "#{I18n.t('shared.chart.finance.title.party_donations_for')}: #{f[:parties].map{|m| parties[BSON::ObjectId(m)][:name] }.join(', ')}<br/>" if f[:parties].present?

    if ln >= 1
      chart_title += I18n.t("shared.chart.finance.title.#{ln == 1 ? 'category' : 'category_grouped_by'}")+": "
      SYMS.each { |e|
        if f[e].present?
          chart_title += Category.full_names(categories, f[e]).join(',<br/>')
        end
      }
    end

    if f[:period].present?
      period_first = periods[BSON::ObjectId(f[:period][0])]
      chart_title += I18n.t("shared.chart.finance.title.time_period_#{Period::TYPES[period_first[:type]] == :annual ? 'annual' : 'campaign'}")+": "
      chart_title += f[:period].map{|m| periods[BSON::ObjectId(m)][:name] }.join(",<br/>")
    end


    if chart_type == 0 # If select anything other than party and donor -> charts show the top 5

      chart1 = parties_list.map{|k,v| { name: v[:name], data: v[:data] } }
      period_list.each{|e| chart1_categories << e[:name] }
    # elsif chart_type == 1 # If select 1 party -> top 5 donors for party, last 5 donations for party
    #   chart_meta_obj[:obj] = parties[BSON::ObjectId(f[:parties][0])][:name]
    #   chart1 = data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }.take(limiter).map{|m| [m[:name], m[:partial_donated_amount]] }
    #   chart2 = recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.take(limiter).map{|m| m[:out] }

    elsif chart_type == 2
    #   # If select > 1 donor-> total donations for each donor, top 5 parties donated to

    #   chart1 = data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }.take(limiter).map{|m| [m[:name], m[:partial_donated_amount]] }
    #   chart2 = parties_list.map{|k,v| v }.sort{ |x,y| y[:name] <=> x[:name] }.take(limiter).map{|m| [m[:name], m[:value]] }

    #   chart_meta_obj[:obj] = chart1.map{|m| m[0] }.join(", ") if chart_type == 4

    # elsif chart_type == 3 # If select 1 donor-> last 5 donations for donor, top 5 parties donated to
    #   chart1 = recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.take(limiter).map{|m| m[:out] }
    #   chart2 = parties_list.map{|k,v| v }.sort{ |x,y| y[:name] <=> x[:name] }.take(limiter).map{|m| [m[:name], m[:value]] }

    #   chart_meta_obj[:obj] = chart1.map{|m| m[0] }.join(", ")

    # elsif chart_type == 5 # show selected donors sorted by who donated most and show selected parties sorted by who received most

    #   chart1 = data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }.map{|m| [m[:name], m[:partial_donated_amount]] }
    #   chart2 = parties_list.map{|k,v| v }.sort{ |x,y| y[:value] <=> x[:value] }.map{|m| [m[:name], m[:value]] }
    #   chart_meta_obj[:obj] = chart1.map{|m| m[0] }.join(", ")
    #   chart_meta_obj[:objb] = chart2.map{|m| m[0] }.join(", ")

    end

    {
      data: nil,#data,
      chart1: {
        categories: chart1_categories,
        series: chart1,
        title: chart_title
      }
      # parties_list: parties_list,
      # period_list: period_list
    #   chart1: chart1,
    #   chart2: chart2,
    #   chart2_title: I18n.t("shared.chart.title.#{chart_meta[chart_type][1]}", chart_meta_obj),
    #   table: {
    #     data: table,
    #     header: [human_attribute_name(:id), human_attribute_name(:name),
    #       human_attribute_name(:nature), human_attribute_name(:give_date),
    #       Donation.human_attribute_name(:amount), Donation.human_attribute_name(:party),
    #       Donation.human_attribute_name(:monetary)],
    #     classes: ["center", "", "", "center", "right", "", ""],
    #     total_amount: total_amount,
    #     total_donations: total_donations
    #   }
    }






  end
end
