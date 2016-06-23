# Donor class - donation data for parties by give date
class Donor
  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :donations

  field :first_name, type: String
  field :last_name, type: String
  field :tin, type: String

  validates_presence_of :first_name, :last_name, :tin

  scope :by_donors, -> v { where(:id.in => v) if v.present? }
  scope :by_party, -> v { where("donations.party_id" => { "$in": v}) if v.present? }
  scope :by_tin, -> v { where("donations.tin" => v) }
  scope :from_date, -> v { where("donations.give_date" => { "$gte":  v}) if v.present? && v != -1 }
  scope :to_date, -> v { where("donations.give_date" => { "$lte":  v}) if v.present? && v != -1 }
  scope :from_amount, -> v { where("donations.amount" => { "$gte":  v}) if v.present? && v != -1 }
  scope :to_amount, -> v { where("donations.amount" => { "$lte":  v}) if v.present? && v != -1 }
  scope :where_monetary, -> v { where("donations.monetary" => v) if v == true || v == false }
  scope :only_multiple_donations, -> v { where("donations.1" => { "$exists" => true }) if v == true }
  # d.collection.aggregate([{ "$project": { "name": {"$concat": ["$first_name","-","$last_name"] } }}]).first
  #scope :pair_by_donors, -> v { where(:id.in => v).aggregate([{ "$project": { "name": {"$concat": ["$first_name","-","$last_name"] } }}]) if v.present? }
   # d.collection.aggregate([ { "$match": { tin: "17001006279"}}, { "$project": { "name": {"$concat": ["$first_name","-","$last_name"] } }}])

  def amount
    donations.sum(:amount)
  end

  def self.sorted
    order_by([[:first_name, :asc], [:last_name, :asc]])
  end


  def self.pair_by_donors(ids) #id name
    res = {}
    collection.aggregate([ { "$match": { "_id": { "$in": ids } } }, { "$project": { "name": {"$concat": ["$first_name"," ","$last_name"] } }}]).each{|d|
      res[d[:_id].to_s] = d[:name]
    }
    res
  end

  def self.explore(params)
    donor_ids = parties = monetary = multiple = nil
    period = [-1,-1]
    amount = [-1,-1]

    tmp = params[:donor]
    donor_ids = tmp if tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 }

    tmp = params[:period]
    period = tmp.map{|t| Time.at(t.to_i/1000) } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }

    tmp = params[:amount]
    amount = tmp.map{|t| t.to_i } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.to_i.to_s == t }

    tmp = params[:party]
    parties = tmp if tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 }

    tmp = params[:monetary]
    monetary = tmp == "yes" if tmp == "yes" || tmp == "no"

    multiple = true if params[:multiple] == "yes"

    donors = Donor
            .by_donors(donor_ids)
            .by_party(parties)
            .from_date(period[0])
            .to_date(period[1])
            .from_amount(amount[0])
            .to_amount(amount[1])
            .where_monetary(monetary)
            .only_multiple_donations(multiple)

    # *TODO* donor should now about amount for all donations
    # donors.order_by(amount: 'desc')
    # sort_by {|v|
    #    v.amount
    #  }
    donor_pairs = donor_ids.present? ? Donor.pair_by_donors(donor_ids.map{|m| BSON::ObjectId(m) }) : []
    #Rails.logger.debug("------------------------------------#{donor_ids}-------->#{@donor_pairs}<")
    # require 'digest'
    # Rails.logger.debug("-------------------------------------------->#{["d",donor_ids,period,amount,parties,monetary,multiple].join(";")}<")
    # { data: donors, id: Digest::MD5.hexdigest(["d",donor_ids,period,amount,parties,monetary,multiple].join(";"))}

    parties = {}
    Party.each{|e| parties[e.id] = 0}

    Donor.each{|e|
      e.donations.each { |ee|
        parties[ee.party_id] += ee.amount
      }
    }

    parties.sort_by { |k, v| v }

    { data: donors, donor_info: donor_pairs,  }
    #res = Donor.sorted_by_amount.limit(5).map{|m| { value: m.amount, name: "#{m.first_name} #{m.last_name}" } }
    # res
    #     What happens when filters are selected (table always show full results):
# If select anything other than party and donor -> charts show the top 5
# If select 1 party -> top 5 donors for party, last 5 donations for party
# If select > 1 party -> top 5 donors for parties, total donations for selected parties
# If select 1 donor-> last 5 donations for donor, top 5 parties donated to
# If select > 1 donor-> total donations for each donor, top 5 parties donated to

#     # "donation"=>{"donor"=>["574d9379fbb6bd0313000007", "574d9379fbb6bd0313000014"],
    #  "period"=>["1464724800000", "1464897600000"],
    #   "amount"=>["100", "500"],
    #    "party"=>["5748093cfbb6bd3781000016", "5748093cfbb6bd3781000027"],
    #     "type"=>"monetary",
    #      "multiple"=>"yes"},
    #       "locale"=>"en"}
  end
  # def self.validate_params(params)

  # end

  # def top(params)
  # end

end
