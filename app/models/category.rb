# Category class - trace party categories and sub categories
class Category < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  # has_many :category_data

  field :code, type: String
  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :level, type: Integer
  field :parent_id, type: BSON::ObjectId
  field :detail_id, type: BSON::ObjectId
  field :virtual_ids, type: Array # Array of categories that are summed up of BSON::ObjectId type
  field :virtual, type: Boolean, default: false
  #field :simple, type: Boolean, default: false
  field :form, type: String
  field :cell, type: String
  field :languages, type: Array
  field :default_language, type: String
  #field :tmp_id, type: Integer
  field :order, type: Integer


  index code: 1
  index title: 1
  index parent_id: 1
  index simple: 1

  def title
    puts get_translation(title_translations)
    get_translation(title_translations)
  end

  def description
    get_translation(description_translations)
  end

  def self.tree_out(vir = false, select = false, id = "categories-list")
    list = tree(vir)

    if select
      out = "<select id=#{id}>"
      list.each { |item|
        out += "<option order='#{item[:c].order}'>#{item[:c].title}</option>"
        out += sub_tree_out(item[:sub], select) if item[:sub].present?
      }
      out += "</select>"
    else
      out = "<ul id='#{id}'>"
      list.each { |item|
        out += "<li order='#{item[:c].order}'>#{item[:c].title}"
        out += sub_tree_out(item[:sub], select) if item[:sub].present?
        out += "</li>"
      }
      out += "</ul>"
    end
  end
  def self.tree(vir = false)
    cats = Category.all
    list = []
    cats.where({level: 0}).order_by(order: :asc).each{ |cat| list << { c: cat, sub: sub_tree(cat.id, 1, vir) } }
    list
  end

  private

  def self.sub_tree(par_id, lvl, vir = false)
    # puts par_id
    # puts lvl
    list = nil
    if lvl != 6
      list = []
      Category.where({level: lvl, parent_id: par_id, virtual: vir}).order_by(order: :asc).each{ |cat| list << { c: cat, sub: sub_tree(cat.id, lvl+1, vir)} }
    end
    list
  end


  def self.sub_tree_out(sub, select)
    list = sub
    out = ""
    if list.present?
      if select
        list.each { |item|
          out += "<option order='#{item[:c].order}' data-level='#{item[:c].level}'>#{item[:c].title}</option>"
          out += sub_tree_out(item[:sub], select) if item[:sub].present?
        }
      else
        out = "<ul>"
        list.each { |item|
          out += "<li order='#{item[:c].order}' class='#{item[:c].level}'>#{item[:c].title}"
          out += sub_tree_out(item[:sub], select) if item[:sub].present?
          out += "</li>"
        }
        out += "</ul>"
      end
    end
    out
  end

end
