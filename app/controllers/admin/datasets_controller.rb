class Admin::DatasetsController < AdminController
  before_filter :authenticate_user!
  authorize_resource
  before_filter do @model = Dataset; end

  rescue_from ActionController::ParameterMissing do |e|
    # You can even render a jbuilder template too!
    if action_name == "create"
      redirect_to new_admin_dataset_path, flash: { error: t('shared.msgs.missing_parameter') }
    else
       render :nothing => true, :status => 400
    end
  end

  # GET /datasets
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html
    end
  end

  # GET /datasets/1
  def show
    @item = @model.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # GET /datasets/new
  def new
    @item = @model.new

    respond_to do |format|
      format.html
    end
  end

  # POST /datasets
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        Job.dataset_file_process(@item._id, current_user._id, [admin_dataset_url(id: "_id")])
        format.html { redirect_to admin_datasets_path, flash: {success:  t('shared.msgs.success_created_with_pending_job', :obj => t('mongoid.models.dataset.one'))} }
      else
        format.html { render action: "new" }
      end
    end
  end

  # DELETE /datasets/1
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_datasets_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.dataset.one'))} }
    end
  end

  private
    def _params
      params.require(:dataset).permit(:id, :party_id, :period_id, :source)
    end
end
