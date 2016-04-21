# Category class - trace party categories and sub categories
class Job
  include Mongoid::Document
  include Mongoid::Timestamps

  after_create :start_delayed_job
  # has_many :category_data
  TYPES = [:process_dataset]
  field :type, type: Integer # process_dataset
  field :user_id, type: BSON::ObjectId #
  field :related_ids, type: Array
  field :state, type: Integer, default: 0

  def start_delayed_job
    puts "start--------------------------#{self.inspect}"
    jobber
    self.state = 1
    self.save
    puts "end--------------------------#{self.inspect}"
  end

  def jobber
    puts "start--------------------------#{self.inspect}"
    puts "--------------------------jopper"
    self.state = 2
    self.save
    puts "end--------------------------#{self.inspect}"
  end
  handle_asynchronously :jobber
  # field :title, type: String, localize: true
  # field :description, type: String, localize: true
  # field :level, type: Integer
  # field :parent_id, type: BSON::ObjectId
  # field :detail_id, type: BSON::ObjectId
  # field :virtual_ids, type: Array # Array of categories that are summed up of BSON::ObjectId type
  # field :virtual, type: Boolean, default: false
  # field :complex, type: Boolean, default: false # If virtual and consist of multiple categories then true
  # #field :simple, type: Boolean, default: false
  # field :forms, type: Array
  # field :cells, type: Array
  # field :codes, type: Array
  # field :languages, type: Array
  # field :default_language, type: String
  # #field :tmp_id, type: Integer
  # field :order, type: Integer


  # index code: 1
  # index title: 1
  # index parent_id: 1
  # index simple: 1


  # def self.tree_out(vir = false, select = false, id = "categories-list")
  #   list = tree(vir)

  #   if select
  #     out = "<select id=#{id}>"
  #     list.each { |item|
  #       out += "<option order='#{item[:c].order}'>#{item[:c].title}</option>"
  #       out += sub_tree_out(item[:sub], select) if item[:sub].present?
  #     }
  #     out += "</select>"
  #   else
  #     out = "<ul id='#{id}'>"
  #     list.each { |item|
  #       out += "<li order='#{item[:c].order}'>#{item[:c].title}"
  #       out += sub_tree_out(item[:sub], select) if item[:sub].present?
  #       out += "</li>"
  #     }
  #     out += "</ul>"
  #   end
  # end
  # def self.tree(vir = false)
  #   cats = Category.all
  #   list = []
  #   cats.where({level: 0, virtual: vir}).order_by(order: :asc).each{ |cat| list << { c: cat, sub: sub_tree(cat.id, 1, vir) } }
  #   list
  # end

  # private

  # def self.sub_tree(par_id, lvl, vir = false)
  #   # puts par_id
  #   # puts lvl
  #   list = nil
  #   if lvl != 6
  #     list = []
  #     Category.where({level: lvl, parent_id: par_id, virtual: vir}).order_by(order: :asc).each{ |cat| list << { c: cat, sub: sub_tree(cat.id, lvl+1, vir)} }
  #   end
  #   list
  # end


  # def self.sub_tree_out(sub, select)
  #   list = sub
  #   out = ""
  #   if list.present?
  #     if select
  #       list.each { |item|
  #         out += "<option order='#{item[:c].order}' data-level='#{item[:c].level}'>#{item[:c].title}</option>"
  #         out += sub_tree_out(item[:sub], select) if item[:sub].present?
  #       }
  #     else
  #       out = "<ul>"
  #       list.each { |item|
  #         out += "<li order='#{item[:c].order}' class='#{item[:c].level}'>#{item[:c].title}"
  #         out += sub_tree_out(item[:sub], select) if item[:sub].present?
  #         out += "</li>"
  #       }
  #       out += "</ul>"
  #     end
  #   end
  #   out
  # end

  # def self.parse_formula(formula)
  #   t = nil
  #   if formula.present?
  #     fs = formula.strip.split("&")
  #     forms = []
  #     cells = []
  #     fs.each { |r|
  #       cls = r.split("/")
  #       return nil if cls.length != 2
  #       forms << cls[0]
  #       cells << cls[1]
  #     }
  #     t = [forms, cells]
  #   end
  #   t
  # end

  # def self.parse_codes(codes)
  #   codes.present? ? codes.to_s.strip.split(",") : nil
  # end

end
