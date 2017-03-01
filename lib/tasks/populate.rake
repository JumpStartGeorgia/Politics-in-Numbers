require 'fileutils'
# I18n.locale = :ka
def is_numeric?(obj)
   obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
end



namespace :populate do
  desc "Read and upload all annual files"
  task :annuals => :environment do |t, args|

    log_path = "#{Rails.root}/log/tasks"
    FileUtils.mkpath(log_path)
    lg = Logger.new File.open("#{log_path}/populate_annual.log", 'a')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    # Dataset.destroy_all # only for dev
    # Period.destroy_all

    I18n.locale = :en

    upload_path = Rails.public_path.join("upload/annuals")
    files = []
    filenames = []
    Dir.entries(upload_path).each {|f|
      if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
        files << "#{upload_path}/#{f}"
        filenames << f.to_s.gsub(".xlsx","")
      end
    }

    lg.info "----------------------------------"
    lg.info "#{files.length} - files to process (#{Time.now})"
    lg.info "----------------------------------"
    files.each_with_index {|f,f_i|
      lg.info filenames[f_i]+" >>>"

      tmp_id = filenames[f_i].split(".")
      year = tmp_id[1]
      tmp_id = tmp_id[0]

      prt = Party.find_by(tmp_id: tmp_id)
      per_title = "#{year}"
      per = Period.find_or_create_by({start_date: Date.strptime("01.01.#{year}", "%d.%m.%Y"), type: Period.type_is(:annual)}) do |rec|
        rec.title_translations = { ka: per_title, en: per_title }
        rec.description_translations = { ka: "წლიური #{per_title}", en: "Annual #{per_title}" }
      end

      dataset = nil
      if prt.present? && per.present?
        if !Dataset.where({party_id: prt._id, period_id: per._id}).present?
          dataset = Dataset.new({party_id: prt._id, period_id: period_id = per._id, source: File.open(f) })
          dataset.save
          Job.dataset_file_process(dataset._id, User.all[0]._id, []) # [admin_dataset_url(id: "_id")])
        else
          lg.info "  - already processed"
        end
      else
        lg.info "  - party for id #{tmp_id} is missing" if prt.nil?
        lg.info "  - period for id #{year} is missing" if per.nil?
        next
      end
    }
    lg.info "----------------------------------"
    lg.close
  end

  desc "Read and upload all election files"
  task :elections => :environment do |t, args|

    log_path = "#{Rails.root}/log/tasks"
    FileUtils.mkpath(log_path)
    lg = Logger.new File.open("#{log_path}/populate_election.log", 'a')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    # Dataset.destroy_all # only for dev

    I18n.locale = :en

    files = []
    filenames = []
    upload_path = Rails.public_path.join("upload/elections/2013")
    Dir.entries(upload_path).each {|f|
      if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
        files << "#{upload_path}/#{f}"
        filenames << f.to_s.gsub(".xlsx","")
      end
    }
    upload_path = Rails.public_path.join("upload/elections/2014")
    Dir.entries(upload_path).each {|f|
      if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
        files << "#{upload_path}/#{f}"
        filenames << f.to_s.gsub(".xlsx","")
      end
    }

    upload_path = Rails.public_path.join("upload/elections/2016")
    Dir.entries(upload_path).each {|f|
      if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
        files << "#{upload_path}/#{f}"
        filenames << f.to_s.gsub(".xlsx","")
      end
    }

    # puts files.length
    ps = []
    lg.info "----------------------------------"
    lg.info "#{files.length} - files to process (#{Time.now})"
    lg.info "----------------------------------"
    files.each_with_index {|f,f_i|
      lg.info filenames[f_i]+" >>>"

      tmp_id = filenames[f_i].split("_")
      periods = tmp_id[1].split("-")
      start_date = Date.strptime(periods[0], '%d.%m.%Y')
      end_date = Date.strptime(periods[1], '%d.%m.%Y')
      #puts "#{periods.inspect}:
      # ps |= ["#{start_date} #{end_date}"]
      tmp_id = tmp_id[0]

      prt = Party.find_by(tmp_id: tmp_id)
      per_title = "#{I18n.l(start_date, format: :filename)}_#{I18n.l(end_date, format: :filename)}"
      per = Period.find_or_create_by({ start_date: start_date, end_date: end_date, type: Period.type_is(:election)}) do |rec|
        rec.title_translations = { ka: per_title, en: per_title }
        rec.description_translations = { ka: "კამპანია #{per_title}", en: "Campaign #{per_title}" }
      end

      dataset = nil
      if prt.present? && per.present?
        if !Dataset.where({party_id: prt._id, period_id: per._id}).present?
          dataset = Dataset.new({party_id: prt._id, period_id: period_id = per._id, source: File.open(f) })
          dataset.save
          Job.dataset_file_process(dataset._id, User.all[0]._id, [])
        else
          lg.info "  - already processed"
        end
      else
        lg.info "  - party for id #{tmp_id} is missing" if prt.nil?
        lg.info "  - period for id #{year} is missing" if per.nil?
        next
      end

    }
    lg.info "----------------------------------"
    # puts ps.inspect
    lg.close
  end

  desc "Read and upload all donation files"
  task :donations => :environment do |t, args|

    log_path = "#{Rails.root}/log/tasks"
    FileUtils.mkpath(log_path)
    lg = Logger.new File.new("#{log_path}/populate_donation.log", 'w')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    # Donorset.destroy_all # only for dev

    I18n.locale = :en

    files = []
    filenames = []
    upload_path = Rails.public_path.join("upload/donors")
    Dir.entries(upload_path).each {|f|
      if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
        files << "#{upload_path}/#{f}"
        filenames << f.to_s.gsub(".xlsx","")
      end
    }

    puts files.length
    files.each_with_index {|f,f_i|
      lg.info filenames[f_i]

      donorset = Donorset.new({ source: File.open(f) })
      donorset.save
      # lg.info donorset.errors.inspect
      Job.donorset_file_process(donorset._id, User.all[0]._id)
    }
    lg.close
  end

  desc "Test if there is no dead donations (donations without donorsets)"
  task :test_dead_donations => :environment do |t, args|

    sets = {}
    Donorset.each{|d|
      sets[d._id] = 1
    }
    Donor.each{|dnr|
      dnr.donations.each {|don|
        if !sets.key?(don.donorset_id)
          puts "---------------donation without donorset found #{don.donorset_id}"
          dnr.donations.delete(don)
          dnr.save
        end
      }
    }
  end

  desc "Read and reupload party file"
  task :reparty => :environment do |t, args|

    log_path = "#{Rails.root}/log/tasks"
    FileUtils.mkpath(log_path)
    lg = Logger.new File.new("#{log_path}/reparty.log", 'w')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    I18n.locale = :ka

    lg.info "----------------------------------"
    lg.info "Reprocess parties - files to process (#{Time.now})"
    lg.info "----------------------------------"

    up_path = Rails.public_path.join("upload")

    parties_data = []
    workbook = RubyXL::Parser.parse("#{up_path}/parties.xlsx")
    workbook[0].each_with_index { |row, row_i|
      if row && row.cells
        cells = Array.new(5, nil)
        row.cells.each_with_index do |c, c_i|
          if c && c.value.present?
            cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
          end
        end
        tmp = { }
        tmp[:tmp_id] = cells[0] if cells[0].present?
        names = cells[2].split(";")
        title_ka = cells[1].present? ? cells[1] : names[0]
        pp = Party.where(title: title_ka)
        if pp.length > 1
          puts '#{title_ka} is duplicated'
          next


        end
        pp = pp.first

        # puts "#{title_ka} #{pp.inspect}"
        if pp.nil?
          lg.info "created - #{title_ka}"
          puts "created #{title_ka} #{cells[0]}"
          tmp[:title_translations] = { ka: title_ka }
          tmp[:title_translations][:en] = cells[3] if cells[3].present?
          tmp[:title_translations][:ru] = cells[4] if cells[4].present?
          tmp[:description] = "პარტია #{title_ka}"
          tmp[:name] = names
          tmp[:member] = cells[0].present?

          Party.create!(tmp)
        elsif cells[0].present?
          puts "#{cells[0]} tmp_id updated #{title_ka}"
          pp.update_attributes({tmp_id: cells[0]})
          #puts cells[0]
        end
      end
    }


    lg.close
  end



