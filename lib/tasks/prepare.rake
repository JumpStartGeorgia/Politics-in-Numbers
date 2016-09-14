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
end
