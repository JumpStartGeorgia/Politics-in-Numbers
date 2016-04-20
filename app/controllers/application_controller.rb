# The central controller
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  ##############################################
  # Locales #
  before_filter :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
    puts "----#{I18n.locale}"
  end
  # before_action :set_locale
  #private :set_locale

  def default_url_options(options = {})
    { locale: I18n.locale }.merge options
  end

  ##############################################
  # Authorization #

  rescue_from CanCan::AccessDenied do |_exception|
    if user_signed_in?
      not_authorized
    else
      not_found
    end
  end

  # def valid_role?(role)
  #   redirect_to root_path, :notice => t('shared.msgs.not_authorized') if !current_user || !current_user.role?(role)
  # end

  def not_authorized
    puts "-------------------------sdf-"
    redirect_to new_user_session, alert: t('shared.msgs.not_authorized')
  rescue ActionController::RedirectBackError
    redirect_to root_path
  end

  def not_found(redirect_path = root_path)
    Rails.logger.debug('Not found redirect')
    redirect_to redirect_path,
                notice: t('shared.msgs.does_not_exist')
  end

  def set_tabbed_translation_form_settings(tinymce_template='default')
    @languages = Language.sorted
    #@css.push('tabbed_translation_form.css')
    #@js.push('tabbed_translation_form.js')
    #gon.tinymce_options = Hash[TinyMCE::Rails.configuration[tinymce_template].options.map{|(k,v)| [k.to_s,v.class == Array ? v.join(',') : v]}]

    # if tinymce_template != 'default'
    #   @css.push('shCore.css')
    #   @js.push('shCore.js', 'shBrushJScript.js')
    # end
  end

  def d(obj)
    @p << obj
    @p << nil
  end
  def worksheet_to_table(worksheet)
    table = []
    worksheet.each { |row|
      row_data = []
      if row
        row.cells.each { |cell|
          row_data.push(cell && cell.value.present? ? "#{cell.value}#{cell.value.class}" : "empty")
          d(cell.formula.inspect) if cell && cell.value.present? && cell.value == 40731.56
        }
      else
        row_data.push("empty")
      end
      table.push << row_data

    }
    @tables << table
  end
  def get_sheet_id(sheet_name)
    tmp = sheet_name.gsub 'ფორმა', ''
    tmp.gsub! 'N', ''
    tmp.gsub! ' ', ''
    tmp
  end

  def deep_present(parent, tree)
    p = parent
    tree.each {|d|
      p = p[d].present? ? p[d] : nil
      break if p.nil?
    }
    p
  end
  # def log(msg)
  #     Rails.logger.debug("\033[44;37m#{'*'*80}\n    #{DateTime.now.strftime('%d/%m/%Y %H:%M')}#{msg.to_s.rjust(56)}\n#{'*'*80}\033[0;37m")
  # end
end