desc "Read and upload new election files from folder"
  task :reelections, [:part] => :environment do |t, args|
    part = args[:part]
    if part.present?

      log_path = "#{Rails.root}/log/tasks"
      FileUtils.mkpath(log_path)
      lg = Logger.new File.open("#{log_path}/reelections.log", 'a')
      lg.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end

      # Dataset.destroy_all # only for dev

      I18n.locale = :en

      files = []
      filenames = []
      #parts = ["07"]#, "02", "03", "04", "05", "06", "07", "08"]

      #parts.each{|part|
        upload_path = Rails.public_path.join("upload/reelections/#{part}")
        Dir.entries(upload_path).each {|f|
          if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
            files << "#{upload_path}/#{f}"
            filenames << f.to_s.gsub(".xlsx","")
          end
        }
      #}

      ps = []
      lg.info "----------------------------------"
      lg.info "#{files.length} - files to process (#{Time.now})"
      lg.info "----------------------------------"
      files.each_with_index {|f,f_i|
        lg.info filenames[f_i]+" >>>"

        tmp_id = filenames[f_i].split("_")
        periods = tmp_id[1].split("-")
        start_date = Date.strptime(periods[0], '%d.%m.%Y')
        end_date = Date.strptime(periods[1], '%d.%m.%Y')
        #puts "#{periods.inspect}:
        # ps |= ["#{start_date} #{end_date}"]
        tmp_id = tmp_id[0]

        prt = Party.find_by(tmp_id: tmp_id)
        per_title = "#{I18n.l(start_date, format: :filename)}_#{I18n.l(end_date, format: :filename)}"
        per = Period.find_or_create_by({ start_date: start_date, end_date: end_date, type: Period.type_is(:election)}) do |rec|
          rec.title_translations = { ka: per_title, en: per_title }
          rec.description_translations = { ka: "კამპანია #{per_title}", en: "Campaign #{per_title}" }
        end

        dataset = nil
        if prt.present? && per.present?
          if !Dataset.where({party_id: prt._id, period_id: per._id}).present?
            dataset = Dataset.new({party_id: prt._id, period_id: period_id = per._id, source: File.open(f), version: 2 }) #[4,5,9,10,15,23,34,36].include?(tmp_id.to_i) ? 1 :
            dataset.save
            Job.dataset_file_process(dataset._id, User.all[0]._id, [])
          else
            lg.info "  - already processed"
          end
        else
          lg.info "  - party for id #{tmp_id} is missing" if prt.nil?
          lg.info "  - period for id #{year} is missing" if per.nil?
          next
        end

      }
      lg.info "----------------------------------"
      # puts ps.inspect
      lg.close
    end
  end


  desc "Read and upload new annuals files from folder"
  task :reannuals, [:part] => :environment do |t, args|
    part = args[:part]
    if part.present?

      log_path = "#{Rails.root}/log/tasks"
      FileUtils.mkpath(log_path)
      lg = Logger.new File.open("#{log_path}/reannuals.log", 'a')
      lg.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end


      I18n.locale = :en

      files = []
      filenames = []

      upload_path = Rails.public_path.join("upload/reannuals/#{part}")
      Dir.entries(upload_path).each {|f|
        if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
          files << "#{upload_path}/#{f}"
          filenames << f.to_s.gsub(".xlsx","")
        end
      }

      ps = []
      lg.info "----------------------------------"
      lg.info "#{files.length} - files to process (#{Time.now})"
      lg.info "----------------------------------"
      files.each_with_index {|f,f_i|
        lg.info filenames[f_i]+" >>>"

        tmp_id = filenames[f_i].split(".")

        year = tmp_id[1]
        start_date =  Date.strptime("01.01.#{year}", "%d.%m.%Y")

        tmp_id = tmp_id[0]


        prt = Party.find_by(tmp_id: tmp_id)
        per_title = "#{year}"
        per = Period.find_or_create_by({start_date: start_date, type: Period.type_is(:annual)}) do |rec|
          rec.title_translations = { ka: per_title, en: per_title }
          rec.description_translations = { ka: "წლიური #{per_title}", en: "Annual #{per_title}" }
        end

        dataset = nil
        if prt.present? && per.present?
          if !Dataset.where({party_id: prt._id, period_id: per._id}).present?
            dataset = Dataset.new({party_id: prt._id, period_id: period_id = per._id, source: File.open(f), version: 2}) #[4,5,9,10,15,23,34,36].include?(tmp_id.to_i) ? 1 :
            dataset.save
            Job.dataset_file_process(dataset._id, User.all[0]._id, [])
          else
            lg.info "  - already processed"
          end
        else
          lg.info "  - party for id #{tmp_id} is missing" if prt.nil?
          lg.info "  - period for id #{year} is missing" if per.nil?
          next
        end

      }
      lg.info "----------------------------------"
      lg.close
    end
  end


