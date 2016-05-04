class Admin::MediaController < AdminController
  authorize_resource
  before_filter do @model = Medium; end

  # GET /media
  def index
    @items = @model.sorted

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /media/1
  def show
    @item = @model.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /media/new
  def new
    @item = @model.new

    set_tabbed_translation_form_settings

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /media/1/edit
  def edit
    @item = @model.find(params[:id])

    set_tabbed_translation_form_settings
  end

  # POST /media
  def create
    @item = @model.new(_params)

    respond_to do |format|
      if @item.save
        format.html { redirect_to admin_media_path, flash: {success:  t('shared.msgs.success_created', :obj => t('mongoid.models.medium.one'))} }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "new" }
      end
    end
  end

  # PUT /media/1
  def update
    @item = @model.find(params[:id])
    respond_to do |format|
      pars = _params
      if pars && pars[:medium] && pars[:medium][:media_images]
        pars[:medium][:media_images].each{ |img|
          @item.media_images.find_or_create_by(img)
        }
        pars[:medium].delete(:media_images)
      end


      puts "--------------------------#{pars.inspect}"
      if @item.update_attributes(pars)
        format.html { redirect_to admin_media_path, flash: {success:  t('shared.msgs.success_updated', :obj => t('mongoid.models.medium.one'))} }
      else
        set_tabbed_translation_form_settings

        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /media/1
  def destroy
    @item = @model.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to admin_media_url, flash: {success:  t('shared.msgs.success_destroyed', :obj => t('mongoid.models.medium.one'))} }
    end
  end

  private
    def _params
      [:name_translations, :title_translations, :description_translations,
       :author_translations, :permalink_translations, :embed_translations,
       :web_translations, :image_translations]
       .each{|f| params[:medium][f].delete_if{|k,v| !v.present? } }

      #image_translations = { ka: nil, en: nil, ru: nil }
      if params && params[:medium] && params[:medium][:image_translations]
        params[:medium][:media_images] = []
        params[:medium][:image_translations].each{ |k,v|
          params[:medium][:media_images] << { image: v, locale: k.to_sym }
        }
      end
      params[:medium].delete(:image_translations)
      puts "--------------------------#{params.inspect}"
      # params[:medium][:image_translations]
      #  image_translations
      params.require(:medium).permit( :public, :read_more, :show_image,
        name_translations: [:ka, :en, :ru],
        title_translations: [:ka, :en, :ru],
        description_translations: [:ka, :en, :ru],
        author_translations: [:ka, :en, :ru],
        embed_translations: [:ka, :en, :ru],
        permalink_translations: [:ka, :en, :ru],
        web_translations: [:ka, :en, :ru],
        image_translations: [:ka, :en, :ru],
        media_images: [:image, :locale])
    end
end
