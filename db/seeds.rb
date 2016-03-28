# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).

# roles = %w(super_admin site_admin content_manager)
# roles.each do |role|
#   Role.find_or_create_by(name: role)
# end



puts "Creating categories and it/'s subcategories"
cats = [
  {
    title: "Income", cells: "FF2/C9+FF3/C9", simple: 1
  }
]

cats.each{|d,i|
  Category.create!(d) #.map { |k, v| [k.to_s, v.to_s] }.to_h
  puts "Category #{d[:title]} was added"
}
