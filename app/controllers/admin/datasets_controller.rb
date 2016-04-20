class Admin::DatasetsController < ApplicationController
  # before_filter :authenticate_user!
  # before_filter do |controller_instance|
  #   controller_instance.send(:valid_role?, @site_admin_role)
  # end
  before_filter do @model = Dataset; end

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
        format.html { redirect_to admin_parties_path, flash: {success:  t('shared.msgs.success_created', :obj => t('mongoid.models.party.one'))} }
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
    @item = @model.find(params[:id])
    puts "---------------------#{_params.inspect}---------#{@item.inspect}--"
    respond_to do |format|
      if @item.update_attributes(_params)
        puts "good-----------------------------------____#{@item.errors.inspect}_"
        format.html { redirect_to admin_parties_path, flash: {success:  t('shared.msgs.success_updated', :obj => t('mongoid.models.party.one'))} }
        format.json { head :no_content }
      else
        puts "bad-----------------------------------____#{@item.errors.inspect}_"
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
      format.html { redirect_to admin_parties_url, flash: {success:  t('shared.msgs.success_deleted', :obj => t('mongoid.models.party.one'))} }
      format.json { head :no_content }
    end
  end

  private
    def _params
      pars = params.clone
      #puts "=================================#{pars}"
      default = I18n.default_locale
      locales = [:ka, :en, :ru]
      [:title_translations, :description_translations, :permalink_translations].each{|f|
        pars[:party][f].delete_if{|k,v| !v.present? }
      }
      # sls = pars[:party][:_slugs_translations];
      # sls.each{|k,v| sls[k] = [v] }
      pars.require(:party).permit(:_id, :id, :title, :type, :color, :name, :tmp_id, title_translations: [:ka, :en, :ru], description_translations: [:ka, :en, :ru], permalink_translations: [:ka, :en, :ru])
    end
end
