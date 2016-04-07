# Category class - trace party categories and sub categories
class Category < CustomTranslation
  include Mongoid::Document
  include Mongoid::Timestamps

  # has_many :category_data

  field :code, type: String
  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :parent_id, type: BSON::ObjectId
  field :level, type: Integer
  field :simple, type: Boolean, default: false
  field :virtual, type: Boolean, default: false
  field :detail_id, type: BSON::ObjectId
  field :form, type: String
  field :cell, type: String
  field :languages, type: Array
  field :default_language, type: String
  field :tmp_id, type: Integer


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

  def self.tree_out
    list = tree
    out = "<ul>"
    list.each { |item|
      out += "<li>#{item[:c].title}</li>"
      out += sub_tree_out(item[:sub]) if item[:sub].present?
    }
    out += "</ul>"
  end
  def self.tree
    cats = Category.all
    list = []
    cats.where({level: 0}).each{ |cat| list << { c: cat, sub: sub_tree(cat.tmp_id, 1) } }
    list
  end

  private

  def self.sub_tree(par_id, lvl)
    puts par_id
    puts lvl
    list = nil
    if lvl != 6
      list = []
      Category.where({level: lvl, parent_id: par_id}).each{ |cat| list << { c: cat, sub: sub_tree(cat.tmp_id, lvl+1)} }
    end
    list
  end


  def self.sub_tree_out(sub)
    list = sub
    out = "<li>"
    list.each { |item|
      cat = item[:s]
      if item[:sub].present?
        out += "<ul>"
        out += "<li>#{item[:c].title}</li>"
        out += sub_tree_out(item[:sub])
        out += "</ul>"
      end
    }
    out += "</li>"
  end

end
