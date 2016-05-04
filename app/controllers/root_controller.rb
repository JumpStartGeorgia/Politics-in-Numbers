# Non-resource pages
class RootController < ApplicationController
  def index
    puts "--------------------------#{new_user_session_path}"
    # @categories = Category.tree_out
    #@parties = Dataset.first
  end

  def about
    @page_content = PageContent.by_name('about')
  end

  def media
    # @page_content = PageContent.by_name('about')
  end

  def download
    # @page_content = PageContent.by_name('about')
  end

  def api
    # @page_content = PageContent.by_name('about')
  end

  def parties
    # @page_content = PageContent.by_name('about')
  end


  def read
    I18n.locale = :en
    Dataset.destroy_all
    start = Time.now
    @p = []
    upload_path = Rails.public_path.join("upload/annual")
    sheets = ["1", "2", "3", "4" , "4.1" , "4.2" , "4.3" , "4.4" , "5" , "5.1" , "5.2" , "5.3" , "5.4", "5.5", "6" , "6.1" , "7", "8", "8.1" , "9" , "9.1" , "9.2" , "9.3", "9.4" , "9.5", "9.6", "9.7", "9.7.1",  "Validation"] # 9.71 = 9.8
    sheets_abbr = ["FF1", "FF2", "FF3", "FF4" , "FF4.1" , "FF4.2" , "FF4.3" , "FF4.4" , "FF5" , "FF5.1" , "FF5.2" , "FF5.3" , "FF5.4" , "FF5.5" , "FF6" , "FF6.1" , "FF7", "FF8", "FF8.1" , "FF9" , "FF9.1" , "FF9.2" , "FF9.3", "FF9.4" , "FF9.5", "FF9.6", "FF9.7", "FF9.7.1", "V"]

    lg = Logger.new File.new('log/bad_category.log', 'w')
    lg.formatter = proc do |severity, datetime, progname, msg|

      "#{msg}\n"
    end

    files = []
    filenames = []
    Dir.entries(upload_path).each {|f|
      files << "#{upload_path}/#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
      filenames << f.to_s.gsub(".xlsx","") if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
    }


    files.each_with_index{|f,f_i|

      start_partial = Time.now
      #break if f_i == 1
      #next if !f.include? "/8.2015.xlsx"
      d("#{f}")
      lg.info "#{f}"

      tmp_id = filenames[f_i].split(".")
      prt = Party.where(tmp_id: tmp_id[0])
      per = Period.where(start_date: Date.strptime("01.01.#{tmp_id[1]}", "%d.%m.%Y"))
      dataset = nil
      if prt.present? && per.present?
        party_id = prt.first._id
        period_id = per.first._id
        dataset = Dataset.new({party_id: party_id, period_id: period_id })
        #d "#{party_id} - #{period_id}"
      else
        d("File #{filenames[f_i]}, Party for id #{tmp_id[0]} is missing") if prt.first.nil?
        d("File #{filenames[f_i]}, Period for id #{tmp_id[1]} is missing") if per.first.nil?
        next
      end

      workbook = RubyXL::Parser.parse(f)
      missed_sheets = []
      extra_sheets = []
      workbook_sheets = []
      workbook_sheets_map = {}
      error = false

      workbook.worksheets.each_with_index { |w, wi|
        sheet_id = get_sheet_id(w.sheet_name)
        workbook_sheets << sheet_id #w.sheet_name
        if sheet_id != "Validation"
          extra_sheets << w.sheet_name if !sheets.include? sheet_id
          workbook_sheets_map["FF#{sheet_id}"] = wi
        end
      }
      sheets.each_with_index { |w, wi|
        missed_sheets << w if !workbook_sheets.include? w
      }

      Category.each { |item|
        if !item.virtual
          val = 0
          item.forms.each_with_index { |form, form_i|
            puts
            cell = item.cells[form_i]
            code = item.codes && item.codes[form_i]
            if sheets_abbr.include? form
              abbr_index = sheets_abbr.index(form)
              address = RubyXL::Reference.ref2ind(cell)
              is_code = true
              if code.present?
                cd = deep_present(workbook, [workbook_sheets_map[form], address[0], 0])
                cd = cd.present? ? cd.value.to_s : ""
                if code != cd
                  lg.info("#{item.title}/#{form}/#{cell}/#{code} but is #{cd}")
                  is_code = false
                end
              end
              if is_code
                lg.info "good"
                val_tmp = deep_present(workbook, [workbook_sheets_map[form], address[0], address[1]])
                val += val_tmp.present? ? val_tmp.value.to_f : 0.0
              end

              #lg.info "#{form}#{cell}#{val}"
            else
              lg.info("Missing form #{form}")
            end
          }
          dataset.category_datas << CategoryData.new({ type: nil, value: val, category_id: item._id })
        end
      }
      # Category.each { |item|
      #   if item.virtual
      #     val = 0
      #     item.virtual_ids.each{ |id|
      #       #d(dataset.category_datas.length)
      #     }
      #     # forms.each { |form, form_i|
      #     #   cell = cells[form_i]
      #     #   code = codes[form_i]
      #     #   if sheets_abbr.include? form
      #     #     abbr_index = sheets_abbr.index(form)
      #     #     address = RubyXL::Reference.ref2ind(cell)
      #     #     val_tmp = workbook[workbook_sheets_map[form]][address[0]][address[1]]
      #     #     val += val_tmp.present? ? val_tmp.value.to_f : 0.0


      #     #     #lg.info "#{form}#{cell}#{val}"
      #     #   else
      #     #     d("Missing form #{form}")
      #     #   end
      #     # }
      #     # dataset.category_datas << CategoryData.new({ type: nil, value: val, category_id: item._id })
      #   end
      # }
      # calculate main virtual category

      Detail.each{ |item|
        next
        table = []
        next if item.code != "FF4.1"
        schemas = item.detail_schemas.order_by(order: 1)
        required = []
        has_required_or = false
        defaults = []
        types = []
        skipped = []
        header_map = []
        schemas.each do |sch|
          has_required_or = true if sch.required == :or
          required << sch.required
          defaults << sch.default_value
          types << sch.field_type
          skipped << sch.skip
          header_map << sch.orig_title
        end
        cnt = item.fields_count

        worksheet = workbook[workbook_sheets_map[item.code]]
        (lg.info "missing sheet"; next;) if worksheet.nil?
        #worksheet_to_table(worksheet)

        is_header = true
        terms = {}
        item.terminators.each{|r|
          terms[r.field_index] = [] if !terms.key?(r.field_index)
          terms[r.field_index] << r.term
        }
        #d("Terms are: #{terms.values.join(' | ')}")

        worksheet.each_with_index { |row, row_i|
          if row && row.cells
            cells = Array.new(header_map.length, nil)
            row.cells.each_with_index do |c, c_i|
              if c && c.value.present?
                cells[c_i] = c.value.class != String ? c.value : (!(c_i == 0 && c.value.to_s.strip == "...") ? c.value.to_s.strip : "" )
              end
            end

            if is_header
              if cells[0] == "N"
                lg.info cells.inspect
              end
              if cells == header_map
                lg.info "plus one"
                is_header = false
              end
            else
              begin
                or_state = 0
                good_row = true
                stop_row = false
                required.each_with_index do |r, r_i|
                  good_cell = r_i < cells.length && cells[r_i].present?
                  (stop_row = true; good_row = false; break;) if good_cell && terms.key?(r_i+1) && terms[r_i+1].any? { |t| cells[r_i].to_s.include?(t) }
                  # 11.2015 not stopping
                  next if skipped[r_i]
                  if r == :and
                    (good_row = false;) if !good_cell
                  elsif r == :or
                    or_state += 1 if good_cell
                  else

                  end
                end
                good_row = false if has_required_or && or_state == 0

                if stop_row
                  #lg.info "stop row #{cells.join('; ')}"
                  break
                else
                  if good_row
                    cells.each_with_index do |r, r_i|
                      cells[r_i] = defaults[r_i] if r.nil? && defaults[r_i].present?
                      cells[r_i] = cells[r_i].to_f if types[r_i] == "Float"
                    end
                    table << cells
                    #d("#{cells.join('; ')}")
                    #put default if needed
                  else
                    #lg.info "bad row #{cells.join('; ')}"
                  end
                end
              rescue Exception => e
                d("#{cells.inspect}exception --------------------- #{e.inspect}")
              end
            end
          end
        }

        if is_header
          d("Form header was not found. Should be #{header_map}")
          break
        else
          dd = DetailData.new({ table: table, detail_id: item._id }) if table.present?
          lg.info dd.inspect
          dataset.detail_datas << dd
        end
      }


      d("Time elapsed #{(Time.now - start_partial).round(2)} seconds")
      dataset.save!
    }
    lg.close
    d("Time elapsed #{(Time.now - start).round(2)} seconds")
  end

  def read_details
    lg = Logger.new File.new('log/skipped.log', 'w')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
    # lgg = Logger.new File.new('log/extrasheets.log', 'w')
    # lgg.formatter = proc do |severity, datetime, progname, msg|
    #   "#{msg}\n"
    # end

    @p = []
    start = Time.now
    upload_path = Rails.public_path.join("upload/annual")
    files = []
    filenames = []
    Dir.entries(upload_path).each {|f|
      files << "#{upload_path}/#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
      filenames << "#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
    }

    sheets = ["1", "2", "3", "4" , "4.1" , "4.2" , "4.3" , "4.4" , "5" , "5.1" , "5.2" , "5.3" , "5.4", "5.5", "6" , "6.1" , "7", "8", "8.1" , "9" , "9.1" , "9.2" , "9.3", "9.4" , "9.5", "9.6", "9.7", "9.7.1",  "Validation"]    # 9.71 = 9.8
    sheets_abbr = ["FF1", "FF2", "FF3", "FF4" , "FF4.1" , "FF4.2" , "FF4.3" , "FF4.4" , "FF5" , "FF5.1" , "FF5.2" , "FF5.3" , "FF5.4" , "FF5.5" , "FF6" , "FF6.1" , "FF7", "FF8", "FF8.1" , "FF9" , "FF9.1" , "FF9.2" , "FF9.3", "FF9.4" , "FF9.5", "FF9.6", "FF9.7", "FF9.7.1", "V"]
    files.each_with_index{|f,f_i|
      start_partial = Time.now
      #break if f_i == 2
      #next if !f.include? "/8.2015.xlsx"
      d("#{f}")
      lg.info "#{f}"
      workbook = RubyXL::Parser.parse(f)
      missed_sheets = []
      extra_sheets = []
      workbook_sheets = []
      workbook_sheets_map = {}
      error = false

      workbook.worksheets.each_with_index { |w, wi|
        sheet_id = get_sheet_id(w.sheet_name)
        workbook_sheets << sheet_id #w.sheet_name
        if sheet_id != "Validation"
          extra_sheets << w.sheet_name if !sheets.include? sheet_id
          workbook_sheets_map["FF#{sheet_id}"] = wi
        end
      }
      # d(workbook_sheets_map.inspect)

      sheets.each_with_index { |w, wi|
        missed_sheets << w if !workbook_sheets.include? w
      }
      # puts extra_sheets.inspect
      if missed_sheets.present? || extra_sheets.present?
        #error = true
        #d("This sheets should be in file: #{missed_sheets.join(", ")}") if missed_sheets.present?
        d("This sheets shouldn't be in file: #{extra_sheets.join(", ")}") if extra_sheets.present?
        # if extra_sheets.present?
        #   lgg.info "#{filenames[f_i]} - #{extra_sheets.join(", ")}"
        # end
      end

        @tables = []
        Detail.each{ |item|
          next if item.code != "FF1"
          schemas = item.detail_schemas.order_by(order: 1)
          required = []
          has_required_or = false
          defaults = []
          types = []
          skipped = []
          header_map = []
          schemas.each do |sch|
            has_required_or = true if sch.required == :or
            required << sch.required
            defaults << sch.default_value
            types << sch.field_type
            skipped << sch.skip
            header_map << sch.orig_title
          end
          cnt = item.fields_count

          worksheet = workbook[workbook_sheets_map[item.code]]
          (lg.info "missing sheet"; next;) if worksheet.nil?
          #worksheet_to_table(worksheet)

          is_header = true
          terms = {}
          item.terminators.each{|r|
            terms[r.field_index] = [] if !terms.key?(r.field_index)
            terms[r.field_index] << r.term
          }
          #d("Terms are: #{terms.values.join(' | ')}")

          worksheet.each_with_index { |row, row_i|
            if row && row.cells
              cells = Array.new(header_map.length, nil)
              row.cells.each_with_index do |c, c_i|
                if c && c.value.present?
                  cells[c_i] = c.value.class != String ? c.value : (!(c_i == 0 && c.value.to_s.strip == "...") ? c.value.to_s.strip : "" )
                end
              end

              if is_header
                if cells[0] == "N"
                  lg.info cells.inspect
                end
                if cells == header_map
                  lg.info "plus one"
                  is_header = false
                end
              else
                begin
                  or_state = 0
                  good_row = true
                  stop_row = false
                  required.each_with_index do |r, r_i|
                    good_cell = r_i < cells.length && cells[r_i].present?
                    (stop_row = true; good_row = false; break;) if good_cell && terms.key?(r_i+1) && terms[r_i+1].any? { |t| cells[r_i].to_s.include?(t) }
                    # 11.2015 not stopping
                    next if skipped[r_i]
                    if r == :and
                      (good_row = false;) if !good_cell
                    elsif r == :or
                      or_state += 1 if good_cell
                    else

                    end
                  end
                  good_row = false if has_required_or && or_state == 0

                  if stop_row
                    #lg.info "stop row #{cells.join('; ')}"
                    break
                  else
                    if good_row
                      cells.each_with_index do |r, r_i|
                        cells[r_i] = defaults[r_i] if r.nil? && defaults[r_i].present?
                        cells[r_i] = cells[r_i].to_f if types[r_i] == "Float"
                      end
                      #d("#{cells.join('; ')}")
                      #put default if needed
                    else
                      #lg.info "bad row #{cells.join('; ')}"
                    end
                  end
                rescue Exception => e
                  d("#{cells.inspect}exception --------------------- #{e.inspect}")
                end
              end
            end
          }

          if is_header
            d("Form header was not found. Should be #{header_map}")
            break
          end
        }

      d("Time elapsed #{(Time.now - start_partial).round(2)} seconds")
    }
    lg.close
    #lgg.close
    d("Time elapsed #{(Time.now - start).round(2)} seconds")
  end

  def read_donors

    start = Time.now
    @p = []
    lg = Logger.new File.new('log/donors.log', 'w')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    upload_path = Rails.public_path.join("upload/donors")
    files = []
    filenames = []
    Dir.entries(upload_path).each {|f|
      files << "#{upload_path}/#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
      filenames << "#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
    }

    headers_map = ["N", "თარიღი", "ფიზიკური პირის სახელი", "ფიზიკური პირის გვარი", "ფიზიკური პირის პირადი N", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ]

    Donor.destroy_all
    donors = []
    files.each_with_index{|f,f_i|
      start_partial = Time.now
      d("#{f}")
      #next if f_i != 0
      next if !f.include? "/2014.xlsx"

      workbook = RubyXL::Parser.parse(f)

      worksheet = workbook[0]
      is_header = true

      worksheet.each_with_index { |row, row_i|
        if row && row.cells
          cells = Array.new(headers_map.length, nil)
          row.cells.each_with_index do |c, c_i|
            if c && c.value.present?
              cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
            end
          end
          if is_header
            if cells == headers_map
              is_header = false
            end
          else
            begin
              break if cells[1].nil?

              p = Party.by_name(cells[6])
              #lg.info p.class == Party
              # lg.info "#{cells[6]} #{p.inspect}"
              if p.class == Party
                #lg.info "good"
              else
                if !donors.include?(cells[6])
                  donors << cells[6]
                end
              end
              # d(cells[6])
              # p =
              # d(p.inspect)
              # Donor.create!({
              #   give_date: cells[1],
              #   first_name: cells[2],
              #   last_name: cells[3],
              #   tin: cells[4],
              #   amount: cells[5],
              #   party_id: Party.by_name(cells[6])._id,
              #   comment: cells[7]
              # })

            rescue Exception => e
              d("#{cells.inspect}exception --------------------- #{e.inspect}")
              # d(cells.inspect)
            end
          end
        end
        #lgg.info cells
      }
      d("Header is missing, file is corrupted") if is_header


      d("Time elapsed #{(Time.now - start_partial).round(2)} seconds")
    }
    donors.each {|r|
      lg.info "#{r} #{Party.is_initiative(r)}"
    }
    lg.close
    d("Time elapsed #{(Time.now - start).round(2)} seconds")
  end

  def read_donors_but_parties
    donors = [
      # 2016
      'მ.პ.გ.  ერთიანი ნაციონალური მოძრაობა',
      'საქართველოს რესპუბლიკური პარტია',
      'საქართველოს პატრიოტთა ალიანსი',
      'პოლიტიკური გაერთიანება "თავისუფალი საქართველო"',
      'მ.პ.გ.  "დევნილთა პარტია"',
      'პლატფორმა ახალი პოლიტიკური ცენტრისთვის',
      'მ.პ.გ.  "ქართული ოცნება-დემოკრატიული საქართველო"',
      'ეროვნულ-დემოკრატიული პარტია',
      'ა.ა.ი.პ "გაერთიანება ბედნიერი საქართველოსთვის"',
      'მ.პ.გ.  "საქართველოს მშვიდობისათვის"',
      'პოლიტიკური გაერთიანება "მემარცხენე ალიანსი"',
      'საქართველოს რესპუბლიკური პარტია',
      'პოლიტიკური გაერთიანება "თავისუფალი საქართველო"',
      'მ.პ.გ."ქართული ოცნება-დემოკრატიული საქართველო"',
      'მ.პ.გ.ერთიანი ნაციონალური მოძრაობა',
      'მ.პ.გ."დევნილთა პარტია"',
      'საქართველოს კონსერვატიული პარტია',
      'პოლიტიკური პარტია "განახლებული საქართველოსთვის"',
      'პლატფორმა ახალი პოლიტიკური ცენტრისთვის',
      'საქართველოს პატრიოტთა ალიანსი',
      'პოლიტიკური გაერთიანება "მემარცხენე ალიანსი"',
      # 2015
      'პ.გ. "თავისუფალი საქართველო"',
      'საქართველოს რესპუბლიკური პარტია',
      'მ.პ.გ. "ქართული ოცნება-დემოკრატიული საქართველო"',
      'მ.პ.გ. ერთიანი ნაციონალური მოძრაობა',
      'მ.პ.გ. "ქართული დასი"',
      'პ.გ. "ხალხის პარტია"',
      'პ.გ. "განახლებული საქართველოსთვის"',
      'მ.პ.გ. "ქართული პარტია"',
      'საქართველოს კონსერვატიული პარტია',
      'საქართველოს პატრიოტთა ალიანსი',
      'მ.პ.გ. "ქრისტიან-დემოკრატიული სახალხო პარტია"',
      'მ.პ.გ. "თავისუფალი დემოკრატები"',
      'ეროვნულ-დემოკრატიული პარტია',
      'მ.პ.გ. "დევნილთა პარტია"',
      'პ.გ. მემარცხენე ალიანსი',
      'საქართველოს ქრისტიან-კონსერვატიული პარტია',
      'მ.პ.გ. "საქართველოს მშვიდობისათვის"',
      'პლატფორმა ახალი პოლიტიკური ცენტრისთვის',
      # 2014 this was copied from summary in donors 2014.xlsx, unlike others because
      # other was taken from actual data that is not possible in corrupted 2014 version
      'მ,პ.გ. "ქართული ოცნება-დემოკრატიული საქართველო"',
      'მ.პ.გ "გაერთიანებული დემოკრატიული მოძრაობა"',
      'მ.პ.გ.  ერთიანი ნაციონალური მოძრაობა',
      'საქართველოს პატრიოტთა ალიანსი',
      'პარტია "საქართველოს გზა"',
      'საქართველოს ქრისტიან-კონსერვატიული პარტია',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული პარტია"',
      'საქართველოს ლეიბორისტული პარტია',
      'პ.პ  "დემოკრატიული მოძრაობა-ერთიანი საქართველო"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ახალი მემარჯვენეები"',
      'საქართველოს მწვანეთა პარტია',
      'პოლიტიკური გაერთიანება "ხალხის პარტია"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "რეფორმატორები"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული დასი"',
      'ეროვნულ-დემოკრატიული პარტია',
      'მერაბ კოსტავას საზოგადოება',
      'პოლიტიკური პარტია "განახლებული საქართველოსთვის"',
      'ქრისტიან-დემოკრატიული პარტია',
      'პ.პ  "მომავალი საქართველო"',
      'პოლიტიკური პარტია "მომავალი საქართველო"',
      'საქართველოს ერთიანი კომუნისტური პარტია',
      'პოლიტიკური გაერთიანება "თავისუფალი საქართველო"',
      'საქართველოს რესპუბლიკური პარტია',
      'საინიციატივო გჯუფები',
      # 2013
      'პოლიტიკური პარტია "დემოკრატიული მოძრაობა-ერთიანი საქართველო"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული დასი"',
      'პოლიტიკური გაერთიანება "ეროვნული ფორუმი"',
      'საქართველოს კონსერვატიული პარტია',
      'პოლიტიკური გაერთიანება "თავისუფალი საქართველო"',
      'საქართველოს რესპუბლიკური პარტია',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული პარტია"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ჩვენი საქართველო თავისუფალი დემოკრატები"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული ოცნება-დემოკრატიული საქართველო"',
      'ეროვნულ-დემოკრატიული პარტია',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქრისტიან-დემოკრატიული მოძრაობა"',
      'ზვიად ჩიტიშვილის ამომრჩეველთა საინიციატივო ჯგუფი',
      'პოლიტიკური პარტია "განახლებული საქართველოსთვის"',
      'მოქალაქეთა პოლიტიკური გაერთიანება ერთიანი ნაციონალური მოძრაობა',
      'მერაბ კოსტავას საზოგადოება',
      'საქართველოს ლეიბორისტული პარტია',
      'საქართველოს მწვანეთა პარტია',
      'პოლიტიკური პარტია "მომავალი საქართველო"',
      'ლევან ჩაჩუას ამომრჩეველთა საინიციატივო ჯგუფი',
      'ქართველ ტრადიციონალისტთა კავშირი',
      'მოქალაქეთა პოლიტიკური გაერთიანება "საქართველოს ევროპელი დემოკრატები"',
      'ნუგზარ ავალიანის ამომრჩეველთა საინიციატივო ჯგუფი',
      'მოქალქეთა პოლიტიკური გაერთიანება მოძრაობა "მრეწველობა გადაარჩენს საქართველოს"',
      # 2012
      'ეროვნულ-დემოკრატიული პარტია',
      'სამართლიანობის აღდგენის კავშირი ხმა ერისა: უფალია ჩვენი სიმართლე',
      'პოლიტიკური პარტია "დემოკრატიული მოძრაობა-ერთიანი საქართველო"',
      'პოლიტიკური პარტია "განახლებული საქართველოსთვის"',
      'საზოგადოებრივი მოძრაობა „ქართული ოცნება“',
      'პოლიტიკური გაერთიანება "ერთობა რეალური იდეისათვის"',
      'საქართველოს რესპუბლიკური პარტია',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული პარტია"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ახალი მემარჯვენეები"',
      'პოლიტიკური გაერთიანება "თავისუფალი საქართველო"',
      'მოქალაქეთა პოლიტიკური გაერთიანება - საქართველოს სახალხო ფრონტი',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქრისტიან-დემოკრატიული მოძრაობა"',
      'საქართველოს კონსერვატიული პარტია',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ჩვენი საქართველო თავისუფალი დემოკრატები"',
      'მოქალაქეთა პოლიტიკური გაერთიანება ერთიანი ნაციონალური მოძრაობა',
      'პოლიტიკური გაერთიანება "ეროვნული ფორუმი"',
      'რესპუბლიკური ინსტიტუტი',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული ოცნება-დემოკრატიული საქართველო"',
      'საქართველოს მწვანეთა პარტია',
      'მ.პ. გ "დემოკრატიული განახლება ჩვენი საქართველო გაბრწყინდება" (ჩვენები)',
      'მოქალქეთა პოლიტიკური გაერთიანება მოძრაობა "მრეწველობა გადაარჩენს საქართველოს"',
      'ა(ა)იპ "საქართველო არ იყიდება"',
      'საქართველოს ლეიბორისტული პარტია',
      'ვლადიმერ ვახანიას ამომრჩეველთა საინიციატივო ჯგუფი',
      'პოლიტიკური პარტია "მომავალი საქართველო"',
      'ალექსი შოშიკელაშვილის ამომრჩეველთა საინიციატივო ჯგუფი',
      'მოქალაქეთა პოლიტიკური გაერთიანება "სოციალ-დემოკრატები საქართველოს განვითარებისათვის"',
      'მოქალაქეთა პოლიტიკური გაერთიანება "მთლიანი საქართველო"',
      'მერაბ კოსტავას საზოგადოება',
      'ა(ა)იპ "მომავალი დღეს "',
      'ა(ა)იპ "მოძრაობა ამომრჩეველთა ლიგა "',
      'მოქალაქეთა პოლიტიკური გაერთიანება "ქართული დასი"'
    ]
    lg = Logger.new File.new('log/donors.log', 'w')
    lg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end
    lgg = Logger.new File.new('log/extrasheets.log', 'w')
    lgg.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    @p = []
    start = Time.now
    upload_path = Rails.public_path.join("upload/donors")
    files = []
    filenames = []
    Dir.entries(upload_path).each {|f|
      files << "#{upload_path}/#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
      filenames << "#{f}" if File.file?("#{upload_path}/#{f}") && f != ".gitkeep"
    }
    #raise RuntimeError, "#{files.join(', ')}"
    # map = {
    #   "2016" => [4, 5],
    #   "2015"=> [27, 28],
    #   "2014"=> [31, 32],
    #   "2013"=> [30,31],
    #   "2012"=> [38, 39]
    # }
    # donors = [] # for generating unique party names from donor files
    headers_map = ["N", "თარიღი", "ფიზიკური პირის სახელი", "ფიზიკური პირის გვარი", "ფიზიკური პირის პირადი N", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ]
    #
    # sheets = ["ფორმა N1", "ფორმა N2", "ფორმა N3" , "ფორმა N4", "ფორმა N4.1", "ფორმა N4.2", "ფორმა N4.3", "ფორმა 4.4", "ფორმა N5", "ფორმა N5.1",  "ფორმა N5.2",  "ფორმა N5.3", "ფორმა N5.4", "ფორმა N6", "ფორმა N6.1", "ფორმა N7", "ფორმა N8", "ფორმა N 8.1", "ფორმა N9", "ფორმა N9.1", "ფორმა N9.2", "ფორმა N9.3", "ფორმა N9.4", "ფორმა N9.5", "ფორმა N9.6", "ფორმა N9.7", "ფორმა N9.7.1", "Validation"]
    # 9.71 = 9.8
    # sheets = ["1", "2", "3", "4" , "4.1" , "4.2" , "4.3" , "4.4" , "5" , "5.1" , "5.2" , "5.3" , "5.4", "5.5", "6" , "6.1" , "7", "8", "8.1" , "9" , "9.1" , "9.2" , "9.3", "9.4" , "9.5", "9.6", "9.7", "9.7.1",  "Validation"]
    # sheets_abbr = ["FF1", "FF2", "FF3", "FF4" , "FF4.1" , "FF4.2" , "FF4.3" , "FF4.4" , "FF5" , "FF5.1" , "FF5.2" , "FF5.3" , "FF5.4" , "FF5.5" , "FF6" , "FF6.1" , "FF7", "FF8", "FF8.1" , "FF9" , "FF9.1" , "FF9.2" , "FF9.3", "FF9.4" , "FF9.5", "FF9.6", "FF9.7", "FF9.7.1", "V"]
    #
    #
    lgg.info donors.length
    donors.uniq!
    lgg.info donors.length

    dn = {}
    donors.each_with_index do |d,d_i|
      dn[d_i]= { id: d_i, orig: d.clone }
      d.gsub!("მოქალაქეთა პოლიტიკური გაერთიანება","")
      d.gsub!("პოლიტიკური გაერთიანება","")
      d.gsub!("პოლიტიკური პარტია","")
      d.gsub!("მ.პ.გ.","")
      d.gsub!("მ,პ.გ.","")
      d.gsub!("მ.პ.გ","")
      d.gsub!("მ.პ. გ ","")
      d.gsub!("პ.გ.","")
      d.gsub!("პ.პ","")
      d.gsub!("ა.ა.ი.პ","")
      d.gsub!("ა(ა)იპ","")
      d.gsub!("- ","")
      d.gsub!("  ","")
      d.gsub!("\"","")
      dn[d_i][:clean] = d.strip
      dn[d_i][:used] = false
      # donors[d_i] =
      #lgg.info  dn[d_i][:clean] #map {|x| x[:clean] } #donors[d_i]
    end

    dn.each{|k, v|
      next if dn[k][:used]
      dn.each{|kk,vv|
        next if dn[kk][:used]
        if k != kk && vv[:clean] == v[:clean]
          if !dn[k][:same_ids].present?
            dn[k][:same_ids] = [kk]
          else
            dn[k][:same_ids] << kk
          end
          dn[kk][:used] = true
        end
      }
      dn[k][:used] = true
      dn[k][:empty] = true if dn[k][:same_ids].nil?
    }

    dnn = {}
    in_cnt = 0
    dn.each{|k, v|
      if v.key?(:same_ids) || v[:empty].present?
        dnn[k] = v
        str = "#{v[:clean]}\t"
        str += "#{v[:orig]}\t"
        if v[:same_ids].present?
          in_cnt += v[:same_ids].length + 1
          dnn[k][:origs] = [v[:orig]]
          v[:same_ids].each{|sid|
            str += "#{dn[sid][:orig]}\t"
            dnn[k][:origs] << dn[sid][:orig]
          }
        else
          in_cnt += 1
        end
        lgg.info str
      end
    }
    lgg.info in_cnt
    #lgg.info dnn.inspect


    files.each_with_index{|f,f_i|
      # break
      start_partial = Time.now
      #next if f_i != 3
      next if !f.include? "/2014.xlsx"
      d("#{f}")
      lg.info "#{f}"
      lgg.info "#{f}"
      workbook = RubyXL::Parser.parse(f)

      # spl = filenames[f_i].gsub(".xlsx", '').split("_")
      # mt = map.key?(spl[0]) ? [1,2] : map[spl[0]]

      worksheet = workbook[0]
      is_header = true

      worksheet.each_with_index { |row, row_i|
        if row && row.cells
          cells = Array.new(headers_map.length, nil)
          row.cells.each_with_index do |c, c_i|
            if c && c.value.present?
              cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
            end
          end
          if is_header
            if cells == headers_map
              d("Header row found")
              is_header = false
            end
          else
            begin
              # for generating unique party names from donor files
                # pname = cells[6].strip
                # if !donors.include? pname
                #   d("#{pname}")
                #   donors << pname
                #   lg.info pname
                # end
              # Donor.create!({
              #   give_date: cells[1],
              #   first_name: cells[2],
              #   last_name: cells[3],
              #   tin: cells[4],
              #   amount: cells[5],
              #   party_id: Party.by_name(cells[7])._id,
              #   comment: cells[7]
              # })
            rescue Exception => e
              d("#{cells.inspect}exception --------------------- #{e.inspect}")
              # d(cells.inspect)
            end
          end
        end
        lgg.info cells
      }




      d("Time elapsed #{(Time.now - start_partial).round(2)} seconds")
    }
    lg.close
    lgg.close
    d("Time elapsed #{(Time.now - start).round(2)} seconds")
  end
end

# worksheet_header && worksheet_header.each{|cell|
#   d(cell && cell.value)
# }
# tmp = workbook[item.orig_code][address[0]][address[1]]
#     val = tmp.present? ? tmp.value.to_f : 0.0
#     if ind == 0
#       cells_value = val if ind == 0
#     else
#       oper = operations[ind-1]
#       if oper == "+"
#         cells_value = cells_value + val
#       elsif oper = "-"
#         cells_value = cells_value - val
#       end
#     end
