# General helpers for application views
module ApplicationHelper
  def page_title(page_title)
    content_for(:page_title) { page_title.html_safe }
  end
  def title(page_title)
    content_for(:title) { page_title.html_safe }
  end
    # in the forms, show the default language text in the non-default language tabs
  # type: text, url, etc - whatever is needed to make 'tabbed_translation_form.default_xxx' work
  # IMPORTANT - html_safe must be called on the return value
  def show_default_text(text, type='text')
    text.present? ? "<span class='default-translation-text'> (#{t("shared.common.default_#{type}")}: #{text})</span>" : ""
  end
  def get_slug(obj, locale)
    return obj._slugs_translations[locale].last if obj._slugs_translations.present? && obj._slugs_translations[locale].present?
  end
  def existence_translations(obj, field)
    ls = []
    #locales = I18n.available_locales.map(&:to_s)
    field_locales = obj.send("#{field}_translations").keys.map{|k|"#{k.upcase}"}
    "<div class='available-locales'><span>#{field_locales.join(' | ')}</span></div>"
  end
  def generate_li_list(arr=[], tabindex = 5) # format[[id,value]]
    html = ""
    arr.each{|e|
      html += "<li tabindex='5'><div class='item' data-id='#{e[0]}'>#{e[1]}</div></li>"
    }
    html.html_safe
  end
end
