# Dataset - trace category and detail data for party
# based on specific period
class Dataset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  after_create  :prune_share_images

  STATES = [:pending, :processed, :discontinued]  # 0 pending 1 processed 2 discontinued
  SYMS = [ :income, :income_campaign, :expenses, :expenses_campaign, :reform_expenses, :property_assets, :financial_assets, :debts ]

  embeds_many :category_datas
  embeds_many :detail_datas

  field :party_id, type: BSON::ObjectId
  field :period_id, type: BSON::ObjectId
  field :state, type: Integer, default: 0
  field :del, type: Boolean, default: false

  default_scope ->{ where(del: false) }
#  before_source_post_process :source_post_process
  has_mongoid_attached_file :source,
    :path => ':rails_root/public/system/:class/:attachment/:id/:style.:extension',
    :url => '/system/:class/:attachment/:id/:style.:extension'


  validates_presence_of :party_id, :period_id
  validates_attachment :source, presence: true, content_type: { content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }, size: { in: 0..25.megabytes }
  validates_inclusion_of :state, in: [0, 1, 2]

  def source_post_process
  end

  def self.sorted
    order_by([[:created_at, :desc]])
  end

  def party
    @party = Party.find(party_id)
  end

  def period
    @period = Period.find(period_id)
  end

  def party_name
    @party = party if @party.nil?
    @party.title
  end

  def period_name
    @period = period if @period.nil?
    @period.title
  end

  def current_state
    I18n.t("mongoid.options.dataset.state.#{STATES[state].to_s}")
  end

  def current_state_sym
    STATES[state].to_s
  end

  def set_state(st)
    st = STATES.index(st.to_sym)
    if st.present?
      self.state = st
      self.save
    end
  end

  def self.has_state(st)
    begin
      st.to_i < STATES.length
    rescue
      false
    end
  end

  def is_state(st)
    self.state == STATES.index(st)
  end

  def self.by_period(per_id)
    where({period_id: per_id})
  end

  def self.clean_ids(ids)
    ids = [] if !ids.present?
    ids = ids.delete_if(&:blank?)
    ids.class == Array ? ids : []
  end

  def self.filter(params)

    options = []
    matches = []
    conditions = []

    matches.push({ "party_id": { "$in": params[:party].map{|m| BSON::ObjectId(m)} } }) if params[:party].present?
    matches.push({ "period_id": { "$in": params[:period].map{|m| BSON::ObjectId(m)} } }) if params[:period].present?

    cat_ids = []
    SYMS.each { |e|
      params[e].each{ |m| cat_ids << BSON::ObjectId(m) } if params[e].present?
    }

    if cat_ids.present?
      matches.push({ "category_datas.category_id": { "$in": cat_ids } })
      ors = []
      cat_ids.each{|e| ors.push({ "$eq": ["$$category_datas.category_id", e ] }) }
      conditions.push({ "$or": ors });
    end

    options.push({ "$match": { "$and": matches } }) if !matches.blank?

    options.push({
      "$project": {
        party_id: 1,
        period_id: 1,
        category_datas: {
          "$filter": {
            input: "$category_datas",
            as: "category_datas",
            cond: { "$and": conditions }
          }

        }
      }
     })
    collection.aggregate(options)
  end
  def self.explore(params, type = "a", inner_pars = false)
    limiter = 5

    if inner_pars
      f = params
      f[:party] = [] unless f[:party].present?
      f[:period] = [] unless f[:period].present?
    else
      f = { }
      f[:party] = Party.get_ids_by_slugs(params[:party])
      f[:period] = Period.get_ids_by_slugs(params[:period])
    end
    ln = 0
    main_categories_count = 0
    missing_category = true
    SYMS.each { |e|
      if params[e].present?
        f[e] = inner_pars ? params[e].map{|m| BSON::ObjectId(m)} : Category.get_ids_by_slugs(params[e])
        if f[e].present?
          missing_category = false
        else
          params.delete(e)
        end
      end
    }
    if missing_category
      return nil
      # f[:income] = [Category.only_sym.where(sym: :income).first._id]
      # params[:income] = [:income]
    end
    data = filter(f).to_a

    parties = {}
    periods = {}
    categories = {}
    Party.each{|e| parties[e.id] = { value: 0, name: e.title } }
    # Rails.logger.fatal("----------------------------------------#{parties.inspect}----#{I18n.locale}")
    Period.each{|e| periods[e.id] = { name: e.title, date: e.start_date, type: e.type } }
    Category.each{|e| categories[e.id] = { title: e.title, parent_id: e.parent_id } }

    selected_categories = []
    main_categories = {}
    main_to_sub_category_map = {}
    category_period_party = {}
    category_grouped_period_party = {}

    SYMS.each { |e|
      if f[e].present?
        f[e].each{|ee|
          selected_categories << ee
          category_period_party[ee] = {}
          m_cat_id = Category.main_category_id(categories, ee)
          main_to_sub_category_map[ee] = m_cat_id
          if !main_categories[m_cat_id].present?
            main_categories[m_cat_id] = []
            category_grouped_period_party[m_cat_id] = {}
          end
          main_categories[m_cat_id] << ee
        }
        ln += f[e].size
        main_categories_count += 1
      end
    }
    cs = ln
    ps = f[:party].nil? ? 0 : f[:party].length

    chart_type = cs == 1 ? 0 : ( main_categories_count == 1 ? 1 : 2 )

    ca = []
    table = []
    # total_amount = 0
    # total_donations = 0
    # monetary_values = [I18n.t("mongoid.attributes.donation.monetary_values.t"), I18n.t("mongoid.attributes.donation.monetary_values.f")]
    # nature_values = [I18n.t("mongoid.attributes.donor.nature_values.private"), I18n.t("mongoid.attributes.donor.nature_values.organization")]
    # recent_donations = []
    parties_list = {}
    period_list = {}
    ca = []
    ca_categories = []


    # collect data
    data.each{|e|
      if !period_list[e[:period_id]].present?
        per = periods[e[:period_id]]
        period_list[e[:period_id]] = { id: e[:period_id], name: per[:name], date: per[:date], type: per[:type]  }
      end

      if !parties_list[e[:party_id]].present?
        parties_list[e[:party_id]] = { name: parties[e[:party_id]][:name], data: [] }
      end
    }

    f[:period].each { |p_id|
      if !period_list.key?(BSON::ObjectId(p_id))
        period_list[p_id] = { id: p_id, name: periods[BSON::ObjectId(p_id)][:name], date: periods[BSON::ObjectId(p_id)][:date], type: periods[BSON::ObjectId(p_id)][:type]  }
      end
    }

    f[:party].each { |p_id|
      if !parties_list.key?(BSON::ObjectId(p_id))
        parties_list[p_id] = { name: parties[BSON::ObjectId(p_id)][:name], data: [] }
      end
    }

    tmp = []
    period_list.each{|k,v| tmp.push({ id: v[:id], name: v[:name], date: v[:date], type: v[:type] }) }
    period_list = tmp.sort!{ |x,y| x[:date] <=> y[:date] }

    parties_list.each{|k,v|
      parties_list[k][:data] = Array.new(period_list.size, 0)

    }

    main_categories.each{|cat_k, cat_v|
      period_list.each { |per|
        parties_list.each{ |k,v|

          if !category_grouped_period_party[cat_k][per[:id]].present?
            category_grouped_period_party[cat_k][per[:id]] = {}
          end

          if !category_grouped_period_party[cat_k][per[:id]][k].present?
            category_grouped_period_party[cat_k][per[:id]][k] = 0
          end
        }
      }
    }




    data.each{|e|


      pp = period_list.index{ |s| s[:id] == e[:period_id] }
      per = period_list[pp]
      e[:category_datas].each { |ee|

        #one category and common
        parties_list[e[:party_id]][:data][pp] = ee[:value].round(2)

        # one main multiple sub
        category_period_party[ee[:category_id]][e[:period_id]] = {}
        category_period_party[ee[:category_id]][e[:period_id]][e[:party_id]] = ee[:value].round(2)

        # more than one main category
        category_grouped_period_party[main_to_sub_category_map[ee[:category_id]]][e[:period_id]][e[:party_id]] += ee[:value].round(2)

      }
    }

    categories_list = []

    # Party Finance chart titles: Chart titles be like this: Category name (if 2, connect with 'and', if more than 2, connect with comma and put 'and' between the last one items), Party Name ( (if more than one, the same principle), Time period


    # title generator
    chart_titles = [[],[],[]]

    if ln >= 1 # grab selected category names
      #chart_title += I18n.t("shared.chart.finance.title.#{ln == 1 ? 'category' : 'category_grouped_by'}")+": "
          # chart_title += tmp.join(', ') + (chart_type == 2 ? "; " : ", ")
      SYMS.each { |e|
        if f[e].present?
          tmp = Category.full_names(categories, f[e])
          chart_titles[0].concat(tmp);
          tmp.each{|ee| categories_list << ee }
        end
      }
    end

    chart_titles[1].concat(f[:party].map{|m| parties[BSON::ObjectId(m)][:name] }) # grab selected party names

    if f[:period].present? # grab selected period names

      chart_titles[2].concat(f[:period].map{|m| "#{periods[BSON::ObjectId(m)][:name]}" })
    end

    chart_title = ""
    last_and = I18n.t("shared.common.and")
    chart_titles.each{ |r|
      sz = r.size
      r.each_with_index { |rr, ii|
        chart_title += (ii == sz - 1 && sz > 1 ? " " + last_and + " " : ", ") + rr
      }
    }
    chart_title = chart_title[2..chart_title.size-1] if chart_title.size > 1

    headers = [[""],[I18n.t("shared.common.parties")]]
    header_classes = [["empty"], ["outer"]]
    classes = [nil]
    # prepaire data for charts
    if chart_type == 0 # one category
      ca = parties_list.map{|k,v|
        table << ( [v[:name]] + v[:data] ) # data for table
        { name: v[:name], data: v[:data] } # data for chart
      }

      period_list.each_with_index{|e, i|
        ca_categories << e[:name] # chart categories (years)
        headers[0] << nil # table header first row
        headers[1] << e[:name] # table header second row
        header_classes[0] << nil # table header class first row
        header_classes[1] << nil # table header class second row
        classes << "right" # table data class
      }
      headers[0][headers[0].size-1] = categories_list[0] # custom header label for first row category label
      header_classes[0][headers[0].size-1] = "outer center" # custom header class for first row category label

    elsif chart_type == 1 # multiple categories for same main category

      selected_categories.each_with_index{|cat, cat_i|

        ca.push({
          name: categories[cat][:title],
          data: []
        });
        period_list.each { |per|
          parties_list.each{ |k,v|
            ca[cat_i][:data] << category_period_party[cat][per[:id]][BSON.ObjectId(k)]
          }
        }
      }

      parties_list.each{ |k,v|
        table << [v[:name]]
        period_list.each { |per|
          selected_categories.each_with_index{|cat|
            tmp = category_period_party[cat][per[:id]][BSON.ObjectId(k)]
            table[table.size-1] << (tmp.present? ? tmp : 0)
          }
        }
      }

      period_list.each { |e|
        item = {
          name: e[:name],
          categories: []
        }
        parties_list.each{ |k,v|
          item[:categories].push(v[:name])
        }
        ca_categories.push(item)


        selected_categories.each{|cat|
          headers[0] << nil # table header first row
          headers[1] << categories[cat][:title] # table header first row
          header_classes[0] << nil # table header class first row
          header_classes[1] << nil # table header class second row
          classes << "right" # table data class
        }
        headers[0][headers[0].size-1] = e[:name]
        header_classes[0][headers[0].size-1] = "outer center"
      }

    elsif chart_type == 2 # multiple categories for different main categories
      cat_i = 0
      main_categories.each{|cat_k, cat_v|
         # Rails.logger.debug("-------------------------------#{main_categories}---------#{cat_k}----#{cat_v}")
        tmp = cat_v.map{ |m| categories[m][:title] }.join(", ")

        ca.push({
          name: tmp,
          data: []
        });

        period_list.each { |per|
          parties_list.each{ |k,v|
            ca[cat_i][:data] << category_grouped_period_party[cat_k][per[:id]][k]
          }
        }
        cat_i += 1
      }

      parties_list.each{ |k,v|
        table << [v[:name]]
        period_list.each { |per|
          main_categories.each{|cat_k, cat_v|
            tmp = category_grouped_period_party[cat_k][per[:id]][k]
            table[table.size-1] << (tmp.present? ? tmp : 0)
          }
        }
      }

      period_list.each { |e|
        item = {
          name: e[:name],
          categories: []
        }
        parties_list.each{ |k,v|
          item[:categories].push(v[:name])
        }
        ca_categories.push(item)

        main_categories.each{|cat_k, cat_v|
          headers[0] << nil # table header first row
          headers[1] << cat_v.map{|m| categories[m][:title] }.join(", ")# table header first row
          header_classes[0] << nil # table header class first row
          header_classes[1] << nil # table header class second row
          classes << "right" # table data class
        }
        headers[0][headers[0].size-1] = e[:name]
        header_classes[0][headers[0].size-1] = "outer center"
      }

    end
    if ["a"].index(type).present?
      f.keys.each{|e|
        if f[e].class == Array
          if f[e].empty?
            f.delete(e)
          else
            f[e].each_with_index{|ee,ii|
              f[e][ii] = ee.to_s if ee.class == BSON::ObjectId
            }
          end
        end
      }
      sid = ShortUri.explore_uri(f.merge({filter: "finance"}))
    end
    res = {}
    if ["t", "a"].index(type).present?
      res = {
        table: {
          data: table,
          header: headers,
          header_classes: header_classes,
          classes: classes
        }
      }
    end
    if ["ca", "a", "co", "coa"].index(type).present?
      res.merge!({
        ca: {
            categories: ca_categories,
            series: ca,
            title: chart_title
        }
      })
    end
    if ["a"].index(type).present?
      res.merge!({
        sid: sid,
        pars: f
      })
    end

    res
  end
  def self.download_filter(params)

    options = []
    matches = []
    conditions = []

    matches.push({ "_id": { "$in": params[:ids].map{|m| BSON::ObjectId(m)} } }) if params[:ids].present?
    matches.push({ "party_id": { "$in": params[:party].map{|m| BSON::ObjectId(m)} } }) if params[:party].present?
    matches.push({ "period_id": { "$in": params[:period].map{|m| BSON::ObjectId(m)} } }) if params[:period].present?

    matches.push({ "state": { "$eq": 1 } }) # only processed datasets

    options.push({ "$match": { "$and": matches } }) if !matches.blank?

    options.push({
      "$project": {
        party_id: 1,
        period_id: 1
      }
     })

    #options.push({ "$sort": { give_date: -1, name: 1 } })
    collection.aggregate(options)
  end
  def self.download(params, type="table")

    f = {}
    f[:ids] = Dataset.clean_ids(params[:ids]) if params[:ids].present?
    f[:party] = Party.get_ids_by_slugs(params[:party]) if params[:party].present?
    f[:period] = Period.get_ids_by_slugs(params[:period]) if params[:period].present?

    data = download_filter(f).to_a
    parties = {}
    periods = {}
    Party.members.each{|e| parties[e.id] = e.title }
    Period.each{|e| periods[e.id] = { tp: e.current_type, sd: e.start_date, ed: e.end_date } }
    min_date = Date.new(2050,1,1)
    max_date = Date.new(1970,1,1)

    if type == "table"
      require "#{Rails.root}/lib/js/helper.rb"
      table = []
      data.each_with_index{ |e, e_i|
        p = periods[e[:period_id]]
        table << [e[:_id].to_s, "#{parties[e[:party_id]]} - #{p[:tp]}", "#{I18n.l(p[:sd], format: :date)} - #{I18n.l(p[:ed], format: :date)}"]
        max_date = p[:ed] if p[:ed] > max_date
        min_date = p[:sd] if p[:sd] < min_date
      }
      table.sort!{ |x,y| [x[1],y[2]] <=> [y[1],x[2]] } # sort by name asc and date desc

      {
        table: {
          header: ["", I18n.t("root.download.filename"), I18n.t("root.download.filename_period")],
          data: table,
          classes: ["", "", "center"]
        },
      }
    elsif type == "file" || type == "info"
      sz = 0
       # Rails.logger.fatal("fatal----------------------#{data.present?}#{ActionController::Base.helpers.number_to_human_size(sz)}")
      if data.present?
        require "#{Rails.root}/lib/js/helper.rb"
        compressed_filestream = Zip::OutputStream.write_buffer do |zp|
          data.each_with_index{ |e, e_i|
            tmp_party = parties[e[:party_id]]
            p = periods[e[:period_id]]
            max_date = p[:ed] if p[:ed] > max_date
            min_date = p[:sd] if p[:sd] < min_date
            zp.put_next_entry "%s%s.xlsx" % [Helper.sanitize("#{tmp_party} (#{p[:tp]} "), "#{I18n.l(p[:sd], format: :filename)}_#{I18n.l(p[:ed], format: :filename)})"]
            zp.print IO.read(Rails.public_path.join("system/datasets/sources/#{e[:_id]}/original.xlsx"))
          }
        end
        compressed_filestream.rewind
        sz = compressed_filestream.size # not sure if close is needed compressed_filestream.close
      end
      { size: ActionController::Base.helpers.number_to_human_size(sz) }
      .merge(type == "file" ? {
        file: sz > 0 ? compressed_filestream.read : nil,
        filename: "#{I18n.t("root.download.filename_finance")}_#{I18n.l(min_date, format: :filename)}_#{I18n.l(max_date, format: :filename)}_(pins.ge).zip" } : {})
    end
  end

  private

    def prune_share_images
      begin
        I18n.available_locales.each { |lang|
          path = "#{Rails.root}/public/system/share_images/finance/#{lang}"
          if File.directory?(path)
            FileUtils.remove_entry_secure(path, force = true)
            FileUtils.mkdir_p(path)
          end
        }
        return true
      rescue
        return false
      end
    end
end
