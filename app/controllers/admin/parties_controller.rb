# Admin page for managing parties
class Admin::PartiesController < AdminController
  before_filter :authenticate_user!
  authorize_resource
  before_filter { @model = Party; }

  # GET /parties
  # GET /parties.json
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @items }
    end
  end

  # GET /parties/1
  # GET /parties/1.json
  def show
    @item = @model.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @item }
    end
  end

  # GET /parties/new
  # GET /parties/new.json
  def new
    @item = @model.new

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # GET /parties/1/edit
  def edit
    @item = @model.find(params[:id])

    set_tabbed_translation_form_settings
  end

  # POST /parties
  # POST /parties.json
  def create
    @item = @model.new(params[:party])

    respond_to do |format|
      if @item.save
        format.html do
          redirect_to admin_parties_path, flash: {
            success:  t('shared.msgs.success_created',
                        obj: t('mongoid.models.party.one'))
          }
        end
        format.json { render json: @item, status: :created, location: @item }
      else
        set_tabbed_translation_form_settings

        format.html { render action: 'new' }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /parties/1
  # PUT /parties/1.json
  def update
    @item = @model.find(params[:id])
    respond_to do |format|
      if @item.update_attributes(_params)
        format.html do
          redirect_to admin_parties_path, flash: {
            success:  t('shared.msgs.success_updated',
                        obj: t('mongoid.models.party.one'))
          }
        end
        format.json { head :no_content }
      else
        set_tabbed_translation_form_settings

        format.html { render action: 'edit' }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  def bulk
    @deffered = current_user.deffereds.find(params[:id])
    if !@deffered.present?
      redirect_to admin_parties_path, flash: {
        notice: t('mongoid.messages.deffered.not_found') }
    else
      @items = @model.where(:id.in => @deffered.related_ids)
      unless @items.present?
        @deffered.destroy
        redirect_to admin_parties_path, flash: {
          notice: t('mongoid.messages.deffered.no_related_objects') }
      end
    end
  end

  def bulk_update
    @deffered = current_user.deffereds.find(params[:id])
    if !@deffered.present?
      redirect_to admin_parties_path, flash: {
        notice: t('mongoid.messages.deffered.not_found') }
    else
      related_ids = @deffered.related_ids
      has_error = false
      @items = []

      parties = _bulk_params['parties']
      parties.each do |k, v|
        party = @model.find(k)

        if party.present? && related_ids.include?(party._id)
          has_error = true unless party.update(type: v['type'].to_i)
          @items << party
        else
          redirect_to bulk_admin_parties_path(@deffered.id), flash: {
            notice: t('mongoid.messages.deffered.missing_parameter') }
        end
      end

      respond_to do |format|
        if !has_error
          @deffered.soft_destroy
          format.html do
            redirect_to admin_parties_path, flash: {
              success:  t('shared.msgs.success_updated',
                          obj: t('mongoid.models.party.one'))
            }
          end
        else
          format.html do
            render 'bulk', id: @deffered.id, flash: {
              notice:  t('shared.msgs.unexpected_error') }
          end
        end
      end
    end
  end

  # DELETE /parties/1
  # DELETE /parties/1.json
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html do
        redirect_to admin_parties_url, flash: {
          success:  t('shared.msgs.success_destroyed',
                      obj: t('mongoid.models.party.one'))
        }
      end
      format.json { head :no_content }
    end
  end

  private

  def _params
    pars = params.clone
    puts "=================================#{pars}"
    # default = I18n.default_locale
    # locales = [:ka, :en, :ru]
    [:title_translations, :description_translations].each do |f|
      pars[:party][f].delete_if { |_k, v| !v.present? }
    end
    # sls = pars[:party][:_slugs_translations];
    # sls.each{|k,v| sls[k] = [v] }
    pars.require(:party).permit(
      :_id, :id, :title, :type, :color, :name, :tmp_id,
      title_translations: [:ka, :en, :ru],
      description_translations: [:ka, :en, :ru]
    )
  end

  def _bulk_params
    # params.permit(:id).permit(:parties).permit!
    # pars = params.clone
    params.permit(:id, parties: {}).tap do |whitelisted|
      whitelisted[:parties] = params[:parties]
      whitelisted[:id] = params[:id]
    end
  end
end
