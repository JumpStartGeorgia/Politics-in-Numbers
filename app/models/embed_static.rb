# Period class meta information about parties
class EmbedStatic
  include Mongoid::Document
  include Mongoid::Timestamps

  # TYPES = [:static, :dynamic]

  field :sid, type: Integer
  field :sid, type: Integer
  field :data, type: Hash
  field :active, type: Boolean, default: false

  validates_presence_of :type, :data
  # validates_inclusion_of :type, in: [0, 1]

 # def self.types
 #    col = {}
 #    TYPES.each_with_index{|d, i|
 #      col[I18n.t("mongoid.options.embed.type.#{d}")] = i
 #    }
 #    col
 #  end

 #  def self.is_type(tp)
 #    begin
 #      tp.to_i < TYPES.length
 #    rescue
 #      false
 #    end
 #  end

 #  def self.type_is(tp)
 #    TYPES.index(tp.to_sym)
 #  end
end
