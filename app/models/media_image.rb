# MediaImage class - paperclip attachment
class MediaImage
  include Mongoid::Document
  include Mongoid::Paperclip

  embedded_in :medium
  field :locale, type: Symbol

  has_mongoid_attached_file :image,
    :path => ':rails_root/public/system/:class/:attachment/:id/:style.:extension',
    :url => '/system/:class/:attachment/:id/:style.:extension',
    :styles => { :small => "200x", :medium => "700x", :large => "1200x" },
    :convert_options => {:small => '-quality 85', :medium => '-quality 85', :large => '-quality 85' }

  validates_attachment :image, presence: true, content_type: { content_type: %w(image/jpeg image/jpg image/png image/gif) }, size: { in: 0..5.megabytes }

end
