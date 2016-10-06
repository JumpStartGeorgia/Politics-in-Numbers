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

    # dd = nil
    #  Donor.each{|e| e.donations.each{|ee|
    #     if ee.amount == 800
    #       dd = e
    #     end
    #   }
    # }
    #Rails.logger.debug("--------------------------------------------#{dd.collection.inspect}")
    # sd = dd.collection.aggregate([
    #     { "$match": { "donations.amount": 800 } },
    #    {
    #       "$project": {
    #         first_name: 1,
    #          donations: {
    #             "$filter": {
    #                 input: "$donations",
    #                 as: "donation",
    #                 cond: { "$eq": [ "$$donation.amount", 800 ] }
    #                #cond: { "$$donation": { "$amount": 800 } }
    #             }
    #          }
    #       }
    #    }
    # ])
    # # .each do | doc |
    # #     pp doc
    # # end
    #  Rails.logger.debug("--------------------------------#{sd.inspect}")
    # @categories = Category.tree_out
    #@parties = Dataset.first
  end

  def explore
    pars = explore_params
    is_csv = pars[:format] == 'csv'



    which_filter = pars[:filter]
    @filter_type = which_filter == "finance" ? "finance" : "donation"
    has_filters = which_filter.present? && (which_filter == "donation" || which_filter == "finance")

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

    if !has_filters
      has_filters = true
      @filter_type = "finance"
      which_filter = "finance"
      pars.merge!(finance_pars)
    end

    is_finance = which_filter == "finance"
    is_donation = !is_finance

    dt = []

    donation_pars = pars if !is_finance
    finance_pars = pars if is_finance


    if !is_csv

      gon.url = root_url
      gon.app_name = "pins.ge"
      gon.date_format = t('date.formats.jsdate')
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



      gon.gonned_type = which_filter

      gon.donation_params = donation_pars
      gon.donation_data = Donor.explore(donation_pars)

      tmp = Dataset.explore(finance_pars)
      gon.finance_params = tmp.delete(:pars)
      gon.finance_data = tmp

      dt = is_finance ? gon.finance_data : gon.donation_data

      pars.delete(:locale)
      @donation_download_link = request.path + "?filter=donation&" +  donation_pars.reject{|k,v| k == "filter" }.to_param  + "#{donation_pars.empty? ? '' : '&'}#{'format=csv'}"
      @finance_download_link = request.path + "?filter=finance&" +  finance_pars.reject{|k,v| k == "filter" }.to_param  + "#{finance_pars.empty? ? '' : '&'}#{'format=csv'}"

      gon.params = pars

    else

      dt = is_finance ? Dataset.explore(finance_pars, true) : Donor.explore(donation_pars, true)

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
      format.csv { send_data csv_file, filename: "explore_#{which_filter}_#{Date.today}.csv" }
    end
  end

  def explore_filter
    res = {}
    pars = explore_filter_params

    if pars[:donation].present?
      res[:donation] = Donor.explore(pars[:donation])
    elsif pars[:finance].present?
      res[:finance] = Dataset.explore(pars[:finance])
    end

    render :json => res
  end

  def download
    @show_page_title = false

    pars = download_params
    is_zip = pars[:format] == 'zip'

    which_filter = pars[:filter]
    @filter_type = which_filter == "finance" ? "finance" : "donation"
    has_filters = which_filter.present? && (which_filter == "donation" || which_filter == "finance")

    donation_pars = {}
    finance_pars = {}

    if !has_filters
      has_filters = true
      @filter_type = "finance"
      which_filter = "finance"
      pars.merge!(finance_pars)
    end

    is_finance = which_filter == "finance"
    is_donation = !is_finance

    @button_state = ['','']
    @button_state[is_finance ? 1 : 0] = ' active'

    dt = []

    donation_pars = pars if !is_finance
    finance_pars = pars if is_finance

    if !is_zip
      gon.download = t('.download')
      gon.search = t('.search')
      # gon.url = root_url
      # gon.app_name = "pins.ge"
      # gon.date_format = t('date.formats.jsdate')
      # gon.filter_item_close = t('.filter_item_close')
      # gon.all = t('shared.common.all')
      # gon.campaign = t('.campaign')
      # gon.search = t('.search')
      # gon.table_length = t('.table_length')
      # gon.numericSymbols = t('shared.common.numericSymbols')

      gon.gonned = false

      gon.party_list = Party.list
      gon.period_list = Period.list

      gon.gonned_type = which_filter
       Rails.logger.fatal("--------------------------------------------#{pars}")

      gon.donation_params = donation_pars
      gon.donation_data = Donor.download(donation_pars)
      tmp = [] #Dataset.explore(finance_pars)
      gon.finance_params = tmp.delete(:pars)
      gon.finance_data = tmp

      dt = is_finance ? gon.finance_data : gon.donation_data
      gon.donation_data = {donation: { table: { data: [["Donations", "16.05.2016-20.11.2016", "25.645KB"]] }}}
      pars.delete(:locale)

      # @donation_download_link = request.path + "?filter=donation&" +  donation_pars.reject{|k,v| k == "filter" }.to_param  + "#{donation_pars.empty? ? '' : '&'}#{'format=csv'}"
      # @finance_download_link = request.path + "?filter=finance&" +  finance_pars.reject{|k,v| k == "filter" }.to_param  + "#{finance_pars.empty? ? '' : '&'}#{'format=csv'}"

      gon.params = pars

    else

      dt = is_finance ? Dataset.explore(finance_pars, true) : Donor.download(donation_pars, true)

      # csv_file = CSV.generate do |csv|
      #   if is_donation
      #     csv << dt[:table][:header]
      #   else
      #     dt[:table][:header].each{|e|
      #       tmp = []
      #       tmp_prev = ""
      #       e.reverse_each{|ee|
      #         tmp.unshift(ee.present? ? ee : tmp_prev)
      #         tmp_prev = ee
      #       }
      #       csv << tmp
      #     }
      #   end
      #   dt[:table][:data].each { |r| csv << r }
      # end
    end

    respond_to do |format|
      format.html
      format.zip { send_data dt[:file], filename: "explore_#{which_filter}_#{Date.today}.zip" }
    end
    # @page_content = PageContent.by_name('about')
  end

  def download_filter
    res = {}
    pars = download_filter_params
    if pars[:donation].present?
      res[:donation] = Donor.download(pars[:donation])
    elsif pars[:finance].present?
      res[:finance] = { finance: "test" } # Dataset.explore(pars[:finance])
    end

    render :json => res
  end


  # show the embed chart if the id was provided and can be decoded and parsed into hash
  # id - base64 encoded string of a hash of parameters
  def embed

    # @highlight_data = get_highlight_data(params[:id])
    # puts @highlight_data.inspect
    # if !@highlight_data[:error]
    # puts "here"
    #   # save the js data into gon
    #   gon.highlight_data = {}
    #   gon.highlight_data[@highlight_data[:highlight_id].to_s] = @highlight_data[:js]

    #   set_gon_highcharts

    #   gon.update_page_title = true

    #   gon.get_highlight_desc_link = highlights_get_description_path
    #   gon.powered_by_link = @xtraktr_url
    #   gon.powered_by_text = I18n.t('app.common.powered_by_xtraktr')
    #   gon.powered_by_title = I18n.t('app.common.powered_by_xtraktr_title')

    #   gon.visual_type = @highlight_data[:visual_type]
    #   if @highlight_data[:visual_type] != Highlight::VISUAL_TYPES[:map] # if the visual is a chart, include the highcharts file
    #     @js.push('highcharts.js')
    #   elsif @highlight_data[:visual_type] == Highlight::VISUAL_TYPES[:map] # if the visual is a map, include the highmaps file
    #     @js.push('highcharts.js', 'highcharts-map.js')

    #     if @highlight_data[:type] == 'dataset'
    #       @shapes_url = Dataset.shape_file_url(@highlight_data[:id]) # have to get the shape file url for this dataset
    #     end
    #   end
    #   @js.push('highcharts-exporting.js')
    # end
    puts "here1"
    respond_to do |format|
      format.html # index.html.erb
    end
  # end
  end


  def about
    @donations_page_content = PageContent.by_name('about_donations')
    @party_finances_page_content = PageContent.by_name('about_party_finances')
    @show_page_title = false
  end

  def media
    @media = Medium.is_public.sorted_public.page(params[:page]).per(2)
    @show_page_title = false
    gon.show_more = t('shared.common.show_more')
    gon.show_less = t('shared.common.show_less')
  end



  # def api
  #   # @page_content = PageContent.by_name('about')
  # end

  # def parties
  #   # @page_content = PageContent.by_name('about')
  # end
  def select_donors
    q = params[:q].split
    donors = []
    if q.length == 1
      regex1 =  /^#{Regexp.escape(q[0])}/i
      regex2 = /.*/i
    else
      regex1 =  /^#{Regexp.escape(q[0])}/i
      regex2 = /^#{Regexp.escape(q[1])}/i
    end
    Donor.any_of({ first_name: regex1 , last_name: regex2 }, { first_name: regex2 , last_name: regex1 }, {tin: regex1 }).each{ |m|
      donors << [ "#{m.first_name} #{m.last_name}", "#{m.id}"]
    }
    render :json => donors
  end


  def download_file
    # Zip::File.open('path/archive.zip', Zip::File::CREATE) do |z|
    #   files.each do |f|
    #     z.add('file_name', f.path)
    #   end
    # end
    respond_to do |format|
      format.html
      format.zip do
        compressed_filestream = Zip::OutputStream.write_buffer do |zp|
          zp.put_next_entry "parties.xlsx"
          zp.print IO.read(Rails.public_path.join("upload/test/parties.xlsx"))

          zp.put_next_entry "categories.xlsx"
          zp.print IO.read(Rails.public_path.join("upload/test/categories.xlsx"))

          #zp.print animal.to_json(only: [:name, :age, :species])
        end
        compressed_filestream.rewind
        send_data compressed_filestream.read, filename: "animals.zip"
        # send_file 'path/archive.zip', type: 'application/zip',
        #   disposition: 'attachment',
        #   filename: "my_archive.zip"
      end
    end
  end
