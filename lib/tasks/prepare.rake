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
      p.unset_slug!
      p.save
    }
    Party.each { |p|
      p.unset_slug!
      p.save
    }
    Period.each { |p|
      p.unset_slug!
      p.save
    }
    Category.each { |p|
      p.unset_slug!
      p.save
    }
  end

  desc "Create sequence collection used by shortener"
  task :create_sequence_collection => :environment do |t, args|
    db = Mongoid.default_client
    db.command({ create: "sequence" })
  end

  desc "Drop sequence collection used by shortener"
  task :drop_sequence_collection => :environment do |t, args|
    db = Mongoid.default_client
    s = db.command({ listCollections: 1, filter: { name: "sequence" }  })
    db.command({ drop: "sequence" }) if s.documents[0]["cursor"]["firstBatch"].present?
    #
  end

  desc "Create sequence document for explore and embed_static used by shortener"
  task :populate_sequence => :environment do |t, args|
    db = Mongoid.default_client
    db.command({ insert: "sequence", documents: [ { _id: "explore_id", seq: 1000000000000000000 } ] })
    db.command({ insert: "sequence", documents: [ { _id: "embed_static_id", seq: 2000000000000000000 } ] })
  end

  desc "Recreate sequence collection and document for explore and embed_static used by shortener"
  task :resequence => :environment do |t, args|
    Rake::Task["prepare:drop_sequence_collection"].invoke
    Rake::Task["prepare:create_sequence_collection"].invoke
    Rake::Task["prepare:populate_sequence"].invoke
  end

  desc "Truncate ShortUri and recreate explore and embed_static sequence"
  task :reset_shorturi => :environment do |t, args|
    ShortUri.destroy_all
    Rake::Task["db:mongoid:remove_undefined_indexes"].invoke
    Rake::Task["prepare:resequence"].invoke
  end
  # WARNING call slug generator function for Category, Donor, Party, Period

end
