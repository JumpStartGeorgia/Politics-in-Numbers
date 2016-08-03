# Party class - meta information about parties
class Medium
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  before_save :image_localization

  embeds_many :media_images, :cascade_callbacks => true

  field :name, type: String, localize: true # media name
  field :title, type: String, localize: true
  field :description, type: String, localize: true # summary
  field :author, type: String, localize: true
  field :embed, type: String, localize: true # embed code
  field :permalink, type: String, localize: true
  field :web, type: String, localize: true # url to story
  field :story_date, type: Date # date the story was published

  field :public, type: Boolean, default: false
  field :published_at, type: Date

  field :read_more, type: Boolean, default: false # if story needs read_more

  field :image, type: BSON::ObjectId, localize: true

  slug :permalink, :title, history: true, localize: true do |d|
    if d.permalink_changed?
      d.permalink.to_url
    elsif d.title_changed?
      d.title.to_url
    else
      d.id.to_s
    end
  end

  def image_localization
    tmp = {}
    self.media_images.each{ |img|
      tmp[img.locale] = img._id
    }
    self.image_translations = tmp
  end

  require 'uri'
  validate :validate_translations
  validates_presence_of :public, :read_more, :story_date
  validates_format_of :web, :with => URI.regexp


  #/^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix

  def validate_translations
    default = I18n.default_locale
    ["name_translations", "title_translations", "author_translations"].each{|f|
      if self.send(f)[default].blank?
        errors.add(:base, I18n.t('mongoid.errors.messages.validations.default_translation_missing',
          field: self.class.human_attribute_name(f),
          lang: Language.name_by_locale(default)))
      end
    }
  end

  def cover(locale=nil)
    if locale.present? && image_translations.has_key?(locale)
      tmp = media_images.find(image_translations[locale])
    elsif image.present?
      tmp = media_images.find(image)
    end
    tmp.present? ? tmp.image : nil
  end

  def human_public
    I18n.t("mongoid.options.media.public.#{public.to_s[0]}")
  end

  def human_read_more
    puts "mongoid.options.media.read_more.#{read_more.to_s[0]}"
    I18n.t("mongoid.options.media.read_more.#{read_more.to_s[0]}")
  end

  # def human_image
  #   image_path
  # end
  def human_published_at
    published_at.present? ? I18n.l(published_at) : nil
  end

  def human_cover
    "<img src='#{cover.url(:small)}'>".html_safe
  end

  # update the embed code to use the proivided sizes
  def human_embed(width=600, height=315)
    embed_code = nil
    if embed.present?
      embed_code = embed.dup
      w_index = embed_code.index('width="')
      if w_index.present?
        end_quote = embed_code.index('"', w_index+7)
        embed_code = embed_code[0..w_index+6] + width.to_s + embed_code[end_quote..-1]
      end
      h_index = embed_code.index('height="')
      if h_index.present?
        end_quote = embed_code.index('"', h_index+8)
        embed_code = embed_code[0..h_index+7] + height.to_s + embed_code[end_quote..-1]
      end
    end

    # add the responsive class
    src_index = embed_code.index('src="')
    if src_index.present?
      embed_code = embed_code[0..src_index-1] + ' class="embed-responsive-item" ' + embed_code[src_index..-1]
    end

    return embed_code
  end

  ## SCOPES

  def self.is_public
    where(public: true)
  end

  def self.sorted_public
    order_by([[:published_at, :desc], [:title, :asc]])
  end

  def self.sorted
    order_by([[:public, :asc], [:published_at, :asc], [:title, :asc]])#.limit(3)
  end
end
