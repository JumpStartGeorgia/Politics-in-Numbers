# Non-resource pages
class RootController < ApplicationController
  layout "embed", only: [:embed]
  layout false, only: [:share]
  def index
    # redirect_to('/explore')

    @show_page_title = false
    @home_page_content = PageContent.by_name('home')

    # get categories so can generate links to explore page
    categories = Category.non_virtual.only_sym
    @main_categories = {}
    categories.each{|m| @main_categories[m[:sym]] = m[:id].to_s }

  end

  def explore
    @show_page_title = false
    pars = explore_params
    inner_pars = false
    sid = pars[:id]
    if sid.present?
      shr = ShortUri.by_sid(sid, :explore)
      if shr.present?
        pars = shr.pars
        inner_pars = true
      else
        redirect_to explore_path and return
      end
    end
    @fltr = pars[:filter]

    @categories = Category.non_virtual # required for object explore calls
    gon.category_lists = Category.simple_tree_local(@categories.to_a, false)
    gon.main_categories = {}
    @categories.only_sym.each{|m| gon.main_categories[m[:sym]] = m.permalink }
    gon.main_categories_ids = gon.main_categories.map{|k,v| v}

    donation_pars = {}
    finance_pars = {
      income: [gon.main_categories[:income]],
      party: Party.where(:tmp_id.in => [1,2]).map{|m| m.permalink },
      period: Period.annual.limit(3).map{|m| m.permalink }
    }

    if !(@fltr.present? && ["finance", "donation"].index(@fltr).present?)
      @fltr = "finance"
      pars.merge!(finance_pars)
    end

    is_finance = @fltr == "finance"
    is_donation = !is_finance

    @button_state = ['', '']
    @button_state[is_finance ? 1 : 0] = ' active'

    dt = []

    donation_pars = pars if !is_finance
    finance_pars = pars if is_finance

    if !request.format.csv?

      gon.url = root_url
      gon.path = explore_path
      gon.filter_path = explore_filter_path
      gon.embed_path = embed_static_path(id: "_id_")
      gon.app_name = "pins.ge"
      gon.date_format = t('date.formats.jsdate')
      gon.mdate_format = t('date.formats.jsmomentdate')
      gon.filter_item_close = t('.filter_item_close')
      gon.all = t('shared.common.all')
      gon.campaign = t('.campaign')
      gon.search = t('.search')
      gon.table_length = t('.table_length')
      gon.numericSymbols = t('shared.common.numericSymbols')

      gon.gonned = true

      gon.party_list = Party.list
      gon.donor_list = Donor.list_with_tin
      gon.period_list = Period.list


      gon.is_donation = is_donation

      tmp = Donor.explore(donation_pars, "a", inner_pars)
      gon.donation_params = tmp.delete(:pars)
      gon.donation_data = tmp

      tmp = Dataset.explore(finance_pars, "a", inner_pars)
      gon.finance_params = tmp.delete(:pars)
      gon.finance_data = tmp

      dt = is_finance ? gon.finance_data : gon.donation_data

      pars.delete(:locale)
      @donation_download_link = request.path + "?filter=donation&" +  donation_pars.reject{|k,v| k == "filter" }.to_param  + "#{donation_pars.empty? ? '' : '&'}#{'format=csv'}"
      @finance_download_link = request.path + "?filter=finance&" +  finance_pars.reject{|k,v| k == "filter" }.to_param  + "#{finance_pars.empty? ? '' : '&'}#{'format=csv'}"

      gon.params = pars

    else

      dt = is_finance ? Dataset.explore(finance_pars, "t", inner_pars) : Donor.explore(donation_pars, "t", inner_pars)

      csv_file = CSV.generate do |csv|
        if is_donation
          csv << dt[:table][:header]
        else
          dt[:table][:header].each{|e|
            tmp = []
            tmp_prev = ""
            e.reverse_each{|ee|
              tmp.unshift(ee.present? ? ee : tmp_prev)
              tmp_prev = ee
            }
            csv << tmp
          }
        end
        dt[:table][:data].each { |r| csv << r }
      end
    end

    respond_to do |format|
      format.html
      format.csv { csv_file.present? ? send_data(csv_file, filename: "explore_#{@fltr}_#{Date.today}.csv") : redirect_to(explore_path, :notice => t('shared.msgs.data_not_found')) }
    end
  end

  def explore_filter
    pars = explore_filter_params
    res = {}
    p = pars[:donation]
    if p.present?
      tmp = Donor.explore(p)
      tmp.delete(:pars)
      res[:donation] = tmp
    elsif pars[:finance].present?
      tmp = Dataset.explore(pars[:finance])
      tmp.delete(:pars)
      res[:finance] = tmp
    end
    render :json => res
  end

  def download
    @show_page_title = false

    pars = download_params
    @fltr = pars[:filter]

    if !(@fltr.present? && ["finance", "donation"].index(@fltr).present?)
      @fltr = "finance"
      pars.merge!({filter: "finance"})
    end

    is_finance = @fltr == "finance"
    is_donation = !is_finance

    @button_state = ['', '']
    @button_state[is_finance ? 1 : 0] = ' active'

    dt = []

    if request.format.json?
      if pars[:type] == "info"
        dt = is_finance ? Dataset.download(pars, "info") : Donor.download(pars, "info")
      else
        dt = is_finance ? Dataset.download(pars) : Donor.download(pars)
      end

    elsif request.format.zip?
      dt = is_finance ? Dataset.download(pars, "file") : Donor.download(pars, "file")
    else
      gon.gonned = true

      gon.download = t('.download')
      gon.search = t('.search')
      gon.file_size = t('.file_size')

      gon.party_list = Party.list
      gon.period_list = Period.list

      gon.is_donation = is_donation

      gon.gonned_data = is_finance ? Dataset.download(pars) : Donor.download(pars)
      pars.delete(:locale)
      gon.params = pars
    end

    respond_to do |format|
      format.html
      format.json { render :json => dt }
      format.zip { dt[:file].present? ? send_data(dt[:file], filename: "#{dt[:filename]}") : redirect_to(download_path, :notice => t('shared.msgs.data_not_found')) }
    end
  end

  def about
    @show_page_title = false
    @donations_page_content = PageContent.by_name('about_donations')
    @party_finances_page_content = PageContent.by_name('about_party_finances')
  end

  def media
    @show_page_title = false
    @media = Medium.is_public.sorted_public.page(params[:page]).per(2)
    gon.show_more = t('shared.common.show_more')
    gon.show_less = t('shared.common.show_less')
  end

  def embed_static
    pars = embed_static_params
    sid =
    nsid = ShortUri.embed_static_uri(pars[:id])

    respond_to do |format|
      format.json { render :json => { sid: nsid } }
    end
  end

  # show the embed chart if the id was provided and can be decoded and parsed into hash
  # id - base64 encoded string of a hash of parameters
  def embed
    @missing = true

    pars = embed_params

    sid = pars[:id]
    type = pars[:type]
    is_static = type == "static"
    gon.tp = pars[:c]

    if sid.present?
      shr = ShortUri.by_sid(sid, is_static ? :embed_static : :explore)
      if shr.present? && shr.other.present? && (shr.other == 0 || shr.other == 1)
        gon.is_donation = shr.other == 0
        if (gon.is_donation ? ["a", "b"] : ["a"]).index(gon.tp).present?
          gon.data = is_static ? shr.pars : ((gon.is_donation ? Donor : Dataset).explore(shr.pars, "co" + gon.tp, true))
          @missing = false
        end
      end
    end

    respond_to do |format|
      format.html { render :layout => 'embed' }
    end
  end

  # def embed_test
  #   @id = params[:id]
  #   @type = params[:type]
  #   @chart = params[:chart]
  #   respond_to do |format|
  #     format.html { render :layout => false }
  #   end
  # end

  def share
    pars = share_params

    sid = pars[:id]
     Rails.logger.fatal("fatal----------------------#{sid}")
    gon.tp = pars[:c]
    @locale = I18n.locale
    @descr = "Lorem Ipsum Desc"
    @title = t('shared.common.name')
    @sitename = t('shared.common.name')
    @image = img_url({ id: sid }) #image_url("share.png")
    @share_url = share_url({ id: sid})

    if true || request.user_agent.include?("facebookexternalhit")
        respond_to do |format|
          format.html
        end
    else
      redirect_to explore_path({ id: sid }) and return
    end
  end

  def img
     id = params[:id]


    require 'net/http'
    uri = URI.parse("http://127.0.0.1:3003/")
    jsn = File.read("#{Rails.root}/vendor/assets/javascripts/highcharts-export-server/opts.json") #JSON.parse().to_s


    headers = {
      'Content-Type' => 'application/json', #'application/json',
    #   'Accept'  => '*/*', #'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' #'application/json'#,
    }

    http = Net::HTTP.new(uri.host, uri.port)
    #http.set_debug_output $stderr
    http.request_post(uri.path, jsn.gsub("%text", id), headers) {|response|
      f = File.new("#{Rails.root}/public/system/share/#{I18n.locale}/#{id}.png", 'wb')
      f << Base64.urlsafe_decode64(response.body)
      f.close
    }

    send_file "#{Rails.root}/public/system/share/#{I18n.locale}/#{id}.png",
       :type => 'image/png', :disposition => 'inline', filename: "#{id}.png"
  end

  private

    def explore_params
      params.permit([:id, :filter, :monetary, :multiple, :nature, :locale, :format, { donor: [], period: [], amount: [], party: [], income: [], income_campaign: [], expenses: [], expenses_campaign: [], reform_expenses: [], property_assets: [], financial_assets: [], debts: [] }])
    end

    def explore_filter_params
      params.permit(:locale, :donation => [:monetary, :multiple, :nature, { donor: [], period: [], amount: [], party: []}],
        :finance => [{ party: [], period:[], income: [], income_campaign: [], expenses: [], expenses_campaign: [], reform_expenses: [], property_assets: [], financial_assets: [], debts: []  }])
    end

    def download_params
      params.permit([:filter, :locale, :format, :type, period: [], party: [], ids: []])
    end

    def embed_params
      params.permit([:id, :type, :c ]) #, :width, :height, :locale, :format
    end

    def embed_static_params
      params.permit([ :id ]) #, :width, :height, :locale, :format
    end

    def share_params
      params.permit(:id)
    end

end







