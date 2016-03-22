# Allows authorization of certain actions based on user role
class Role < ActiveRecord::Base
  has_many :users
end
