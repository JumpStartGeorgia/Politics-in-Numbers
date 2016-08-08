class Admin::PageContentsController < AdminController
  authorize_resource
  before_filter do @model = PageContent; end

  rescue_from ActionController::ParameterMissing do |e|
    # You can even render a jbuilder template too!
    if action_name == "create"
      redirect_to new_admin_page_content_path, flash: { error: t('shared.msgs.missing_parameter') }
    else
       render :nothing => true, :status => 400
    end
  end

  # GET /pages
  def index
    @items = @model.all

    respond_to do |format|
      format.html
    end
  end

  # GET /pages/1
  def show
    @item = @model.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  # GET /pages/new
  def new
    @item = @model.new

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /pages/1/edit
  def edit
    @item = @model.find(params[:id])
    set_tabbed_translation_form_settings
  end

  # POST /pages
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to admin_page_content_path(@item), flash: {success:  t('app.msgs.success_created', :obj => t('mongoid.models.page_content.one'))} }
      else
        set_tabbed_translation_form_settings
        format.html { render action: "new" }
      end
    end
  end

  # PUT /pages/1
  def update
    @item = @model.find(params[:id])


    respond_to do |format|
      if @item.update_attributes(_params)
        format.html { redirect_to admin_page_content_path(@item), flash: {success:  t('app.msgs.success_updated', :obj => t('mongoid.models.page_content.one'))} }
      else
        set_tabbed_translation_form_settings
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /pages/1
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_page_contents_url, flash: {success:  t('app.msgs.success_deleted', :obj => t('mongoid.models.page_content.one'))} }
    end
  end
  private
    def _params
      params.require(:page_content).permit(:id, :name, :title, :content)
    end
end
