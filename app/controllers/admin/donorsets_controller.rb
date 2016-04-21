class Admin::DonorsetsController < ApplicationController
  authorize_resource
  before_filter do @model = Donorset; end

  # GET /donorsets
  # GET /donorsets.json
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @items }
    end
  end

  # GET /donorsets/new
  # GET /donorsets/new.json
  def new
    @item = @model.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # POST /donorsets
  # POST /donorsets.json
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        job(:process_donorset, @item._id)
        format.html { redirect_to admin_donorsets_path, flash: {success:  t('shared.msgs.success_created', :obj => t('mongoid.models.donorset.one'))} }
        format.json { render json: @item, status: :created, location: @item }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /donorsets/1
  # DELETE /donorsets/1.json
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_donorsets_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.donorset.one'))} }
      format.json { head :no_content }
    end
  end

  private
    def _params
      pars = params.clone
      pars.require(:donorset).permit(:id, :party_id, :period_id, :source)
    end
end
