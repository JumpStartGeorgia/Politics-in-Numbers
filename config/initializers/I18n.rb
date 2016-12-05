module I18n
  def self.with_fallback(v)
    r = ""
    if v.class == String
      r = v
    elsif v.class == Hash || v.class == BSON::Document
      I18n.fallbacks[I18n.locale].each{|e|
        if v.key?(e) && v[e].present?
          r = v[e]
          break
        end
      }
    end
    r
  end
end
