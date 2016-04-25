# Dataset - trace category and detail data for party
# based on specific period
class Dataset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  after_create :before_process_job

  STATES = [:pending, :processed, :discontinued]

  embeds_many :category_datas
  embeds_many :detail_datas
  #belongs_to :party

  field :party_id, type: BSON::ObjectId
  field :period_id, type: BSON::ObjectId
  field :state, type: Integer, default: 0 # 0 pending 1 processed 2 discontinued

  has_mongoid_attached_file :source, :path => ':attachment/:id/:style.:extension'


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

  def before_process_job
    put
    delay_process_dataset
  end

  def process_job

  end
  handle_asynchronously :process_job, :priority => 1

 # def self.states
 #    col = {}
 #    STATES.each_with_index{|d, i|
 #      col[I18n.t("mongoid.options.dataset.type.#{d}")] = i
 #    }
 #    col
 #  end

 #  def self.state_is(tp)
 #    STATES.index(tp.to_sym)
 #  end

 #  def self.is_state(tp)
 #    begin
 #      tp.to_i < STATES.length
 #    rescue
 #      false
 #    end
 #  end

end