#options = Rack::Utils.parse_query(Base64.urlsafe_decode64(embed_id))
  # def select_parties
  #   q = params[:q]
  #   parties = []
  #   regex1 =  /^#{Regexp.escape(q[0])}/i
  #   # Party.all.each{ |set|
  #   #   set.donors.any_of({ title: regex1 , last_name: regex2 }, 1{ first_name: regex2 , last_name: regex1 }, {tin: regex1 }).each{ |m|
  #   #     parties << [ "#{m.first_name} #{m.last_name}", "#{m.id}"]
  #   #   }
  #   # }
  #   render :json => parties
  # end

  def share
    pars = share_params
    @return_url = pars[:return_url]
    @return_url = root_path if !@return_url.present?
    Rails.logger.info("--------------------------------------------#{request.user_agent}")
     #dev-pin.jumpstart.ge/share?return_url=http://google.com&params[]=2
     #http://localhost:3000/ka/share?return_url=/about&params[]=123&params[]=abc
     #http://localhost:3000/ka/share?return_url=http://www.dev-pin.jumpstart.ge&params[]=123&params[]=abc
     @inner_pars = []
     @inner_pars = pars[:params] if pars[:params].present?
     #facebookexternalhit
    if (request.user_agent.include?("facebook") && request.user_agent.include?("externalhit")) # if facebook robot Rails.env.development? ||
