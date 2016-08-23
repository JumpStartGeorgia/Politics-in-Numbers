# General helpers for application views
module ApplicationHelper
  def page_title(page_title)
    content_for(:page_title) { page_title.html_safe }
  end

  def current_url
    "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
  end

  def full_url(path)
    "#{request.protocol}#{request.host_with_port}#{path}"
  end

  # apply the strip_tags helper and also convert nbsp to a ' '
  def strip_tags_nbsp(text)
    if text.present?
      strip_tags(text.gsub('&nbsp;', ' '))
    end
  end

  # from http://www.kensodev.com/2012/03/06/better-simple_format-for-rails-3-x-projects/
  # same as simple_format except it does not wrap all text in p tags
  def simple_format_no_tags(text, html_options = {}, options = {})
    text = '' if text.nil?
    text = smart_truncate(text, options[:truncate]) if options[:truncate].present?
    text = sanitize(text) unless options[:sanitize] == false
    text = text.to_str
    text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
#   text.gsub!(/([^\n]\n)(?=[^\n])/, '\1<br />') # 1 newline   -> br
    text.html_safe
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


  # create a header with a line under it that is not the full width of the container
  def underlined_header(text, header="h2", header_class='')
    return "<div class='underlined-header-container'><#{header} class='#{header_class}'>#{text}</#{header}><div class='underlined-header'>&nbsp;</div></div>".html_safe
  end
end
