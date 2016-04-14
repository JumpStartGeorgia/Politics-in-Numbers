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

end
