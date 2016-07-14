# Category class - trace party categories and sub categories
class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  # has_many :category_data

  field :title, type: String, localize: true
  field :description, type: String, localize: true
  field :level, type: Integer
  field :parent_id, type: BSON::ObjectId
  field :detail_id, type: BSON::ObjectId
  field :virtual_ids, type: Array # Array of categories that are summed up of BSON::ObjectId type
  field :virtual, type: Boolean, default: false
  field :complex, type: Boolean, default: false # If virtual and consist of multiple categories then true
  #field :simple, type: Boolean, default: false
  field :forms, type: Array
  field :cells, type: Array
  field :codes, type: Array
  field :languages, type: Array
  field :default_language, type: String
  #field :tmp_id, type: Integer
  field :order, type: Integer
  field :sym, type: Symbol

  scope :virtual, ->{ where(virtual: true) }
  scope :non_virtual, ->{ where(virtual: false) }
  scope :only_sym, ->{ where(:sym.ne => nil) }

  index code: 1
  index title: 1
  index parent_id: 1
  #index simple: 1
  SYMS = [ :income, :income_campaign, :expenses, :expenses_campaign, :reform_expenses, :property_assets, :financial_assets, :debts ]

  def self.full_names(cats, ids)
    names = []
    ids.each{|e|
      cat = cats[e]
      rev = [cat[:title]]
      while(cat[:parent_id].present?)
        cat = cats[cat[:parent_id]]
        rev.unshift(cat[:title])
      end
      names << rev.join(' - ')
      names << rev.join(' - ')
    }
    return names
  end

  def self.by_sym(cats, sym = nil, vir = false)
    out = {}
    d = tree_local(cats.to_a, vir, sym)
    d.each { |item|
      out[item[:c][:sym]] = by_sym_helper(item[:sub], true) if item[:sub].present?
    }
    out
  end


  # def self.by_sym(sym = nil, vir = false)
  #   out = {}
  #   d = tree(vir, sym)
  #   d.each { |item|
  #     out[item[:c][:sym]] = by_sym_helper(item[:sub], true) if item[:sub].present?
  #   }
  #   out
  # end
  def self.tree_local(cats, vir = false, sym = nil)
    list = []
    cats.select{|s| s.level == 0 }.sort { |x,y| x.order <=> x.order }.each{|cat|
      list << { c: cat, sub: sub_tree_local(cats, cat.id, 1, vir) }
    }
    list
  end
  def self.sub_tree_local(cats, par_id, lvl, vir = false)
    # puts par_id
    # puts lvl
    list = nil
    if lvl != 6
      list = []
      cats.select{|s| s.level == lvl && s.parent_id == par_id && s.virtual == vir }.sort { |x,y| x.order <=> x.order }.each{ |cat|
        list << { c: cat, sub: sub_tree_local(cats, cat.id, lvl+1, vir)} }
    end
    list
  end


  def self.tree(vir = false, sym = nil)
    cats = Category.all
    list = []
    cats.where({level: 0, virtual: vir}.merge!( sym.present? ? { sym: sym } : {} )).order_by(order: :asc).each{ |cat| list << { c: cat, sub: sub_tree(cat.id, 1, vir) } }
    list
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
        has_sub = item[:sub].present?
        info = []
        item[:c].forms.each_with_index{|f, i| info << "#{f}/#{item[:c].cells[i]}/#{item[:c].codes[i] if item[:c].codes.present?}" } if item[:c].forms.present?
        out += "<li order='#{item[:c].order}'><div class='box#{has_sub ? ' inner' : '' }'><label>#{item[:c].title}</label><div class='info'>#{ info.join(', ')}</div></div>"
        out += sub_tree_out(item[:sub], select) if has_sub
        out += "</li>"
      }
      out += "</ul>"
    end
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
          has_sub = item[:sub].present?
          info = []
          item[:c].forms.each_with_index{|f, i| info << "#{f}/#{item[:c].cells[i]}/#{item[:c].codes[i] if item[:c].codes.present?}" } if item[:c].forms.present?
          out += "<li order='#{item[:c].order}' class='#{item[:c].level}'><div class='box#{has_sub ? ' inner' : '' }'><label>#{item[:c].title}</label><div class='info'>#{info.join(', ')}</div></div>"
          out += sub_tree_out(item[:sub], select) if has_sub
          out += "</li>"
        }
        out += "</ul>"
      end
    end
    out
  end

  def self.by_sym_helper(sub, first)
    list = sub
    out = ""
    if list.present?
        out = "<ul>" if !first
        list.each { |item|
          has_sub = item[:sub].present?
          out += "<li class='l#{item[:c].level}#{has_sub ? ' collapse' : ''}' tabindex='5'>#{has_sub ? '<div class=\'tree-toggle\'></div>' : ''}<div class='item' data-id='#{item[:c].id}'>#{item[:c].title}</div>"
          out += by_sym_helper(item[:sub], false) if has_sub
          out += "</li>"
        }
        out += "</ul>" if !first
    end
    out
  end

  def self.parse_formula(formula)
    t = nil
    if formula.present?
      fs = formula.strip.split("&")
      forms = []
      cells = []
      fs.each { |r|
        cls = r.split("/")
        return nil if cls.length != 2
        forms << cls[0]
        cells << cls[1]
      }
      t = [forms, cells]
    end
    t
  end

  def self.parse_codes(codes)
    codes.present? ? codes.to_s.strip.split(",") : nil
  end

end
