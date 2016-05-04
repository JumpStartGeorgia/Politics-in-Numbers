class AdminController < ApplicationController
  before_filter :authenticate_user!
  layout "admin"
  # before_filter do |controller_instance|
  #   controller_instance.send(:valid_role?, @site_admin_role)
  # end

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @pages }
    end
  end

  def category
    # @virtual = Category.tree(true)
    # @non_virtual = Category.tree(false)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def permalink
    value = params[:value]
    locale = params[:locale]
    locales = I18n.available_locales
    perm = nil
    #object = params[:object].present?
    if value.present? && locale.present? && locales.include?(locale.to_sym)
      begin
        orig_locale = I18n.locale
        I18n.locale = locale
        perm = Mongoid::Slug::UniqueSlug.new(Party.new).find_unique(value) if value.present?
      ensure
        I18n.locale = orig_locale
      end
    end
    render json: { permalink: perm }
  end

end
