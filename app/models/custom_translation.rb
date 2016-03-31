# CustomTranslation class - used as parent class to extend translation
# #ability for classes that use localize feature
class CustomTranslation
  require 'active_model'
  include Mongoid::Interceptable

  # By default mongoid uses I18n.locale or I18n.default_locale
  # to determine which locale to use to get the localized field info.
  # This does not work when we are letting users define
  # which locale their data is in.

  # So this class provides a method 'get_translation' that has a param
  # to indicate which locale to get data for.

  # In the model classes that inherit from this class, you have to override
  # the GET method for each field that is translated and have it call
  # the 'get_translation' method. For example:
  # def title
  #   get_translation(self.title_translations)
  # end

  # ###########################################
  # # if the object has translations but is an embeded document,
  # it should not be using callbacks
  # # so set this to false if you do not want callbacks working
  # def initialize(options={use_callbacks: true})
  #   @use_callbacks = use_callbacks
  #   puts "--> initialize, use_callbacks = #{use_callbacks}"
  # end

  ###########################################

  # current_locale: save a reference to the locale that should be used
  #   to get translations for
  # languages: optional variable array to hold list of required locales
  #   that should be overriden with a field in the inheriting class
  # default_language: optional variable to hold default locale
  #   that should be overriden with a field in the inheriting class
  attr_accessor :current_locale, :languages, :default_language

  ###########################################

  # when the record is initialized, set the current_locale
  # to the default language, or the current locale if non-set
  after_initialize :set_current_locale
  after_initialize :set_languages

  # if the current locale is in the list of languages or there is no
  # default language, use current locale, else default to default language
  def set_current_locale
    self.current_locale =
      ((languages.present? && languages.include?(I18n.locale.to_s)) ||
      default_language.blank?) ? I18n.locale.to_s : default_language
  end

  # if this is a new record and languages does not exist,
  #  initialize it to the current locale
  def set_languages
    self.languages = [I18n.locale.to_s] if languages.blank?
    self.default_language = I18n.locale.to_s if default_language.blank?
  end

  ###########################################

  # get the translation for the provided object and locale
  # - object: reference to the mongoid field that has translations
  #   (e.g., self.title_translations)
  # - locale: what locale to get translation for; defaults to
  #   self.current_locale
  # - fallback_locale: indicates which fallback locale should be used
  #  in case the locale param does not have a translation value
  def get_translation(object, locale = current_locale,
                      fallback_locale = default_language)
    fallback_locale ||= I18n.default_locale

    orig_locale = I18n.locale
    I18n.locale = locale.to_sym

    text = object[I18n.locale.to_s]
    text = object[fallback_locale.to_s] if text.blank?

    I18n.locale = orig_locale

    text
  end

  # get the languages sorted with default first
  def languages_sorted
    langs = languages.dup
    if default_language.present?
      langs.rotate!(langs.index(default_language))
    end
    langs
  end

  # return array of language objects for each locale in languages
  def language_objects
    langs = []

    if languages.present?
      languages_sorted.each do |locale|
        l = Language.where(locale: locale).to_a
        langs << l.first if l.present?
      end
    end

    langs
  end

  # strip the string and fix any bad characters
  # some text is in microsoft ansi encoding and needs to be fixed
  # reference: https://msdn.microsoft.com/en-us/library/cc195054.aspx
  def clean_string(str)
    if str.class == String && str.present?
      clean_text(str)
    else
      str
    end
  end

  # strip the string and fix any bad characters
  # some text is in microsoft ansi encoding and needs to be fixed
  # reference: https://msdn.microsoft.com/en-us/library/cc195054.aspx
  # - <91> = ‘, <92> = ’, <93> = “, <94> = ”, <96> = —, <97> = —
  # - \xa0 = space, \x85 = ...
  # if string = '' or '\\N' return nil
  def clean_text(str, options = {})
    options[:format_code] = false if options[:format_code].nil?
    single_quote = "'"
    double_quote = '"'
    dash = "-"
    space = " "
    ellipsis = "..."

    if !str.nil? && str.length > 0
      x = str.dup.encode('UTF-8', 'binary', invalid: :replace, undef: :replace,
       replace: '')

      if options[:format_code] == true
        x.gsub!('.', '|')
        x.downcase!
      end

      y = x.gsub("<91>", single_quote).gsub("\\x91", single_quote).gsub("‘", single_quote)
          .gsub("<92>", single_quote).gsub("\\x92", single_quote).gsub("’", single_quote)
          .gsub("<93>", double_quote).gsub("\\x93", double_quote).gsub("“", double_quote)
          .gsub("<94>", double_quote).gsub("\\x94", double_quote).gsub("”", double_quote)
          .gsub("<96>", dash).gsub("\\x96", dash)
          .gsub("<97>", dash).gsub("\\x97", dash)
          .gsub("\\x85", ellipsis)
          .gsub("\\xa0", space).chomp.strip

      y = nil if y.empty? || y == "\\N"
      return y
    else
      return str
    end
  end

  def clean_string_for_uploads(str)
    if str.class == String && str.present?

      x = str.dup.chomp.strip
      replacements = [
        ["'", ["<91>", "\\x91", "‘", "<92>", "\\x92", "’"]],
        ['"', ["<93>", "\\x93", "“", "<94>", "\\x94", "”"]],
        ['-', ["<96>", "\\x96", "<97>", "\\x97"]],
        ["...", ["\\x85"]],
        [" ", ["\\xa0"]]
      ]
      replacements.each do |r|
        with = r[0]
        r[1].each { |what| x.gsub!(what, with) }
      end

      x = nil if x.empty? || x == "\\N"
      return x
    else
      return str
    end
  end
end
