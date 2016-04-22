# Donorset - trace category and detail data for party
# based on specific period
class Donorset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  after_create :before_process_job

  STATES = [:pending, :processed, :discontinued]

  embeds_many :donors
  # embeds_many :detail_datas
  #belongs_to :party

  field :state, type: Integer, default: 0 # 0 pending 1 processed 2 discontinued

  has_mongoid_attached_file :source, :path => ':attachment/:id/:style.:extension'


  validates_attachment :source, presence: true, content_type: { content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }, size: { in: 0..25.megabytes }
  validates_inclusion_of :state, in: [0, 1, 2]

  def self.sorted
    order_by([[:created_at, :desc]])
  end
  def set_state(tp)
    st = STATES.index(tp.to_sym)
    self.state = st if st.present?
    self.save
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

  def before_process_job
    puts "------------------------Before preparation on donorset"
    process_job
    puts "------------------------After preparation on donorset"
  end

  def process_job
    lg = Delayed::Worker.logger
    headers_map = ["N", "თარიღი", "ფიზიკური პირის სახელი", "ფიზიკური პირის გვარი", "ფიზიკური პირის პირადი N", "შემოწირ. თანხის ოდენობა", "პარტიის დასახელება", "შენიშვნა" ]

    missing_party = []
    workbook = RubyXL::Parser.parse(source.path)
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

            party = cells[6]
            p = Party.by_name(party)
            if p.class != Party
              clean_name = Party.clean_name(party)
              p = Party.create!({ name: clean_name, title: clean_name, description: "პარტია #{clean_name}", tmp_id: -99, type: Party.type_is(:initiative) })
              missing_party << p._id if !missing_party.include?(party)
            end

            d = Donor.new({ give_date: cells[1], first_name: cells[2],
              last_name: cells[3], tin: cells[4], amount: cells[5],
              party_id: p._id, comment: cells[7] })

            self.donors << d
          rescue Exception => e
            # d(cells.inspect)
          end
        end
      end
    }
    begin
      if is_header
        self.set_state(:discontinued)
        # lg.info "Header is missing, file is corrupted"
      else
        self.save
        self.set_state(:processed)
        missing_party.each {|r|
          lg.info "#----------- {r} #{Party.is_initiative(r)}"
        }
      end
    rescue Exception => e
      self.set_state(:discontinued)
      #puts "-------------------------exception #{e.inspect}"
    end
  end
  handle_asynchronously :process_job, :priority => 0

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
