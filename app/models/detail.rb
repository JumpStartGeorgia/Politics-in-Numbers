class Detail

  include Mongoid::Document
  include Mongoid::Timestamps

  embeds_many :detail_schema

  field :code, type: String
  field :name, type: String
  
end
