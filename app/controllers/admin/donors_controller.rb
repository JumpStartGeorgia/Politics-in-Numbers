class Admin::DonorsController < ApplicationController
  authorize_resource
  before_filter do @model = Donor; end

  # GET /donors
  # GET /donors.json
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @items }
    end
  end

  # GET /donors/1
  # GET /donors/1.json
  def show
    @item = @model.find(params[:id]).donors

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end
  end

  # GET /donors/new
  # GET /donors/new.json
  def new
    @item = @model.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # GET /donors/1/edit
  def edit
    @item = @model.find(params[:id])

    set_tabbed_translation_form_settings
  end

  # POST /donors
  # POST /donors.json
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        job(:process_donor, @item._id)
        format.html { redirect_to admin_donors_path, flash: {success:  t('shared.msgs.success_created', :obj => t('mongoid.models.donor.one'))} }
        format.json { render json: @item, status: :created, location: @item }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /donors/1
  # PUT /donors/1.json
  def update
    @item = @model.find(params[:id])
    puts "---------------------#{_params.inspect}---------#{@item.inspect}--"
    respond_to do |format|
      if @item.update_attributes(_params)
        puts "good-----------------------------------____#{@item.errors.inspect}_"
        format.html { redirect_to admin_donors_path, flash: {success:  t('shared.msgs.success_updated', :obj => t('mongoid.models.donor.one'))} }
        format.json { head :no_content }
      else
        puts "bad-----------------------------------____#{@item.errors.inspect}_"
        set_tabbed_translation_form_settings

        format.html { render action: "edit" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end


  # DELETE /donors/1
  # DELETE /donors/1.json
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_donors_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.donor.one'))} }
      format.json { head :no_content }
    end
  end

  private
    def _params
      pars = params.clone
      pars.require(:donor).permit(:id, :party_id, :period_id, :source)
    end
end
