class Deffered
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user
  # after_create :notify_user
  TYPES = [:parties_type_correction]

  field :type, type: Integer
  field :user_id, type: BSON::ObjectId
  field :related_ids, type: Array
  field :state, type: Integer, default: 0

  validates_presence_of :type, :user_id, :related_ids

  # def set_type(tp)
  #   st = TYPES.index(tp.to_sym)
  #   if st.present?
  #     self.state = st
  #   end
  # end
  # def notify_user
  #   u = User.find(self.user_id)
  #   if u.present?
  #     u.has_defer = true
  #   else
  #     puts "-------------- Raise error, and notify app admin"
  #   end
  # end
  def self.type_is(tp)
    TYPES.index(tp.to_sym)
  end
  def current_type
    I18n.t("mongoid.options.users.deffered.type.#{TYPES[type].to_s}")
  end
end
