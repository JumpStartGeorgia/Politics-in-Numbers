# Donor class - donation data for parties by give date
class Donor
  include Mongoid::Document
  include Mongoid::Timestamps

  #embeds_many :terminators
  #embedded_in :donorset
  belongs_to :donorset

  field :first_name, type: String
  field :last_name, type: String
  field :tin, type: String
  field :amount, type: Float
  field :party_id, type: BSON::ObjectId
  field :give_date, type: Date
  field :comment, type: String

  validates_presence_of :first_name, :amount, :party_id, :give_date

  # scope :campaigns, ->{ where(type: type_is(:election)) }

  def self.sorted
    order_by([[:give_date, :desc], [:first_name, :asc], [:last_name, :asc]])
  end
  def self.sorted_by_amount
    order_by([[:amount, :desc], [:give_date, :desc], [:first_name, :asc], [:last_name, :asc]])
  end

  def party
    p = Party.find(party_id)
    p.present? ? p.title : "Unknown"
  end

  def self.explore(params)
    # Rails.logger.debug("--------------------------------------------#{params}")
    tmp = params[:donor]
    @donors = tmp if tmp.present? && tmp.class == Array && tmp.all?{|t| t.size === 24 }
    tmp = params[:period]
    @period = tmp.map{|t| Time.at(t.to_i/1000) } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.size == 13 && t.to_i.to_s == t }
    tmp = params[:amount]
    @amount = tmp.map{|t| t.to_i } if tmp.present? && tmp.class == Array && tmp.size == 2 && tmp.all?{|t| t.to_i.to_s == t }
    tmp = params[:party]

    res = {}
    res = Donor.sorted_by_amount.limit(5).map{|m| { value: m.amount, name: "#{m.first_name} #{m.last_name}" } }
    res
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
  def self.validate_params(params)

  end

  def top(params)
  end

end
