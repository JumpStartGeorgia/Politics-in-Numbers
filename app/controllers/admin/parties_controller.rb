class Admin::PartiesController < ApplicationController
  # before_filter :authenticate_user!
  # before_filter do |controller_instance|
  #   controller_instance.send(:valid_role?, @site_admin_role)
  # end

  # GET /parties
  # GET /parties.json
  def index
    @items = Party.sorted

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @items }
    end
  end

  # GET /parties/1
  # GET /parties/1.json
  def show
    @item = Party.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end
  end

  # GET /parties/new
  # GET /parties/new.json
  def new
    @item = Party.new

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # GET /parties/1/edit
  def edit
    @item = Party.find(params[:id])

    set_tabbed_translation_form_settings
  end

  # POST /parties
  # POST /parties.json
  def create
    @item = Party.new(params[:party])

    respond_to do |format|
      if @item.save
        format.html { redirect_to admin_parties_path, flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.party.one'))} }
        format.json { render json: @item, status: :created, location: @item }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /parties/1
  # PUT /parties/1.json
  def update
    @item = Party.find(params[:id])

    respond_to do |format|
      if @item.update_attributes(params[:party])
        format.html { redirect_to admin_parties_path, flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.party.one'))} }
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "edit" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parties/1
  # DELETE /parties/1.json
  def destroy
    @item = Party.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_parties_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.party.one'))} }
      format.json { head :no_content }
    end
  end
end
