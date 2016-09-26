namespace :prepare do # WARNING ondeploy
  desc "For each party set member flag "
  task :set_party_member_flag => :environment do |t, args|
    Party.each{|p|
      if p.tmp_id.present?
        p.member = true
        p.save
      end
    }
  end
  desc "For each donor save, for full_name to be filled"
  task :reset_slugs => :environment do |t, args|
    Donor.each { |p|
      p.clear_slug!
      p.build_slug
      p.save
    }
    Party.each { |p|
      p.clear_slug!
      p.build_slug
      p.save
    }
    Period.each { |p|
      p.clear_slug!
      p.build_slug
      p.save
    }
    Category.each { |p|
      p.clear_slug!
      p.build_slug
      p.save
    }
  end
  # WARNING call slug generator function for Category, Donor, Party, Period
end
