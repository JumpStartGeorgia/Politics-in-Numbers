# Entrance to admin page
class AdminController < ApplicationController
  layout 'admin'

  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html
      format.json { render json: @pages }
    end
  end

  def category
    # @virtual = Category.tree(true)
    # @non_virtual = Category.tree(false)
    respond_to do |format|
      format.html
    end
  end

  def permalink
    value = params[:value]
    locale = params[:locale]
    locales = I18n.available_locales
    perm = nil

    if value.present? && locale.present? && locales.include?(locale.to_sym)
      begin
        orig_locale = I18n.locale
        I18n.locale = locale

        if value.present?
          perm = Mongoid::Slug::UniqueSlug.new(Party.new).find_unique(value)
        end
      ensure
        I18n.locale = orig_locale
      end
    end
    render json: { permalink: perm }
  end
end
