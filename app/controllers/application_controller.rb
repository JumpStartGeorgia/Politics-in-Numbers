# The central controller
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  ##############################################
  # Locales #

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  before_action :set_locale
  private :set_locale

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

  def not_authorized
    redirect_to :back, alert: t('shared.msgs.not_authorized')
  rescue ActionController::RedirectBackError
    redirect_to root_path
  end

  def not_found(redirect_path = root_path)
    Rails.logger.debug('Not found redirect')
    redirect_to redirect_path,
                notice: t('shared.msgs.does_not_exist')
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
    sheet_name.gsub! 'ფორმა', ''
    sheet_name.gsub! 'N', ''
    sheet_name.gsub! ' ', ''
    return sheet_name
  end
end
