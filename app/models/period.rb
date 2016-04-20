# Period class meta information about parties
class Period
  include Mongoid::Document
  include Mongoid::Timestamps

  #has_many :datasets
  TYPES = [:annual, :election]

  field :type, type: Integer
  field :start_date, type: Date
  field :end_date, type: Date
  field :title, type: String, localize: true
  field :description, type: String, localize: true

  validates_presence_of :type, :start_date, :end_date, :title
  validates_inclusion_of :type, in: [0, 1]

  index({ type: 1, start_date: 1 }, unique: true)
  # rake db:mongoid:create_indexes

  all.map{|t| [t.id, t.title] }

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
  def self.is_type(tp)
    begin
      tp.to_i < TYPES.length
    rescue
      false
    end
  end
end
