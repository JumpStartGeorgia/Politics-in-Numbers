# Period class meta information about parties
class Period
  include Mongoid::Document
  include Mongoid::Timestamps

  #has_many :datasets
  TYPES = [:annual, :election]

  field :type, type: Integer
  field :start_date, type: Date
  field :end_date, type: Date
  field :title, type: String, localize: true, default: ->{ "#{start_date.strftime('%d/%m/%Y')} - #{end_date.strftime('%d/%m/%Y')}" }
  field :description, type: String, localize: true

  validate :validate_dates
  validates_presence_of :type, :start_date, :end_date, :title
  validates_inclusion_of :type, in: [0, 1]

  #default_scope ->{ order_by([[:type, :desc], [:title, :asc]]) }

  index({ type: 1, start_date: 1, end_date: 1 }, unique: true)
  # rake db:mongoid:create_indexes

  all.map{|t| [t.id, t.title] }

  def validate_dates
    if self.type == TYPES.index(:annual)
      self.start_date = Date.new(self.start_date.year, 1, 1)
      self.end_date = Date.new(self.start_date.year, 12, 31)
    end
  end

  def period_start
    I18n.l(start_date)
  end

  def period_end
    I18n.l(end_date)
  end

  def current_type
    I18n.t("mongoid.options.period.type.#{TYPES[type].to_s}")
  end

  def self.sorted
    order_by([[:type, :asc],[:title, :asc]])#.limit(3)
  end

  def self.list
    sorted.map{|t| [t.title, t.id]}
  end

  def self.types
    col = {}
    TYPES.each_with_index{|d, i|
      col[I18n.t("mongoid.options.period.type.#{d}")] = i
    }
    col
  end
  def self.type_is(tp)
    TYPES.index(tp.to_sym)
  end
end
