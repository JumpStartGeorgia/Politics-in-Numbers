# Donorset - trace donors data for party
class Donorset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip


  STATES = [:pending, :processed, :discontinued]  # 0 pending 1 processed 2 discontinued
  before_destroy :destroy_donations
  # has_many :donations

  field :state, type: Integer, default: 0
  field :del, type: Boolean, default: false

  default_scope ->{ where(del: false) }

# Band.unscoped.where(name: "Depeche Mode")
# Band.unscoped do
#   Band.where(name: "Depeche Mode")
# end

  has_mongoid_attached_file :source,
    :path => ':rails_root/public/system/:class/:attachment/:id/:style.:extension',
    :url => '/system/:class/:attachment/:id/:style.:extension'


  validates_attachment :source, presence: true, content_type: { content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }, size: { in: 0..25.megabytes }
  validates_inclusion_of :state, in: [0, 1, 2]

  def self.sorted
    order_by([[:created_at, :desc]])
  end

  def current_state
    I18n.t("mongoid.options.donorset.state.#{STATES[state].to_s}")
  end

  def current_state_sym
    STATES[state].to_s
  end

  def set_state(st)
    st = STATES.index(st.to_sym)
    self.set(state: st) if st.present?
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

  def donations
    lang = I18n.locale
    options = []
    matches = []
    conditions = []

    tmp = self.id
    matches.push({ "donations.donorset_id": { "$eq": tmp } })
    conditions.push({"$eq": [ "$$donation.donorset_id", tmp ]})

    options.push({ "$match": { "$and": matches } }) if !matches.blank?
    options.push({
      "$project": {
        first_name: "$first_name.#{lang}",
        last_name: "$last_name.#{lang}",
        tin: 1,
        donations: {
          "$filter": {
            input: "$donations",
            as: "donation",
            cond: { "$and": conditions }
          }
        }
      }
    })
    Donor.collection.aggregate(options).to_a
  end
  def destroy_donations
    Donor.each{|dnr|
      dnr.donations.delete_all({donorset_id: self.id})
      dnr.save
    }
  end

  # def self.dates_range
  #   min = nil
  #   max = nil
  #   Donorset.all.each {|r|
  #     tmp_min = r.donors.min(:give_date)
  #     tmp_max = r.donors.max(:give_date)
  #     if min.nil? || tmp_min < min
  #       min = tmp_min
  #     end
  #     if max.nil? || tmp_max > max
  #       max = tmp_max
  #     end
  #   }
  #   [min, max]
  # end
end
