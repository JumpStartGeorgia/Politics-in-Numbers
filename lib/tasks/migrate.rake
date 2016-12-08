namespace :migrate do # WARNING ondeploy
  desc "Apply soft_titleize to donor first and last name "
  task :apply_soft_titleize_to_donors => :environment do |t, args|
    Donor.each{|d|
      f = {}
      d.first_name_translations.each do |k,v|
        if v.present?
          f[k] = v.soft_titleize
        end
      end
      d.first_name_translations = f if f.present?

      l = {}
      d.last_name_translations.each do |k,v|
        if v.present?
          l[k] = v.soft_titleize
        end

      end
      d.last_name_translations = l if l.present?

      d.save if d.changed?
    }
  end

  desc "Apply soft_titleize to initiative parties title, and fill if missing for en and ru"
  task :apply_soft_titleize_to_parties => :environment do |t, args|
    Party.where({type: 1}).each{|d|
      f = {}
      d.title_translations.each do |k,v|
        if v.present?
          f[k] = v.soft_titleize
        end
      end
      f["en"] = f["ka"].latinize.soft_titleize if !d.title_translations.key?("en")
      f["ru"] = f["ka"].latinize.soft_titleize if !d.title_translations.key?("ru")

      d.title_translations = f if f.present?

      d.save if d.changed?
    }
  end
end