#https://www.facebook.com/sharer/sharer.php?app_id=570138349825593&sdk=joey&u=http%3A%2F%2Fdev-pin.jumpstart.ge%2Fen%2Fshare%3Freturn_url%3D%252Fka%252Fshare_test%26params%255B0%255D%3D123%26params%255B1%255D%3Dabc&display=popup&ref=plugin&src=share_button
      # if p.present?
      #   encodedP = Base64.urlsafe_encode64(p.to_param)
      #   require 'game_data'

      #   @url = request.original_url.split('?').first + '?f=' + encodedP
      #   tick = 12
      #   cur_ticks = p['t'].to_i
      #   gender = p['g']
      #   category = GameData.category(p['c'])
      #   salary = p['s'].to_i

      #   msalary = 0
      #   if(gender=='m')
      #     msalary = salary
      #     fsalary = salary + (category[:outrun]==1 ? 1 : -1)*(salary * category[:percent] / 100);
      #   else
      #     fsalary = salary
      #     msalary = salary + (category[:outrun]==1 ? -1 : 1)*(salary * category[:percent] / 100);
      #   end
      #   fsalary_total = ((gender == 'm' ? msalary : fsalary) * (cur_ticks * tick)).floor
      #   ssalary_total = ((gender == 'm' ? fsalary : msalary) * (cur_ticks * tick)).floor
      #   salary_total_diff = (fsalary_total - ssalary_total).abs.floor


      #   # params needed for t('.desc1') that is in the share page
      #   @years = ((cur_ticks * tick) / 12).to_s
      #   @job = ''
      #   if p['c'] != 'hyn3wmKk' # do not show job title for 'all jobs'
      #     @job = I18n.t('gap.share.job', job: I18n.t("gap.gamedata.share_category.#{p['c']}"))
      #   end


      #   @salary = view_context.number_with_delimiter(salary_total_diff)
      #   @more_less = ((gender == 'm' && msalary > fsalary) || (gender == 'f' && fsalary > msalary)) ? t('gap.share.more') : t('gap.share.less')
      #   @gender = I18n.t("gap.share.#{gender == 'f' ? 'm' : 'f'}")


      #   @descr = "Gender " + I18n.t("gap.gamedata.gender.#{p['g']}") + ", Age " + p['a'] + ", Category " + I18n.t("gap.gamedata.category.#{p['c']}") + ", Salary " + p['s'] + ", Interest " +  I18n.t("gap.gamedata.interest.#{p['i']}") + ", Salary Percent " + p['p']
      #   respond_to do |format|
      #     format.html
      #   end
      # else
      #   redirect_to gap_path and return
      # end
      Rails.logger.info("--------------------------------------------inside")
    else
      Rails.logger.info("--------------------------------------------redirecting")
      redirect_to @return_url and return
    end
  end

  private
      # "donation"=>{"donor"=>["574d9379fbb6bd0313000007", "574d9379fbb6bd0313000014"],
    #  "period"=>["1464724800000", "1464897600000"],
    #   "amount"=>["100", "500"],
    #    "party"=>["5748093cfbb6bd3781000016", "5748093cfbb6bd3781000027"],
    #     "type"=>"monetary",
    #      "multiple"=>"yes"},
    #       "locale"=>"en"}
    def share_params
      params.permit(:return_url, :locale, {params: []})
    end
    def explore_params
      params.permit([:filter, :monetary, :multiple, :nature, :locale, :format, { donor: [], period: [], amount: [], party: [], income: [], income_campaign: [], expenses: [], expenses_campaign: [], reform_expenses: [], property_assets: [], financial_assets: [], debts: [] }])
    end
    def explore_filter_params
      params.permit(:donation => [:monetary, :multiple, :nature, :all, :locale, { donor: [], period: [], amount: [], party: []}],
        :finance => [:all, :locale, { party: [], period:[], income: [], income_campaign: [], expenses: [], expenses_campaign: [], reform_expenses: [], property_assets: [], financial_assets: [], debts: []  }])
    end
    def download_params
      params.permit([:filter, :locale, :format, period: [], party: [] ])
    end
    def download_filter_params
      params.permit(:donation => [:all, :locale, { period: [] }],
        :finance => [:all, :locale, { party: [], period:[] }])
    end
end







