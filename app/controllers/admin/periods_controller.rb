class Admin::PeriodsController < AdminController
  before_filter :authenticate_user!
  authorize_resource
  before_filter do @model = Period; end

  rescue_from ActionController::ParameterMissing do |e|
    # You can even render a jbuilder template too!
    if action_name == "create"
      redirect_to new_admin_period_path, flash: { error: t('shared.msgs.missing_parameter') }
    else
      render :nothing => true, :status => 400
    end
  end

  # GET /periods
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html
    end
  end

  # GET /donors/1
  def show
    @item = @model.find(params[:id])
    @related_datasets = Dataset.by_period(@item.id)

    respond_to do |format|
      format.html
    end
  end

  # GET /periods/new
  def new
    @item = @model.new
    respond_to do |format|
      format.html
    end
  end

  # GET /periods/1/edit
  def edit
    @item = @model.find(params[:id])
    set_tabbed_translation_form_settings
  end

  # POST /periods
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to admin_periods_path, flash: {success:  t('shared.msgs.success_created', :obj => t('mongoid.models.period.one'))} }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /periods/1
  def update
    @item = @model.find(params[:id])
    respond_to do |format|
      if @item.update_attributes(_params)
        format.html { redirect_to admin_periods_path, flash: {success:  t('shared.msgs.success_updated', :obj => t('mongoid.models.party.one'))} }
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "edit" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /periods/1
  def destroy
    @item = @model.find(params[:id])
    @related_datasets = Dataset.by_period(@item.id)
    if !@related_datasets.present?
      @item.destroy
      redirect_to admin_periods_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.period.one'))}
    else
      redirect_to admin_periods_url, flash: {error:  t('shared.msgs.fail_destroyed_existed_relation', :obj => t('mongoid.models.period.one'))}
    end
  end

  private
    def _params
      [:title_translations, :description_translations].each{|f| params[:period][f].delete_if{|k,v| !v.present? } }
      params.require(:period).permit(:type, :start_date, :end_date, title_translations: [:ka, :en, :ru], description_translations: [:ka, :en, :ru])
    end
end
