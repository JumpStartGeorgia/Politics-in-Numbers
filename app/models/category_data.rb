# Trace party categories and sub categories data
# It is embed in Dataset class, meta data is taken from Category class
class CategoryData
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :dataset

  #field :type, type: Integer
  field :value, type: Float
  field :category_id, type: BSON::ObjectId
  validates_presence_of :value, :category_id
  SYMS = [ :income, :income_campaign, :expenses, :expenses_campaign, :reform_expenses, :property_assets, :financial_assets, :debts ]

  def category
    @category = Category.find(category_id)

  end

  def category_name
    @category = category if @category.nil?
    if @category.present?
      @category.title
    else
      I18n.t("shared.common.unknown")
    end
  end

    def self.filter(params)
    #Rails.logger.debug("****************************************#{params}")

    result = []
    options = []
    matches = []
    conditions = []

    # matches.push({ "_id": { "$in": params[:donor_ids].map{|m| BSON::ObjectId(m)} } }) if params[:donor_ids].present?
    # matches.push({ "multiple": { "$eq": params[:multiple] } }) if params[:multiple] == true

    # if params[:parties].present?
    #   tmp = params[:parties].map{|m| BSON::ObjectId(m) }
    #   matches.push({ "donations.party_id": { "$in": tmp } })
    #   ors = []
    #   tmp.each{|e| ors.push({ "$eq": ["$$donation.party_id", e ] }) }
    #   conditions.push({ "$or": ors });
    # end

    # tmp = params[:period][0]
    # if tmp.present? && tmp != -1
    #   matches.push({ "donations.give_date": { "$gte": tmp } })
    #   conditions.push({"$gte": [ "$$donation.give_date", tmp ]})
    # end

    # tmp = params[:period][1]
    # if tmp.present? && tmp != -1
    #   matches.push({ "donations.give_date": { "$lte": tmp } })
    #   conditions.push({"$lte": [ "$$donation.give_date", tmp ]})
    # end

    # tmp = params[:amount][0]
    # if tmp.present? && tmp != -1
    #   matches.push({ "donations.amount": { "$gte": tmp } })
    #   conditions.push({"$gte": [ "$$donation.amount", tmp ]})
    # end

    # tmp = params[:amount][1]
    # if tmp.present? && tmp != -1
    #   matches.push({ "donations.amount": { "$lte": tmp } })
    #   conditions.push({"$lte": [ "$$donation.amount", tmp ]})
    # end

    # tmp = params[:monetary]
    # if tmp.present? && tmp == true || tmp == false
    #   matches.push({ "donations.monetary": { "$eq": tmp } })
    #   conditions.push({"$eq": [ "$$donation.monetary", tmp ]})
    # end

    # options.push({ "$match": { "$and": matches } }) if !matches.blank?

    # #if !conditions.blank?
    #   options.push({
    #     "$project": {
    #       name: { "$concat": ["$first_name", " ", "$last_name"] },
    #       tin: 1,
    #       nature: 1,
    #       donated_amount: 1,
    #       donations: {
    #         "$filter": {
    #           input: "$donations",
    #           as: "donation",
    #           cond: { "$and": conditions }
    #         }

    #       }
    #     }
    #    })
    # #end
    # options.push({ "$sort": { donated_amount: -1, name: 1 } })
    # #if !matches.blank? || !conditions.blank?
    #   Rails.logger.debug("-------------------------------------aggregate options-------#{options}")
    #   result = collection.aggregate(options)
    #end
    result = { test: "here" }
  end
  def self.explore(params)
    limiter = 5
    Rails.logger.debug("--------------------------------------------#{params}")

    f = {
      parties: nil,
      period: [-1,-1]
    }

    tmp = params[:party]
    f[:parties] = tmp if tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 }

    tmp = params[:period]
    f[:period] = tmp.map{|t| Time.at(t.to_i/1000) } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }

    #{ category: Category.tree(false) }
    SYMS.each { |e|
      tmp = params[e]
      f[e] = tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 } ? tmp : nil
    }

    data = filter(f).to_a
    # Rails.logger.debug("-----------------------------------------return size---#{data.size}")
    # # TODO refactor code to remove ambitious code
    # chart1 = []
    # chart2 = []
    # table = []
    # total_amount = 0
    # total_donations = 0
    # monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
    # nature_values = [I18n.t("mongoid.attributes.donor.nature_values.private"), I18n.t("mongoid.attributes.donor.nature_values.organization")]
    # parties = {}
    # Party.each{|e| parties[e.id] = { value: 0, name: e.title } }

    # chart_meta = [
    #   ["top_5_donors", "top_5_parties"],
    #   ["top_5_donors_for_party", "last_5_donations_for_party"],
    #   ["top_5_donors_for_parties", "total_donations_for_parties"],
    #   ["last_5_donations_for_donor", "top_5_parties_donated_to"],
    #   ["total_donations_for_each_donor", "top_5_parties_donated_to"],
    #   ["donors_donations_sorted_by_amount", "parties_donations_sorted_by_amount"]
    # ]
    # chart_meta_obj = { n: limiter, obj: nil, objb: nil }

    # ds = f[:donor_ids].nil? ? 0 : f[:donor_ids].length
    # ps = f[:parties].nil? ? 0 : f[:parties].length

    # # ds == 0 && ps == 0
    # # ds == 0 && ps == 1
    # # ds == 0 && ps > 1
    # # ds == 1 && ps == 0
    # # ds > 1 && ps == 0
    # # ds >= 1 && ps >= 1

    # chart_type = ds == 0 ? ( ps == 0 ? 0 : ( ps == 1 ? 1 : 2) ) : ( ps == 0 ? ( ds == 1 ? 3 : 4) : 5 )

    # recent_donations = []
    # parties_list = {}

    # data.each{|e|
    #   e[:partial_donated_amount] = 0

    #   e[:donations].each { |ee|

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
    #   }
    # }

    # if chart_type == 0 # If select anything other than party and donor -> charts show the top 5

    #   chart1 = data.take(limiter).map{|m| [m[:name], m[:donated_amount]] }
    #   chart2 = parties.sort_by { |k, v| -1*v[:value] }.take(limiter).map{|k,v| [v[:name], v[:value]] }

    # elsif chart_type == 1 # If select 1 party -> top 5 donors for party, last 5 donations for party
    #   chart_meta_obj[:obj] = parties[BSON::ObjectId(f[:parties][0])][:name]
    #   chart1 = data.sort{ |x,y| y[:partial_donated_amount] <=> x[:partial_donated_amount] }.take(limiter).map{|m| [m[:name], m[:partial_donated_amount]] }
    #   chart2 = recent_donations.sort{ |x,y| y[:date] <=> x[:date] }.take(limiter).map{|m| m[:out] }

    # elsif chart_type == 2 || chart_type == 4 # If select > 1 party -> top 5 donors for parties, total donations for selected parties
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

    # end

    {
      data: data
    #   chart1: chart1,
    #   chart1_title: I18n.t("shared.chart.title.#{chart_meta[chart_type][0]}", chart_meta_obj),
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

# If one category > page 1 of design
# If multiple categories selected > page 3 of design


#     Party - Donations for:
# Category - Grouped by:
# Grouped by: Income - Donated Monetary
# Group by: Property Asset - Vehicles
# Time period annual - In:
# Time period campaign - During:


  end
end
