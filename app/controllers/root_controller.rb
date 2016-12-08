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
        pars = Hash.transform_keys_to_symbols(shr.pars)
        inner_pars = true
      else
        redirect_to explore_path and return
      end
    end
    @fltr = pars[:filter]

    @categories = Category.non_virtual # required for object explore calls
    gon.category_lists = []# Category.simple_tree_local(@categories.to_a, false)
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

      gon.root_url = root_url

      gon.path = explore_path
      gon.filter_path = explore_filter_path
      gon.embed_path = embed_static_path(id: "_id_")
      gon.share_url = share_url({ id: "_id_", chart: "_chart_" })
      gon.share_desc = t("shared.common.description").html_safe
      gon.app_name = "pins.ge"
      gon.app_name_long = t('shared.common.name')
      gon.date_format = t('date.formats.jsdate')
      gon.mdate_format = t('date.formats.jsmomentdate')
      gon.filter_item_close = t('.filter_item_close')
      gon.all = t('shared.common.all')
      gon.campaign = t('.campaign')
      gon.search = t('.search')
      gon.table_length = t('.table_length')
      gon.numericSymbols = t('shared.common.numericSymbols')
      gon.donations_filter_path = filter_donations_path

      gon.gonned = true


      @party_list = Party.sorted.map { |m| [m.id, m.title, m.permalink, m.type == 0 && m.member == true] }
      gon.party_list = Party.list_from(@party_list)

      gon.donor_list = Donor.list(donation_pars[:donor]) if donation_pars.key?(:donor)

      @period_list = Period.sorted.map { |m| [m.id, m.title, m.permalink, m.start_date, m.type] }
      gon.period_list = Period.list_from(@period_list)

      gon.is_donation = is_donation

      tmp = Donor.explore(donation_pars, "a", inner_pars, { parties: @party_list })
      gon.donation_params = tmp.delete(:pars)
      gon.donation_data = tmp

      tmp = Dataset.explore(finance_pars, "a", inner_pars, { parties: @party_list, periods: @period_list })
      gon.finance_params = tmp.delete(:pars)
      gon.finance_data = tmp

      dt = is_finance ? gon.finance_data : gon.donation_data

      pars.delete(:locale)

      @finance_download_link = gon.path + "/" + gon.finance_data[:sid] + "?format=csv"

      gon.donation_table_download_title = t('root.explore.download_table')
      gon.params = pars

    else
      if is_finance
        dt = Dataset.explore(finance_pars, "t", inner_pars)
        csv_file = CSV.generate do |csv|
          dt[:table][:header].each{|e|
            tmp = []
            tmp_prev = ""
            e.reverse_each{|ee|
              tmp.unshift(ee.present? ? ee : tmp_prev)
              tmp_prev = ee
            }
            csv << tmp
          }
          dt[:table][:data].each { |r| csv << r }
        end
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
    # sid =
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
    @missing = true
    pars = share_params

    sid = pars[:id]
    chart = pars[:chart]
    img = pars[:img]
    data = nil
    is_donation = nil
    @title = "#{t('shared.common.name')}"
    @sitename = t('shared.common.name')
    @descr = t("shared.common.description")
    @share_url = share_url({ id: sid, chart: chart })

    if sid.present?
      shr = ShortUri.by_sid(sid, :explore)
      if shr.present? && shr.other.present? && (shr.other == 0 || shr.other == 1)
        is_donation = shr.other == 0
        if (is_donation ? ["a", "b"] : ["a"]).index(chart).present?
          data = (is_donation ? Donor : Dataset).explore(Hash.transform_keys_to_symbols(shr.pars), "co" + chart, true)

          k = ("c#{chart}").to_sym
          @title = "#{data[k][:title]} | #{@title}"
          @image = generate_highchart_png(sid, chart, data, is_donation)
          @missing = false
        end
      end
    end

    if @missing
      @image = view_context.image_url("missing_share.png")
    end
    if img.present? || request.user_agent.include?("facebookexternalhit") || request.user_agent.include?("Twitterbot")
        respond_to do |format|
          format.html
        end
    else
      redirect_to explore_path({ id: sid }) and return
    end
  end

  def donors_filter
    q = params[:q]
    q = q.split if q.present?
    donors = []
    if q.length == 1
      regex1 =  /^#{Regexp.escape(q[0])}/i
      regex2 = /.*/i
    elsif q.length == 2
      regex1 =  /^#{Regexp.escape(q[0])}/i
      regex2 = /^#{Regexp.escape(q[1])}/i
    end
    args1 = []
    args2 = []
    I18n.available_locales.each{|locale|
      args1 << { "first_name.#{locale}": regex1 }
      args1 << { "last_name.#{locale}": regex1 }
      args1 << { "tin": regex1 }

      args2 << { "first_name.#{locale}": regex2 }
      args2 << { "last_name.#{locale}": regex2 }
      args2 << { "tin": regex2 }
    }

    Donor.all_of({"$or" => args1 }, {"$or" => args2 }).sorted.each{ |m|
      donors << [ m.permalink, m.full_name, m.tin ]
    }
    render :json => donors.sort{|x,y| x[1] <=> y[1] }
  end

  def donations_datatable_filter
    dt = Donor.explore_table(params, request.format)
    if request.format.csv?
      csv_file = CSV.generate do |csv|
        csv << dt[:table][:header]
        dt[:table][:data].each { |r| csv << r }
      end
    end
    respond_to do |format|
      format.json { render :json => dt }
      format.csv { csv_file.present? ? send_data(csv_file, filename: "explore_donation_#{Date.today}.csv") : redirect_to(explore_path, :notice => t('shared.msgs.data_not_found')) }
    end
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
      params.permit(:id, :chart, :img, :locale)
    end
    def donors_filter_params
      params.permit(:q)
    end

    def highchart_options_by_type (type)
      if type == :bar
        infile = "{ _colors_, _credits_, \"chart\": {\"type\": \"bar\", \"backgroundColor\": \"_bg_\", }, \"title\": {\"text\": \"_title_\", \"style\": {\"color\": \"#5d675b\", \"fontSize\":\"18px\", \"fontFamily\": \"Fira Sans\", \"textShadow\": \"none\"} }, \"subtitle\": {\"text\": \"_subtitle_\", \"style\": {\"color\": \"#5d675b\", \"fontSize\":\"12px\", \"fontFamily\": \"Fira Sans\", \"fontWeight\": \"100\", \"textShadow\": \"none\"} }, \"xAxis\": {\"type\": \"category\", \"lineWidth\": 0, \"tickWidth\": 0, \"labels\": {\"style\": {\"color\": \"#5d675b\", \"fontSize\":\"14px\", \"fontFamily\": \"Fira Sans\", \"fontWeight\": \"100\", \"textShadow\": \"none\"} } }, \"yAxis\": { \"visible\": false }, \"legend\": { \"enabled\": false }, \"plotOptions\": {\"bar\": {\"color\":\"#ffffff\", \"dataLabels\": {\"enabled\": true, \"padding\": 6, \"style\": {\"color\": \"#5d675b\", \"fontSize\":\"14px\", \"fontFamily\": \"Fira Sans\", \"textShadow\": \"none\"} }, \"pointInterval\":1, \"pointWidth\":17, \"pointPadding\": 0, \"groupPadding\": 0, \"borderWidth\": 0, \"shadow\": false } }, \"series\": [{ \"data\": _series_}] }"
      elsif type == :column
        infile = "{ _colors_, _credits_, \"chart\": {\"type\": \"column\", \"backgroundColor\": \"#FFFFFF\"}, \"title\": {\"text\": \"_title_\", \"margin\": 40, \"style\": {\"fontFamily\":\"Fira Sans\", \"fontSize\":\"18px\", \"color\": \"#5d675b\"}, \"useHTML\": true }, \"xAxis\": {\"type\": \"category\", \"categories\": _categories_, \"gridLineColor\": \"#5D675B\", \"gridLineWidth\":1, \"gridLineDashStyle\": \"Dash\", \"lineWidth\": 1, \"lineColor\": \"#5D675B\", \"tickWidth\": 1, \"tickColor\": \"#5D675B\", \"labels\": {\"style\": {\"color\": \"#5d675b\", \"fontSize\":\"14px\", \"fontFamily\": \"Fira Sans\", \"fontWeight\": \"100\",  \"textShadow\": \"none\"}, \"step\":1 } }, \"yAxis\": [{\"title\": { \"enabled\": false }, \"gridLineColor\": \"#eef0ee\", \"gridLineWidth\":1, \"style\": {\"color\": \"#5d675b\", \"fontSize\":\"14px\", \"fontFamily\": \"Fira Sans\", \"fontWeight\": \"100\", \"textShadow\": \"none\"} }, {\"linkedTo\":0, \"title\": { \"enabled\": false }, \"opposite\": true, \"style\": {\"color\": \"#7F897D\", \"fontSize\":\"12px\", \"fontFamily\": \"Fira Sans\", \"textShadow\": \"none\"} } ], \"legend\": {\"enabled\": true, \"symbolWidth\":10, \"symbolHeight\":10, \"shadow\": false, \"itemStyle\": {\"color\": \"#5d675b\", \"fontSize\":\"14px\", \"fontFamily\": \"Fira Sans\", \"textShadow\": \"none\"} }, \"plotOptions\": {\"column\":{\"maxPointWidth\": 40 } }, \"series\": _series_}"
      end
      infile.gsub!("_colors_", "colors: [ \"#D36135\", \"#DDCD37\", \"#5B85AA\", \"#F78E69\", \"#A69888\", \"#88D877\", \"#5D675B\", \"#A07F9F\", \"#549941\", \"#35617C\", \"#694966\", \"#B9C4B7\"]")
      infile.gsub!("_credits_", "credits: {enabled: true, text: \"pins.ge\"}")

      {
        "infile" => infile,
        "type" => "png",
        "constr" => "Chart",
        "width" => 1200,
        "globaloptions" => "{ lang: { numericSymbols: #{t('shared.common.numericSymbols')}, thousandsSep: ',' } }"
      }

    end
    # WARNINGGGGGGGGGG Fira sans regular and book should be installed on server pc
    def generate_highchart_png(id, chart, data, is_donation)
      begin
        image_name = "#{id}#{chart}.png"
        image_rel_dir = "/system/share_images/#{is_donation ? 'donation' : 'finance'}/#{I18n.locale}"
        image_abs_dir = "#{Rails.root}/public#{image_rel_dir}"
        image_rel_path = "#{image_rel_dir}/#{image_name}"
        image_abs_path = "#{image_abs_dir}/#{image_name}"

        if File.file?(image_abs_path)
          return view_context.image_url(image_rel_path)
        else
          # require 'net/http'
          uri = URI.parse("http://127.0.0.1:3003/")
          headers = { 'Content-Type' => 'application/json' }
          jsn = highchart_options_by_type(is_donation ? :bar : :column)

          k = ("c#{chart}").to_sym
          jsn["infile"].gsub!("_title_", data[k][:title])
          if is_donation
            jsn["infile"].gsub!("_bg_", chart == "a" ? "#EBE187" : "#B8E8AD")
            jsn["infile"].gsub!("_subtitle_", data[k][:subtitle])
            jsn["infile"].gsub!("_series_", data[k][:series].to_s)
          else
            jsn["infile"].gsub!("_categories_", data[k][:categories].to_s)
            jsn["infile"].gsub!("_series_", data[k][:series].to_json.to_s)
          end

          http = Net::HTTP.new(uri.host, uri.port)
          #http.set_debug_output $stderr
          http.request_post(uri.path, jsn.to_json, headers) {|response|
            FileUtils.mkdir_p(image_abs_dir) unless File.directory?(image_abs_dir)
            f = File.new(image_abs_path, 'wb')
            f << Base64.urlsafe_decode64(response.body)
            f.close
            return view_context.image_url(image_rel_path)
          }
        end
      rescue
        return view_context.image_url("missing_share.png")
      end
    end

end







