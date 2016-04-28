class Deffered
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  default_scope ->{ where(del: false) }

  TYPES = [:parties_type_correction]

  field :type, type: Integer
  field :user_id, type: BSON::ObjectId
  field :related_ids, type: Array
  field :state, type: Integer, default: 0
  field :del, type: Boolean, default: false
  validates_presence_of :type, :user_id, :related_ids

  def self.type_is(tp)
    TYPES.index(tp.to_sym)
  end

  def current_type
    I18n.t("mongoid.options.users.deffered.type.#{TYPES[type].to_s}")
  end

  def soft_destroy
    self.del = true
    self.save
  end
end
