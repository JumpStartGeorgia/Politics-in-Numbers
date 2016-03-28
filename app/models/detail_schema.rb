class DetailSchema

  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :detail

  field :title, type: String
  field :order, type: Integer
  field :actual_order, type: Integer
  
end