end



namespace :repair do

  desc "Read and recreate category data based on versioning data"
  task :categories => :environment do |t, args|
    puts "Gather category data"
    categories_cell = []
    categories_data = []
    up_path = Rails.public_path.join("upload")
    workbook = RubyXL::Parser.parse("#{up_path}/categories.xlsx")
    cat_id = 1
    level = 0
    parenting = [nil, nil, nil, nil, nil]
    orders = [0, 0, 0, 0, 0, 0]
    parent_id = nil
    versions = [1,2]
    ln = 12 + versions.length*2

    cat_info = {}
    Category.non_virtual.each{|c|
      cat_cells = []
      cat_codes = []
      #puts "#{c.codes.inspect}   #{c.codes.inspect}"
      #puts "#{c.inspect}" if c.codes.nil?
      if c.forms.present?
        c.forms.each_with_index { |ee, ee_index|
          cat_cells << "#{ee}/#{c.cells[ee_index]}"
          cat_codes << "#{c.codes[ee_index]}" if c.codes.present?
        }
        cat_cells = cat_cells.join("&")
        cat_codes = cat_codes.join(",")
        cat_info["#{cat_cells}#{cat_codes}"] = c.id
      else
        c.destroy
        puts "<<<<<<<<<<#{c.title}"
      end
      # puts "#{cat_cells}   #{cat_codes}"
    }
    #puts "#{cat_info}"
    # puts "#{Category.non_virtual.length}#{cat_info.length}"

    workbook[0].each_with_index { |row, row_i|
      next if row_i == 0
      if row && row.cells
        cells = Array.new(ln, nil) # Level0  Level1  Level2  Level3  Level4  Cells_V1 Codes_V1 Details Short Alias ka ru Cells_V2 Codes_V2
        row.cells.each_with_index do |c, c_i|
          if c && c.value.present?
            cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
          end
        end

        has_level = false
        (0..4).step(1) { |lvl|
          if cells[lvl].present?
            if lvl > level
              orders[lvl] = 1
            else
              orders[lvl] += 1
            end
            level = lvl
            has_level = true
          end
        }
        next if !has_level

        parenting[0] = cat_id if level == 0

        parenting[level] = cat_id
        parent_id = parenting[level-1].present? && level != 0 ? parenting[level-1] : nil

        pointers = []
        #puts "--------------------------#{cells[level].strip}"
        str_cat_id = ""
        versions.each_with_index{|ver,ver_i|
          tmp_index = ver_i == 0 ? 5 : 10 + ver_i*2
          forms_and_cells = Category.parse_formula(cells[tmp_index])
          #(puts "Form or Cell or Both are empty"; exit) if forms_and_cells.nil? && ver_i == 0

          codes = Category.parse_codes(cells[tmp_index+1])
          #(puts "Code is empty";) if codes.nil? && ver_i == 0
          forms_tmp = forms_and_cells.present? ? forms_and_cells[0] : nil
          cells_tmp = forms_and_cells.present? ? forms_and_cells[1] : nil
          codes_tmp = codes.present? ? codes : nil
          pointers << { forms: forms_tmp, cells: cells_tmp, codes: codes_tmp, version: ver } if forms_tmp.present? || cells_tmp.present? || codes_tmp.present?
          str_cat_id = "#{cells[tmp_index]}#{cells[tmp_index+1]}" if ver_i == 0

        }

        dt = cells[7].present? ? cells[7] : nil
        tmp = { tmp_id: cat_id, str_cat_id: str_cat_id, virtual: false, level: level, parent_id: parent_id, title_translations: { en: cells[level].strip }.merge!(cells[10].present? ? {ka: cells[10].strip} : { }).merge!(cells[11].present? ? {ru: cells[11].strip} : { }), detail_id: dt, order: orders[level], sym: cells[9], pointers: pointers }

        categories_cell << (cells << cat_id)
        categories_data << tmp
        cat_id += 1
      end
    }

    # puts "#{categories_data.inspect}"





    puts "  Category data"
    categories_data.each_with_index do |d,i|
      tmp_id = d.delete(:tmp_id)
      str_cat_id = d.delete(:str_cat_id)

      if cat_info.key?(str_cat_id)# && !st.present?
        real_cat = Category.non_virtual.find(cat_info[str_cat_id])
        if real_cat.present?
          real_cat.update_attributes({
            title_translations: d[:title_translations],
            order: d[:order],
            pointers: d[:pointers]
          })
          puts "#{real_cat.title}___#{}"
          categories_data.each {|r| r[:parent_id] = real_cat._id if r[:parent_id] == tmp_id }
        end
        #real_cat.pointers = pointers
        # puts
      else
        puts ">>>>>>>>>>>>>#{d[:title_translations]}#{}"

        d[:detail_id] = Detail.by_code(d[:detail_id])._id if (d[:detail_id].present? && !["FF9", "FF8"].include?(d[:detail_id]))
        cat = Category.create(d)
        categories_data.each {|r| r[:parent_id] = cat._id if r[:parent_id] == tmp_id }
      end

    end

  end
end
