# Donorset - trace category and detail data for party
# based on specific period
class Donorset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

#   after_create :before_process_job

  STATES = [:pending, :processed, :discontinued]

  embeds_many :donors
  # embeds_many :detail_datas
  #belongs_to :party

  field :state, type: Integer, default: 0 # 0 pending 1 processed 2 discontinued
  field :del, type: Boolean, default: false

  default_scope ->{ where(del: false) }

#         Band.unscoped.where(name: "Depeche Mode")
# Band.unscoped do
#   Band.where(name: "Depeche Mode")
# end

  has_mongoid_attached_file :source, :path => ':attachment/:id/:style.:extension'


  validates_attachment :source, presence: true, content_type: { content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }, size: { in: 0..25.megabytes }
  validates_inclusion_of :state, in: [0, 1, 2]

  def self.sorted
    order_by([[:created_at, :desc]])
  end
  def set_state(tp)
    st = STATES.index(tp.to_sym)
    if st.present?
      puts "-------------set_state #{self.inspect}"
      self.state = st
      puts "-------------set_state #{self.valid?} #{self.errors.inspect}"
      puts " -------- #{self.save}"
    end
  end
  def self.is_type(tp)
    begin
      tp.to_i < TYPES.length
    rescue
      false
    end
  end
  # def party
  #   @party = Party.find(party_id)
  # end

  # def period
  #   @period = Period.find(period_id)
  # end

  # def party_name
  #   @party = party if @party.nil?
  #   @party.title
  # end

  # def period_name
  #   @period = period if @period.nil?
  #   @period.title
  # end

  def current_state
    I18n.t("mongoid.options.donorset.state.#{STATES[state].to_s}")
  end

  # def before_process_job
  #   puts "------------------------Before preparation on donorset"
  #   process_job
  #   puts "------------------------After preparation on donorset"
  # end

  # def process_job
  #   begin
  #     puts "user infoooooooooooooooooooooo #{current_user.inspect}"
  #     puts "-------------------------"
  #     lg = Delayed::Worker.logger
  #     headers_map = ["N", "თარიღი", "ფიზიკური პირის სახელი", "ფიზიკური პირის გვარი", "ფიზიკური პირის პირადი N", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ]

  #     missing_parties = []
  #     workbook = RubyXL::Parser.parse(source.path)
  #     worksheet = workbook[0]
  #     is_header = true
  #     raise Exception.new("some")
  #     worksheet.each_with_index { |row, row_i|
  #       if row && row.cells
  #         cells = Array.new(headers_map.length, nil)
  #         row.cells.each_with_index do |c, c_i|
  #           if c && c.value.present?
  #             cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
  #           end
  #         end
  #         if is_header
  #           if cells == headers_map
  #             is_header = false
  #            # puts "-----------------#{cells.inspect}"
  #           end
  #         else
  #           # puts "-----------------nil #{row_i}" if cells[1].nil?
  #           break if cells[1].nil?
  #           party = cells[6]
  #           #lg.info "-----------------------------------#{party}"
  #           p = Party.by_name(party)
  #           if p.class != Party
  #             #lg.info "-----------------------------------#{party} no party"
  #             clean_name = Party.clean_name(party)
  #             missing_parties.each{|mp| (p = mp; break;) if mp.name == clean_name }
  #             if p.class != Party
  #               #lg.info "-----------------------------------#{party} no party saved"
  #               #puts "It is not party second"
  #               p = Party.new({ name: clean_name, title: clean_name, description: "საინიციატივო ჯგუფი #{clean_name}", tmp_id: -99, type: Party.type_is(:initiative) })

  #               if p.valid?
  #                 missing_parties << p
  #                 #puts "Party creating"
  #                 lg.info missing_parties.length
  #               else
  #                 raise Exception.new("Party '#{clean_name}', name is invalid check row #{row_i} in excel, and make sure it has party name")
  #               end
  #             else
  #               #puts "Party was already created"
  #             end
  #           else
  #             #puts "Party is there"
  #           end

  #           self.donors << Donor.new({ give_date: cells[1], first_name: cells[2],
  #             last_name: cells[3], tin: cells[4], amount: cells[5],
  #             party_id: p._id, comment: cells[7] })
  #         end
  #       end
  #     }

  #     if is_header
  #       raise Exception.new("Header in provided file is distinct, compare to expected one.")
  #     else
  #       self.save
  #       missing_parties.each {|mp| mp.save }
  #       self.set_state(:processed)
  #     end

  #   rescue Exception => e
  #     self.set_state(:discontinued)
  #     Notification.about_donorset_creating_fail(e.message, current_user.id)
  #     #puts "-------------------------exception #{e.inspect}"
  #   end
  # end
  # handle_asynchronously :process_job, :priority => 1

 # def self.states
 #    col = {}
 #    STATES.each_with_index{|d, i|
 #      col[I18n.t("mongoid.options.donorset.type.#{d}")] = i
 #    }
 #    col
 #  end

 #  def self.state_is(tp)
 #    STATES.index(tp.to_sym)
 #  end

 #  def self.is_state(tp)
 #    begin
 #      tp.to_i < STATES.length
 #    rescue
 #      false
 #    end
 #  end

end



def read_donors


  end
