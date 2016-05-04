# MediaImage class - paperclip attachment
class MediaImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  embedded_in :MediaImages
  field :locale, type: Symbol

  has_mongoid_attached_file :image,
    :path => ':rails_root/public/system/:class/:attachment/:id/:style.:extension',
    :styles => { :small => "200x200>", :medium => "600x315>", :large => "1200x630>" }

  validates_attachment :image, presence: true, content_type: { content_type: %w(image/jpeg image/jpg image/png) }, size: { in: 0..25.megabytes }

end
