class Job
  # Those are two &lt; symbols (the blog is screwing them up)
  class << self
    def _dataset_file_process(item_id, user_id, links)
      #lg = Delayed::Worker.logger
      lg = Logger.new File.new('log/category.log', 'a')
      lg.formatter = proc do |severity, datetime, progname, msg|
        "#{msg}\n"
      end
      begin
        @dataset = Dataset.find(item_id)
        @user = User.find(user_id)

        (raise Exception.new(I18n.t("notifier.job.dataset_file_process.dataset_not_found"))) if @dataset.nil?
        (raise Exception.new(I18n.t("notifier.job.dataset_file_process.operator_not_found"));) if @user.nil?

        sheets = ["1", "2", "3", "4" , "4.1" , "4.2" , "4.3" , "4.4" , "5" , "5.1" , "5.2" , "5.3" , "5.4", "5.5", "6" , "6.1" , "7", "8", "8.1" , "9" , "9.1" , "9.2" , "9.3", "9.4" , "9.5", "9.6", "9.7", "9.7.1",  "Validation"] # 9.71 = 9.8
        sheets_abbr = ["FF1", "FF2", "FF3", "FF4" , "FF4.1" , "FF4.2" , "FF4.3" , "FF4.4" , "FF5" , "FF5.1" , "FF5.2" , "FF5.3" , "FF5.4" , "FF5.5" , "FF6" , "FF6.1" , "FF7", "FF8", "FF8.1" , "FF9" , "FF9.1" , "FF9.2" , "FF9.3", "FF9.4" , "FF9.5", "FF9.6", "FF9.7", "FF9.7.1", "V"]

        workbook = RubyXL::Parser.parse(@dataset.source.path)
        missed_sheets = []
        extra_sheets = []
        workbook_sheets = []
        workbook_sheets_map = {}

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
        lg.info "----------------------------------"
        lg.info "File: #{@dataset.source_file_name}"
        lg.info "Extra sheets: #{extra_sheets.join(', ')}" if extra_sheets.present?
        lg.info "Missing sheets: #{missed_sheets.join(', ')}" if missed_sheets.present?
        good_codes = 0
        cell_refs = 0
        Category.non_virtual.each { |item|
          val = 0
          item.forms.each_with_index { |form, form_i|
            cell_refs += 1
            cell = item.cells[form_i]
            code = item.codes && item.codes[form_i]
            if sheets_abbr.include? form
              #abbr_index = sheets_abbr.index(form)
              address = RubyXL::Reference.ref2ind(cell)
              is_code = true
              if code.present?
                cd = deep_present(workbook, [workbook_sheets_map[form], address[0], 0])
                cd = cd.present? ? cd.value.to_s : ""
                if code != cd

                  lg.info("#{item.title}/#{form}/#{cell}/#{code} but is #{cd}") if !missed_sheets.map{|r| "FF#{r}"}.include?(form)
                  is_code = false
                end
              end
              if is_code
                val_tmp = deep_present(workbook, [workbook_sheets_map[form], address[0], address[1]])
                val += val_tmp.present? ? val_tmp.value.to_f : 0.0
                good_codes += 1
              end
              #lg.info "#{form}#{cell}#{val}"
            else
              lg.info "Missing form: #{form}"
            end
          }
          @dataset.category_datas << CategoryData.new({ value: val, category_id: item._id })
        }
        lg.info "Category codes: #{good_codes}/#{cell_refs}"

        virtual_category_datas = []
        Category.virtual.each {|item|
          val = 0
          item.virtual_ids.each {|virtual_id|
            d = @dataset.category_datas.where({category_id: virtual_id}).first
            val += d.value if d.present?
          }
          virtual_category_datas << CategoryData.new({ value: val, category_id: item._id })
        }
        @dataset.category_datas << virtual_category_datas

        lg.info "Virtual Categories: #{virtual_category_datas.length}"

        Detail.each{ |item|
          table = []
          #next if item.code != "FF4.1"
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
          next if worksheet.nil?

          is_header = true
          terms = {}
          item.terminators.each{|r|
            terms[r.field_index] = [] if !terms.key?(r.field_index)
            terms[r.field_index] << r.term
          }

          worksheet.each_with_index { |row, row_i|
            if row && row.cells
              cells = Array.new(header_map.length, nil)
              row.cells.each_with_index do |c, c_i|
                if c && c.value.present?
                  cells[c_i] = c.value.class != String ? c.value : (!(c_i == 0 && c.value.to_s.strip == "...") ? c.value.to_s.strip : "" )
                end
              end

              if is_header
                # if cells[0] == "N"
                #   lg.info cells.inspect
                # end
                if cells == header_map
                  # lg.info "plus one"
                  is_header = false
                end
              else
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

                break if stop_row

                if good_row
                  cells.each_with_index do |r, r_i|
                    cells[r_i] = defaults[r_i] if r.nil? && defaults[r_i].present?
                    cells[r_i] = cells[r_i].to_f if types[r_i] == "Float"
                  end
                  table << cells
                else
                  lg.info "bad row #{cells.join('; ')}"
                end

              end
            end
          }

          if is_header
            lg.info "Form header was not found. Should be #{item.code}/#{header_map}"
            break
          else
            dd = DetailData.new({ table: table, detail_id: item._id }) if table.present?
            #lg.info dd.inspect
            @dataset.detail_datas << dd
          end
        }
        @dataset.set_state(:processed)
        lg.close
      rescue Exception => e
        @dataset.destroy if @dataset.present?
        lg.info e.inspect
        Notifier.about_dataset_file_process(e.message, @user);
      end
    end
    handle_asynchronously :_dataset_file_process, :priority => 1

    def _donorset_file_process(item_id, user_id, links)
      begin
        # notifiers = [:user]
        # lg = Delayed::Worker.logger
        lg = Logger.new File.new('log/donorset.log', 'a')
        lg.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
        lg.info "----------------------------------start"
        @donorset = Donorset.find(item_id)
        donors = []
        @user = User.find(user_id)
        (raise Exception.new(I18n.t("notifier.job.donorset_file_process.donorset_not_found"))) if @donorset.nil?
        (raise Exception.new(I18n.t("notifier.job.donorset_file_process.operator_not_found"));) if @user.nil?
        lg.info "----------------------------------1"
        headers_map = [
          ["N", "თარიღი", "ფიზიკური პირის სახელი", "ფიზიკური პირის გვარი", "ფიზიკური პირის პირადი N", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ],
          ["N", "თარიღი", "სახელი/ სამართლებრივი ფორმა", "გვარი / იურიდიული პირის დასახელება", "პირადი ნომერი / საიდ. კოდი", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ]
        ]


        lg.info "----------------------------------1"
        workbook = RubyXL::Parser.parse(@donorset.source.path)
        worksheet = workbook[0]
        is_header = true
        missing_parties = []
        # raise Exception.new("some")
        worksheet.each_with_index { |row, row_i|
          if row && row.cells
            cells = Array.new(headers_map[0].length, nil)
            row.cells.each_with_index do |c, c_i|
              if c && c.value.present?
                cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
              end
            end
            if is_header
              is_header = false if headers_map.any?{|hm| hm == cells }
            else
              break if cells[1].nil?
              party = cells[6]
              p = Party.by_name(party)
              if p.class != Party
                clean_name = Party.clean_name(party)
                missing_parties.each{|mp| (p = mp; break;) if mp.name == clean_name }
                if p.class != Party
                  p = Party.new({ name: clean_name, title: clean_name, description: "საინიციატივო ჯგუფი #{clean_name}", tmp_id: -99, type: Party.type_is(:initiative) })
                  if p.valid?
                    missing_parties << p
                  else
                    raise Exception.new(I18n.t("notifier.job.donorset_file_process.invalid_party_name", name: clean_name, row: row_i))
                  end
                end
              end
              donor = Donor.by_tin(cells[4]).first
              if !donor.present?
                donor = Donor.new({ first_name_translations: { ka: cells[2], en: cells[2].latinize.capitalize }, last_name_translations: { ka: cells[3], en: cells[3].latinize.capitalize }, tin: cells[4], nature: cells[3].present? ? 0 : 1 }) # individual or organization
              end
              donation = Donation.new({ give_date: cells[1], amount: cells[5].round(2), party_id: p._id, comment: cells[7], monetary: cells[7] != "არაფულადი",
              donorset_id: @donorset.id })
              donor.donations << donation
              donors << donor
              #@donorset.donations << donor.donations
            end
          end
        }
        lg.info "----------------------------------2 #{is_header}"
        if is_header
          raise Exception.new(I18n.t("notifier.job.donorset_file_process.unmatched_header", header: headers_map))
        else
          @donorset.save
          donors.each{|t| t.save }
          deffered = nil
          if missing_parties.present?
            missing_parties.each {|mp| mp.save; }
            deffered = Deffered.new({ type: Deffered.type_is(:parties_type_correction), user_id: @user._id, related_ids: missing_parties.map{|r| r._id }})
            @user.deffereds << deffered
            @user.save
          end
          @donorset.set_state(:processed)

          Notifier.about_donorset_file_process(
            I18n.t("notifier.job.donorset_file_process.success",
              filename: @donorset.source_file_name,
              link: links[0].gsub("_id", @donorset.id),
              missing_parties: deffered.present? ? I18n.t("notifier.job.donorset_file_process.missing_parties", link: links[1].gsub("_id", deffered.id)) : ""
            ),
            @user)
        end

      rescue Exception => e
        @donorset.destroy if @donorset.present?
        lg.info e.inspect
        puts "-------------------------------#{e.backtrace}"
        Notifier.about_donorset_file_process(e.message, @user);
      end
    end
    handle_asynchronously :_donorset_file_process, :priority => 1

    def get_sheet_id(sheet_name)
      tmp = sheet_name.gsub 'ფორმა', ''
      tmp.gsub! 'N', ''
      tmp.gsub! ' ', ''
      tmp
    end
    def deep_present(parent, tree)
      p = parent
      tree.each {|d|
        p = p[d].present? ? p[d] : nil
        break if p.nil?
      }
      p
    end
  end



  def self.dataset_file_process(item_id, user_id, links)
    Job._dataset_file_process(item_id, user_id, links)
  end

  def self.donorset_file_process(item_id, user_id, links)
    Job._donorset_file_process(item_id, user_id, links)
  end

end
