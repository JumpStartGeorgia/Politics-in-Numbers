# Donor class - donation data for parties by give date
class Donor
  include Mongoid::Document
  include Mongoid::Timestamps

  #embeds_many :terminators
  embedded_in :donorset

  field :first_name, type: String
  field :last_name, type: String
  field :tin, type: String
  field :amount, type: Float
  field :party_id, type: BSON::ObjectId
  field :give_date, type: Date
  field :comment, type: String

  validates_presence_of :first_name, :last_name, :tin, :amount, :party_id, :give_date

  def self.sorted
    order_by([[:give_date, :desc], [:first_name, :asc], [:last_name, :asc]])
  end
end
