class Admin::PartiesController < ApplicationController
  authorize_resource
  before_filter do @model = Party; end

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

  def bulk(ids=[])
    if ids.kind_of?(Array)
      @items = @model.where(:id.in => ids)
    end
    @items = @model.sorted

    respond_to do |format|
      format.html {
        redirect_to admin_parties_path  if !@items.present?
      }
    end
  end

    # PUT /parties/1
  # PUT /parties/1.json
  def bulk_update
    # "parties"=>{"blah-ka"=>{"type"=>"0"}, "aleksi-shoshikelashvilis-amomrchevelta-sainiciativo-jgupi"=>{"type"=>"1"}, "i"=>{"type"=>"1"}},
    errors = {}
    has_error = false
    @items = []
    _bulk_params.each { |k, v|
      party = @model.find(k)
      if party.present? && @model.is_type(v["type"])
        @items << party
        if !party.update_attributes({ type: v["type"].to_i, description: "test_ka"})
          errors[k] = { error: party.errors }
          has_error = true
        end
      end
    }
    respond_to do |format|
      if !has_error
        format.html { redirect_to admin_parties_path, flash: {success:  t('shared.msgs.success_updated', :obj => t('mongoid.models.party.one'))} }
        format.json { head :no_content }
      else
        format.html { render action: "bulk", flash: {success:  t('shared.msgs.unexpected_error')} }
        format.json { render json: errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parties/1
  # DELETE /parties/1.json
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_parties_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.party.one'))} }
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
    def _bulk_params
      pars = params.clone
      #puts "=================================#{pars}"
     # default = I18n.default_locale
      #locales = [:ka, :en, :ru]
      # sls = pars[:party][:_slugs_translations];
      # sls.each{|k,v| sls[k] = [v] }
      pars.require(:parties)#.tap do |whitelisted|
      #  whitelisted[:other_stuff] = params[:registration][:other_stuff]
     # end
      #pars.require(:parties).permit(:_id, :id, :title, :type, :color, :name, :tmp_id, title_translations: [:ka, :en, :ru], description_translations: [:ka, :en, :ru], permalink_translations: [:ka, :en, :ru])
    end
end
