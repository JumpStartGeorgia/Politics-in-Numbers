class Admin::DonorsetsController < AdminController
  before_filter :authenticate_user!
  authorize_resource
  before_filter do @model = Donorset; end

  rescue_from ActionController::ParameterMissing do |e|
    # You can even render a jbuilder template too!
    if action_name == "create"
      redirect_to new_admin_donorset_path, flash: { error: t('shared.msgs.missing_parameter') }
    else
       render :nothing => true, :status => 400
    end
  end

  # GET /donorsets
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html
    end
  end

  # GET /donors/1
  def show
    @items = @model.find(params[:id]).donations
    respond_to do |format|
      format.html
    end
  end

  # GET /donorsets/new
  def new
    @item = @model.new

    respond_to do |format|
      format.html
    end
  end

  # POST /donorsets
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        Job.donorset_file_process(@item._id, current_user._id, [admin_donorset_url(id: "_id"), bulk_admin_parties_url(id: "_id")])
        format.html { redirect_to admin_donorsets_path, flash: {success:  t('shared.msgs.success_created_with_pending_job', :obj => t('mongoid.models.donorset.one'))} }
      else
        format.html { render action: "new" }
      end
    end
  end

  # DELETE /donorsets/1
  def destroy
    @item = @model.find(params[:id])

    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_donorsets_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.donorset.one'))} }
    end
  end

  private
    def _params
      params.require(:donorset).permit(:id, :source)
    end
end
