# Contains account data
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  belongs_to :role
  # Email already required by devise
  validates :role, presence: true

  def is?(requested_role)
    if role
      role.name == requested_role
    else
      return false
    end
  end

  def manageable_roles
    Role.all.select { |role| Ability.new(self).can? :manage, role }
  end
end
