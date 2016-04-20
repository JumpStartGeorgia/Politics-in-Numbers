# Allows authorization of certain actions based on user role
class Role
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :users

  field :name, type: String
  validates_presence_of :name
end
