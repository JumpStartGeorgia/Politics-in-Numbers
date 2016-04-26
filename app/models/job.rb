class Job
  # Those are two &lt; symbols (the blog is screwing them up)
  class << self
    def _donorset_file_process(item_id, user_id)
      begin
        # puts "user infoooooooooooooooooooooo #{@donorset.inspect} #{@user.inspect}"
        # puts "_method"
        notifiers = [:user]
        @donorset = Donorset.find(item_id)
        @user = User.find(user_id)

        (raise Exception.new("Donorset to process was not found, probably you request to delete it.");) if @donorset.nil?
        (raise Exception.new("Operator not found, send to nowhere.");) if @user.nil?

        headers_map = ["N", "თარიღი", "ფიზიკური პირის სახელი", "ფიზიკური პირის გვარი", "ფიზიკური პირის პირადი N", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ]

        lg = Delayed::Worker.logger

        workbook = RubyXL::Parser.parse(@donorset.source.path)
        worksheet = workbook[0]
        is_header = true
        missing_parties = []
        # raise Exception.new("some")
        worksheet.each_with_index { |row, row_i|
          if row && row.cells
            cells = Array.new(headers_map.length, nil)
            row.cells.each_with_index do |c, c_i|
              if c && c.value.present?
                cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
              end
            end
            if is_header
              is_header = false if cells == headers_map
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
                    raise Exception.new("Party '#{clean_name}', name is invalid check row #{row_i} in excel, and make sure it has party name")
                  end
                end
              end
              donor = Donor.new({ give_date: cells[1], first_name: cells[2],
                last_name: cells[3], tin: cells[4], amount: cells[5],
                party_id: p._id, comment: cells[7] })
              puts "#{donor.errors.inspect}" if !donor.valid?
              @donorset.donors << donor
            end
          end
        }

        if is_header
          raise Exception.new("Header in provided file is distinct, compare to expected one #{headers_map}.")
        else
          # @donorset.save
          if missing_parties.present?
            missing_parties.each {|mp| mp.save; }
            @user.deffereds << Deffered.new({ type: Deffered.type_is(:bulk_parties), user_id: @user._id, related_ids: missing_parties.map{|r| r._id }});
            #puts "--------------------------#{@user.inspect}"
            @user.save
          end
          puts "======================= point1"
          @donorset.set_state(:processed)
          puts "======================= point2"
          Notifier.about_donorset_file_process("File #{@donorset.source_file_name} was successfully processed. To view processed data follow the <a href='#'>link</a>.", @user);
          puts "======================= point3"
        end

      rescue Exception => e
        @donorset.destroy if @donorset.present?
        Notifier.about_donorset_file_process(e.message, @user);
      end
    end
    handle_asynchronously :_donorset_file_process, :priority => 1
  end

  # My importer as a class method
  def self.donorset_file_process(item_id, user_id)
    Job._donorset_file_process(item_id, user_id)
  end
end
