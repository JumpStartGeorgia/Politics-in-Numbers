# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).



def is_numeric?(obj)
   obj.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
end

I18n.locale = :ka
destroy_mode = true
up_path = Rails.public_path.join("upload")

if destroy_mode
  puts "Destroy phase ----------------------"
  puts "  languages"
  Language.destroy_all
  puts "  page_content"
  PageContent.destroy_all
  puts "  party data"
  Party.destroy_all
  puts "  period data"
  Period.destroy_all
  puts "  detail and its schema, with all embed documents"
  Detail.destroy_all
  puts "  category data"
  Category.destroy_all
  # puts "  role data"
  # Role.destroy_all
  # puts "  user data"
  # User.destroy_all
  puts "Destroy phase end ------------------"

end


#####################
## Languages
#####################
puts 'loading languages'
if (Language.count == 0)
  langs = [
    ["ka", "ქართული"],
    ["en", "English"],
    ["ru", "Русский"]
  ]

  langs = langs.map{|x| {locale: x[0], name: x[1]}}
  Language.collection.insert_many(langs)
end

roles = %w(super_admin site_admin content_manager)
roles.each do |role|
  Role.find_or_create_by(name: role)
end

## Create app user and api key
#####################
email = 'application@mail.com'
if User.where(email: email).count == 0
  puts 'Creating app user and api key'
  #User.where(email: email).destroy
  u = User.new(email: email, password: Devise.friendly_token[0,30], role_id: 0)#, is_user: false)
  u.save(validate: false)
  #u.api_keys.create
end

email = 'antarya@gmail.com'
if User.where(email: email).count == 0
  puts 'Creating antarya user'
  #User.where(email: email).destroy
  u = User.new(email: email, encrypted_password: "$2a$10$/bJUUzr2GhJRj6WyojabVO4rGS/xwPQGgTlmazxfdmNz82cEftWQC", role_id: Role.first._id)#, is_user: false)
  u.save(validate: false)
  #u.api_keys.create
end


# puts "Populate page content data"
# PageContent.create(name: 'about', title_translations: {'en' => 'About', 'ka' => 'about'}, content_translations: {
#   'en' =>  %q(
#     <div class="section">
#       <h1>Methodology</h1>
#       <div class="content">
#         <div class="column">
#           <label>Donations</label>
#           <p>lorem ipsum</p>
#         </div>
#         <div class="column">
#           <label>Party Finances</label>
#           <p>lorem ipsum</p>
#         </div>
#       </div>
#     </div>
#     <div class="section">
#       <h1>Sponsors</h1>
#       <div class="content">
#         <a href="#"><img src="js.jpg"></a>
#         <a href="#js"><img src="js.jpg"></a>
#       </div>
#     </div>
#   ),
#   'ka' => ''}) if PageContent.by_name('about').nil?

PageContent.create(name: 'about_donations', title_translations: {'en' => 'Donations', 'ka' => 'Donations'}, content_translations: {
  'en' => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. In diam arcu, ornare in tortor sed, tincidunt accumsan eros. Quisque tempor, diam bibendum tempor aliquet, elit tortor vestibulum metus, non molestie orci purus id ipsum. Donec in maximus turpis. Sed dapibus odio nec ligula mattis, id efficitur mauris auctor. Cras suscipit, enim rutrum placerat fermentum, elit sapien elementum nisl, at scelerisque nunc orci sed risus. Integer quis condimentum leo, sit amet posuere neque. Vestibulum porta sollicitudin quam at ornare. Nunc sit amet pharetra magna, vitae congue leo. Integer eu ultrices lectus, pellentesque porttitor nisl. Duis elementum aliquet tempor. Integer nec ante sit amet erat porta condimentum. Nullam ac enim sagittis, pharetra urna vel, sagittis tellus.</p><p>Mauris tempus, enim in lobortis venenatis, nisi lacus convallis nibh, eget sollicitudin leo eros ac eros. Vestibulum ac nisl nisl. Duis a lorem justo. Nulla facilisi. Pellentesque blandit lorem in posuere lacinia. Aliquam erat volutpat. Proin pharetra vehicula ex sit amet pretium. Sed at justo at augue imperdiet eleifend eu nec arcu. Sed porttitor urna ac sem feugiat consequat. Duis eu nunc arcu. </p>',
  'ka' => '<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. In diam arcu, ornare in tortor sed, tincidunt accumsan eros. Quisque tempor, diam bibendum tempor aliquet, elit tortor vestibulum metus, non molestie orci purus id ipsum. Donec in maximus turpis. Sed dapibus odio nec ligula mattis, id efficitur mauris auctor. Cras suscipit, enim rutrum placerat fermentum, elit sapien elementum nisl, at scelerisque nunc orci sed risus. Integer quis condimentum leo, sit amet posuere neque. Vestibulum porta sollicitudin quam at ornare. Nunc sit amet pharetra magna, vitae congue leo. Integer eu ultrices lectus, pellentesque porttitor nisl. Duis elementum aliquet tempor. Integer nec ante sit amet erat porta condimentum. Nullam ac enim sagittis, pharetra urna vel, sagittis tellus.</p><p>Mauris tempus, enim in lobortis venenatis, nisi lacus convallis nibh, eget sollicitudin leo eros ac eros. Vestibulum ac nisl nisl. Duis a lorem justo. Nulla facilisi. Pellentesque blandit lorem in posuere lacinia. Aliquam erat volutpat. Proin pharetra vehicula ex sit amet pretium. Sed at justo at augue imperdiet eleifend eu nec arcu. Sed porttitor urna ac sem feugiat consequat. Duis eu nunc arcu. </p>'}
) if PageContent.by_name('about_donations').nil?

PageContent.create(name: 'about_party_finances', title_translations: {'en' => 'Party Finances', 'ka' => 'Party Finances'}, content_translations: {
  'en' => '<p>Mauris tempus, enim in lobortis venenatis, nisi lacus convallis nibh, eget sollicitudin leo eros ac eros. Vestibulum ac nisl nisl. Duis a lorem justo. Nulla facilisi. Pellentesque blandit lorem in posuere lacinia. Aliquam erat volutpat. Proin pharetra vehicula ex sit amet pretium. Sed at justo at augue imperdiet eleifend eu nec arcu. Sed porttitor urna ac sem feugiat consequat. Duis eu nunc arcu. </p>',
  'ka' => '<p>Mauris tempus, enim in lobortis venenatis, nisi lacus convallis nibh, eget sollicitudin leo eros ac eros. Vestibulum ac nisl nisl. Duis a lorem justo. Nulla facilisi. Pellentesque blandit lorem in posuere lacinia. Aliquam erat volutpat. Proin pharetra vehicula ex sit amet pretium. Sed at justo at augue imperdiet eleifend eu nec arcu. Sed porttitor urna ac sem feugiat consequat. Duis eu nunc arcu. </p>'}
) if PageContent.by_name('about_party_finances').nil?


# PageContent.create(name: 'home', title_translations: {'en' => 'Home page', 'ka' => 'Home page'}, content_translations: {
#   'en' => '<p>Do you want to know where the political parties get money from? Politics in Numbers has all the official data about the party finances. You can see and compare political party income and expenses, campaign funds, donations, assets, financial obligations and other interesting details.</p>',
#   'ka' => '<p>გაინტერესებს, საიდან იღებენ და რაში ხარჯავენ პოლიტიკური პარტიები ფულს? “პოლიტიკა რიცხვებში” აერთიანებს ყველა ოფიციალურ მონაცემს პოლიტიკური პარტიების დაფინანსების შესახებ. შეგიძლია, ნახო და შეადარო პარტიების შემოსავლები და ხარჯები, კამპანიის ფონდები, შემოწირულებები, ქონება, ვალები და სხვა საინტერესო დეტალები.</p>',
#   'ru' => '<p>Откуда получают и на что тратят деньги политические партии? Узнайте и сравните доходы и расходы, во сколько обходится предвыборная кампания, какие пожертвования получают, каким имуществом обладают и какие заработали долги.Ответы на интересующие вас вопросы в проекте «Политика в цифрах». Мы составили для вас единую базу данных. Здесь всё о финансировании политических объединений в Грузии. Статистика составлялась согласно официальным источникам.</p>'}
# ) if PageContent.by_name('home').nil?




puts "Gather category data"
categories_cell = []
categories_data = []
workbook = RubyXL::Parser.parse("#{up_path}/categories.xlsx")
cat_id = 1
level = 0
parenting = [nil, nil, nil, nil, nil]
orders = [0, 0, 0, 0, 0, 0]
parent_id = nil
workbook[0].each_with_index { |row, row_i|
  next if row_i == 0
  if row && row.cells
    cells = Array.new(12, nil) # Level0  Level1  Level2  Level3  Level4  Cells Codes Details Short Alias ka ru
    row.cells.each_with_index do |c, c_i|
      if c && c.value.present?
        cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
      end
    end

    has_level = false
    (0..4).step(1) { |lvl|
      if cells[lvl].present?
        if lvl > level
          orders[lvl] = 1
        else
          orders[lvl] += 1
        end
        level = lvl
        has_level = true
      end
    }
    next if !has_level

    parenting[0] = cat_id if level == 0

    parenting[level] = cat_id
    parent_id = parenting[level-1].present? && level != 0 ? parenting[level-1] : nil

    forms_and_cells = Category.parse_formula(cells[5])
    (puts "Form or Cell or Both are empty"; exit) if forms_and_cells.nil?

    codes = Category.parse_codes(cells[6])
    (puts "Code is empty";) if codes.nil?

    dt = cells[7].present? ? cells[7] : nil
    tmp = { tmp_id: cat_id, virtual: false, level: level, parent_id: parent_id, forms: forms_and_cells[0], cells: forms_and_cells[1], codes: codes, title_translations: { en: cells[level].strip }.merge!(cells[10].present? ? {ka: cells[10].strip} : { }).merge!(cells[11].present? ? {ru: cells[11].strip} : { }), detail_id: dt, order: orders[level], sym: cells[9] }
    categories_cell << (cells << cat_id)
    categories_data << tmp
    cat_id += 1
  end
}

puts "Gather virtual category data"
virtuals_data = []
cat_id = 1
level = 0
parenting = [nil, nil]
orders = [0, 0]
parent_id = nil
others = []
categories_cell.each_with_index { |cells, row_i|
    next if !(cells[8].present? && is_numeric?(cells[8]))
    virt = cells[8]
    (others << cells[12]; next; ) if virt == 99

    val = ""
    has_level = false
    (0..4).step(1) { |lvl|
      if cells[lvl].present?
        val = cells[lvl]
        if lvl == 0
          if row_i != 0
            virtuals_data << { tmp_id: cat_id, virtual: true, complex: true, level: 1, parent_id: parenting[0], virtual_ids: others, title_translations: { en: "Other", ka: "Other ka", ru: "Other ru" }, order: orders[1]+1, sym: cells[9] }
            cat_id += 1
          end
          others = []
          orders[0] += 1
          orders[1] = 0
          level = 0
        else
          orders[1] += 1 if lvl >= level
          level = 1
        end
        has_level = true
      end
    }
    next if !has_level


    parenting[level] = cat_id
    parent_id = parenting[level-1].present? && level != 0 ? parenting[level-1] : nil

    forms_and_cells = Category.parse_formula(cells[5])
    (puts "Form or Cell or Both are empty"; exit) if forms_and_cells.nil?

    codes = Category.parse_codes(cells[6])
    (puts "Code is empty";) if codes.nil?

    dt = cells[7].present? ? cells[7] : nil
    tmp = { tmp_id: cat_id, virtual: true, level: level, parent_id: parent_id, virtual_ids: [cells[9]], title_translations: { en: val.strip,  ka: (cells[10].present? ? cells[10].strip : nil), ru: (cells[11].present? ? cells[11].strip : nil) }, detail_id: dt, order: orders[level], sym: cells[9] }
    virtuals_data << tmp
    cat_id += 1
}
virtuals_data << { tmp_id: cat_id, virtual: true, complex: true, level: 1, parent_id: parenting[0], forms: nil, cells: nil, title_translations: { en: "Other", ka: "Other ka", ru: "Other ru" }, order: orders[1]+1, virtual_ids: others } if others.present?
# virtuals_data.each {|r|
#   puts "#{'  '*r[:level]}#{r[:title_translations][:en]} #{r[:tmp_id]} #{r[:parent_id]} #{r[:order]} #{r[:virtual_ids].inspect}"
# }



parties_data = []
workbook = RubyXL::Parser.parse("#{up_path}/parties.xlsx")
workbook[0].each_with_index { |row, row_i|
  if row && row.cells
    cells = Array.new(5, nil)
    row.cells.each_with_index do |c, c_i|
      if c && c.value.present?
        cells[c_i] = c.value.class != String ? c.value : c.value.to_s.strip
      end
    end
    tmp = { }
    tmp[:tmp_id] = cells[0] if cells[0].present?
    tmp[:title_translations] = { ka: (cells[1].present? ? cells[1] : cells[2]) }
    tmp[:title_translations][:en] = cells[3] if cells[3].present?
    tmp[:title_translations][:ru] = cells[4] if cells[4].present?
    tmp[:description] = "პარტია #{cells[1].present? ? cells[1] : cells[2]}"
    tmp[:name] = cells[2]

    parties_data << tmp
  end
}
#puts parties_data.inspect



periods_data = [
  # type 'annual' 'election'
  { type: Period.type_is(:annual), start_date: '01.01.2012', end_date: '31.01.2012', title_translations: { ka: "2012" }, description_translations: { ka: "2012 description" }},
  { type: Period.type_is(:annual), start_date: '01.01.2013', end_date: '31.01.2013', title_translations: { ka: "2013" }, description_translations: { ka: "2013 description" }},
  { type: Period.type_is(:annual), start_date: '01.01.2014', end_date: '31.01.2014', title_translations: { ka: "2014" }, description_translations: { ka: "2014 description" }},
  { type: Period.type_is(:annual), start_date: '01.01.2015', end_date: '31.01.2015', title_translations: { ka: "2015" }, description_translations: { ka: "2015 description" }},
  { type: Period.type_is(:election), start_date: '01.01.2015', end_date: '31.03.2015', title_translations: { ka: "election 2015" }, description_translations: { ka: "election 2015" }},
  { type: Period.type_is(:election), start_date: '01.01.2016', end_date: '31.03.2016', title_translations: { ka: "election 2016" }, description_translations: { ka: "election 2016" }}
  #{ type: 'election', start_date: '01.01.2015', end_date: '31.03.2015', title_translations: { ka: "2015 election" }, description_translations: { ka: "2015 election description" }}
]

details_data = [
  { code: "FF1", orig_code: "ფორმა N1", header_row: 8, content_row: 10, fields_count: 13, footer: 0, title_translations: { ka: "საწევრო შენატანები და შემოწირულებები" }},
  { code: "FF4.1", orig_code: "ფორმა N4.1", header_row: 9, content_row: 10, fields_count: 4, footer: 1, note: [1], title_translations: { ka: "სხვადასხვა ხარჯებისა და სხვა დანარჩენი საქონლისა და მომსახურების" } },
  { code: "FF4.2", orig_code: "ფორმა N4.2", header_row: 8, content_row: 9, fields_count: 9, footer: 1, title_translations: { ka: "ხელფასები, პრემიები" }},
  { code: "FF4.3", orig_code: "ფორმა N4.3", header_row: 8, content_row: 9, fields_count: 8, footer: 1, title_translations: { ka: "მივლინებები" }},
  { code: "FF4.4", orig_code: "ფორმა N4.4", header_row: 8, content_row: 9, fields_count: 8, footer: 1, title_translations: { ka: "სხვა განაცემები ფიზიკურ პირებზე (ხელფასის და პრემიის გარდა)" }},
  { code: "FF5.1", orig_code: "ფორმა N4.1", header_row: 9, content_row: 10, fields_count: 4, footer: 1, note: [1, 2], title_translations: { ka: "სხვადასხვა ხარჯებისა და სხვა დანარჩენი საქონლისა და მომსახურების" }},
  { code: "FF5.2", orig_code: "ფორმა N5.2", header_row: 8, content_row: 9, fields_count: 8, footer: 1, note: [1], title_translations: { ka: "ხელფასები, პრემიები" }},
  { code: "FF5.3", orig_code: "ფორმა N5.3", header_row: 8, content_row: 9, fields_count: 8, footer: 1, note: [1], title_translations: { ka: "მივლინებები" }},
  { code: "FF5.4", orig_code: "ფორმა N5.4", header_row: 8, content_row: 9, fields_count: 8, footer: 1, note: [1], title_translations: { ka: "სხვა განაცემები ფიზიკურ პირებზე (ხელფასის და პრემიის გარდა)" }},
  { code: "FF5.5", orig_code: "ფორმა N5.5", header_row: 9, content_row: 10, fields_count: 12, footer: 1, note: [4], title_translations: { ka: "რეკლამის ხარჯი" }},
  { code: "FF6.1", orig_code: "ფორმა N6.1", header_row: 9, content_row: 10, fields_count: 4, footer: 1, note: [1, 2], title_translations: { ka: "სსიპ 'საარჩევნო სისტემების განვითარების, რეფორმებისა და სწავლების ცენტრიდან' მიღებული  სახსრებით გაწეული სხვა ხარჯების" }},
  #{ code: "FF8", orig_code: "ფორმა N8", header_row: 8, content_row: 10, fields_count: 7, footer: 1, title_translations: { ka: "ნაღდი ფულით განხორციელებულ სალაროს ოპერაციათა რეესტრი" }},
  { code: "FF8.1", orig_code: "ფორმა N8.1", header_row: 8, content_row: 10, fields_count: 7, footer: 1, title_translations: { ka: "ნაღდი ფულით განხორციელებულ სალაროს ოპერაციათა რეესტრი" }},
  #{ code: "FF9", orig_code: "ფორმა N9", header_row: 7, content_row: 9, fields_count: 8, footer: 0, title_translations: { ka: "შენობა-ნაგებობების რეესტრი" }},
  { code: "FF9.1", orig_code: "ფორმა N9.1", header_row: 7, content_row: 9, fields_count: 8, footer: 0, title_translations: { ka: "შენობა-ნაგებობების რეესტრი" }},
  { code: "FF9.2", orig_code: "ფორმა N9.2", header_row: 7, content_row: 9, fields_count: 9, footer: 0,  title_translations: { ka: "სატრანსპორტო საშუალებების რეესტრი" }},
  { code: "FF9.3", orig_code: "ფორმა N9.3", header_row: 7, content_row: 9, fields_count: 7, footer: 0, title_translations: { ka: "მოხალისეთა აქტივობების რეესტრი" }},
  { code: "FF9.4", orig_code: "ფორმა N9.4", header_row: 7, content_row: 9, fields_count: 11, footer: 0, title_translations: { ka: "იჯარით/ქირით აღებული უძრავი ქონების რეესტრი" }},
  { code: "FF9.5", orig_code: "ფორმა N9.5", header_row: 7, content_row: 9, fields_count: 12, footer: 0, title_translations: { ka: "იჯარით/ქირით აღებული სატრანსპორტო საშუალებების რეესტრი" }},
  { code: "FF9.6", orig_code: "ფორმა N9.6", header_row: 7, content_row: 9, fields_count: 9, footer: 0, title_translations: { ka: "იჯარით/ქირით აღებული სხვა მოძრავი ქონების რეესტრი" }},
  { code: "FF9.7", orig_code: "ფორმა N9.7", header_row: 8, content_row: 9, fields_count: 9, footer: 1, title_translations: { ka: "ვალდებულებების რეესტრი" }},
  { code: "FF9.7.1", orig_code: "ფორმა N9.7.1", header_row: 7, content_row: 9, fields_count: 13, footer: 1, title_translations: { ka: "საარჩევნო პერიოდში აღებული სესხი/კრედიტი" }}
]

detail_schemas_data = [
  [ # 1
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", title_translations: { ka: "N" }, skip: true },
    { field_type: "Date", order: 1, output_order: 1, orig_title: "ოპერაციის თარიღი", title_translations: { ka: "ოპერაციის თარიღი" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "შემოსავლის ტიპი *", title_translations: { ka: "შემოსავლის ტიპი" }, note: [1] },
    { field_type: "Float", order: 3, output_order: 3, orig_title: "თანხა / ღირებულება (ლარებში)", title_translations: { ka: "თანხა / ღირებულება (ლარებში)" }, footer: :sum},
    { field_type: "String", order: 4, output_order: 4, orig_title: "ფიზიკური პირის სახელი და გვარი / იურიდიული პირის დასახელება", title_translations: { ka: "ფიზიკური პირის სახელი და გვარი / იურიდიული პირის დასახელება" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "პირადი ნომერი / საიდ. კოდი", title_translations: { ka: "პირადი ნომერი / საიდ. კოდი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "შემომწირავის საბანკო ანგარიშის ნომერი", title_translations: { ka: "შემომწირავის საბანკო ანგარიშის ნომერი" }},
    { field_type: "String", order: 7, output_order: 7, orig_title: "შემომწირავის ბანკი", title_translations: { ka: "შემომწირავის ბანკი" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "ქონების აღწერილობა ****", title_translations: { ka: "არაფულადი ფორმით ქონების აღწერილობა" }, note: [3,4] },
    { field_type: "String", order: 9, output_order: 9, orig_title: "მომსახურების მოკლე აღწერილობა", title_translations: { ka: "არაფულადი ფორმით მომსახურების მოკლე აღწერილობა"}, note: [3] },
    { field_type: "String", order: 10, output_order: 10, orig_title: "რაოდენობა/ მოცულობა", title_translations: { ka: "არაფულადი ფორმით რაოდენობა/ მოცულობა"}, note: [3] },
    { field_type: "String", order: 11, output_order: 11, orig_title: "დამატებითი ინფორმაცია", title_translations: { ka: "დამატებითი ინფორმაცია" }}
  ],
  [ # 4.1
    { field_type: "String", order: 1, output_order: -1, orig_title: "N", title_translations: { ka: "N" }},
    { field_type: "String", default_value: "დაუზუსტებელი", order: 2, output_order: 2, orig_title: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით", title_translations: { ka: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით" }}, # this is required but has default
    { field_type: "Float", default_value: 0, order: 3, output_order: -3, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, note: [2], title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", required: :and, default_value: 0, order: 4, output_order: 4, orig_title: "საკასო ხარჯი", footer: :sum, note: [2], title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 4.2
    { field_type: "String", order: 1, output_order: -1, skip: true, orig_title: "N", title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "პირადი ნომერი", title_translations: { ka: "პირადი ნომერი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "პოზიცია", title_translations: { ka: "პოზიცია" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "განაცემის ტიპი", title_translations: { ka: "განაცემის ტიპი" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }},
    { field_type: "Float", order: 9, output_order: 9, orig_title: "გადახდის წყაროსთან დაკავებული საშემოსავლო გადასახადი", footer: :sum, title_translations: { ka: "გადახდის წყაროსთან დაკავებული საშემოსავლო გადასახადი" }}
  ],
  [ # 4.3
    { field_type: "String", order: 1, output_order: 1, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "პირადი ნომერი", title_translations: { ka: "პირადი ნომერი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "მივლინების დანიშნულება", title_translations: { ka: "მივლინების დანიშნულება" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "მივლინების ადგილი", title_translations: { ka: "მივლინების ადგილი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "მივლინების პერიოდი (დღეებში)", title_translations: { ka: "მივლინების პერიოდი (დღეებში)" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 4.4
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "პირადი ნომერი", title_translations: { ka: "პირადი ნომერი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "განაცემის ტიპი", title_translations: { ka: "განაცემის ტიპი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "თვე", title_translations: { ka: "თვე" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 5.1
    { field_type: "String", order: 1, output_order: -1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", default_value: "დაუზუსტებელი", order: 2, output_order: 2, orig_title: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით", title_translations: { ka: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით" }}, # this is required but has default
    { field_type: "Float", default_value: 0, order: 3, output_order: -3, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, note: [2], title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", required: :and, default_value: 0, order: 4, output_order: 4, orig_title: "საკასო ხარჯი", footer: :sum, note: [2], title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 5.2
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "პოზიცია", title_translations: { ka: "პოზიცია" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "განაცემის ტიპი", title_translations: { ka: "განაცემის ტიპი" }},
    { field_type: "Float", order: 6, output_order: 6, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "გადახდის წყაროსთან დაკავებული საშემოსავლო გადასახადი", title_translations: { ka: "გადახდის წყაროსთან დაკავებული საშემოსავლო გადასახადი" }}
  ],
  [ # 5.3
    { field_type: "String", order: 1, output_order: 1, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "პირადი ნომერი", title_translations: { ka: "პირადი ნომერი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "მივლინების დანიშნულება", title_translations: { ka: "მივლინების დანიშნულება" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "მივლინების ადგილი", title_translations: { ka: "მივლინების ადგილი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "მივლინების პერიოდი (დღეებში)", title_translations: { ka: "მივლინების პერიოდი (დღეებში)" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 5.4
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "პირადი ნომერი", title_translations: { ka: "პირადი ნომერი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "განაცემის ტიპი", title_translations: { ka: "განაცემის ტიპი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "თვე", title_translations: { ka: "თვე" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 5.5
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "რეკლამის ფორმა", title_translations: { ka: "რეკლამის ფორმა" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "შემსრულებელი კომპანია/პირი", title_translations: { ka: "შემსრულებელი კომპანია/პირი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "საიდენტიფიკაციო ნომერი", title_translations: { ka: "საიდენტიფიკაციო ნომერი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "რეკლამის დამკვეთი*", note: [1], title_translations: { ka: "რეკლამის დამკვეთი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "ტირაჟი/ხანგრძლივობა", title_translations: { ka: "ტირაჟი/ხანგრძლივობა" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფართობი**", note: [2], title_translations: { ka: "ფართობი" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "რეკლამირებული სუბიექტი****", note: [3], title_translations: { ka: "რეკლამირებული სუბიექტი" }},
    { field_type: "String", order: 9, output_order: 9, orig_title: "ერთეულის ტიპი (კვ.მ.; წუთი...)", title_translations: { ka: "ერთეულის ტიპი (კვ.მ.; წუთი...)" }},
    { field_type: "Float", order: 10, output_order: 10, orig_title: "ერთეულის ღირებულება (ლარი)", title_translations: { ka: "ერთეულის ღირებულება (ლარი)" }},
    { field_type: "Float", order: 11, output_order: 11, orig_title: "ჯამური ღირებულება (ლარი)", footer: :sum,  title_translations: { ka: "ჯამური ღირებულება (ლარი)" }},
    { field_type: "String", order: 12, output_order: 12, orig_title: "შენიშვნა", footer: :sum,  title_translations: { ka: "შენიშვნა" }}
  ],
  [ # 6.1
    { field_type: "String", order: 1, output_order: -1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", default_value: "", order: 2, output_order: 2, orig_title: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით", title_translations: { ka: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით" }},
    { field_type: "Float", default_value: 0, order: 3, output_order: -3, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, note: [2], title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", required: :and, default_value: 0, order: 4, output_order: 4, orig_title: "საკასო ხარჯი", footer: :sum, note: [2], title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [ # 8.1
    { field_type: "String", order: 1, output_order: 1, orig_title: "ტრანზ -აქციის N", skip: true, title_translations: { ka: "ტრანზ -აქციის N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "ოპერაციის თარიღი", title_translations: { ka: "ოპერაციის თარიღი" }},
    { field_type: "Float", order: 3, output_order: 3, orig_title: " სალაროს შემოსავალი, ლარში", title_translations: { ka: " სალაროს შემოსავალი, ლარში" }},
    { field_type: "Float", order: 4, output_order: 4, orig_title: "სალაროს გასავალი, ლარში", title_translations: { ka: "სალაროს გასავალი, ლარში" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "ვალუტა", title_translations: { ka: "ვალუტა" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "ოპერაციის დანიშნულება", title_translations: { ka: "ოპერაციის დანიშნულება" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ნაშთი", title_translations: { ka: "ნაშთი" }},
  ],
  [ # 9.1
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "შენობა-ნაგებობების ტიპი", title_translations: { ka: "შენობა-ნაგებობების ტიპი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "იურიდიული მისმართი", title_translations: { ka: "იურიდიული მისმართი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "საკადასტრო ნომერი", title_translations: { ka: "საკადასტრო ნომერი" }},
    { field_type: "Float", order: 5, output_order: 5, orig_title: "ფართობი მ2", title_translations: { ka: "ფართობი მ2" }},
    { field_type: "Float", order: 6, output_order: 6, orig_title: "საბალანსო ღირებულება", title_translations: { ka: "საბალანსო ღირებულება" }},
    { field_type: "String", order: 7, output_order: 7, orig_title: "ბალანსზე აყვანის თარიღი", title_translations: { ka: "ბალანსზე აყვანის თარიღი" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "დახასიათება", title_translations: { ka: "დახასიათება" }},
  ],
  [ # 9.2
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სატრანსპორტო საშუალების ტიპი", title_translations: { ka: "სატრანსპორტო საშუალების ტიპი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "მარკა", title_translations: { ka: "მარკა" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "მოდელი", title_translations: { ka: "მოდელი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "წარმოების წელი", title_translations: { ka: "წარმოების წელი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "სახელმწიფო ნომერი", title_translations: { ka: "სახელმწიფო ნომერი" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "საბალანსო ღირებულება", title_translations: { ka: "საბალანსო ღირებულება" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "ბალანსზე აყვანის თარიღი", title_translations: { ka: "ბალანსზე აყვანის თარიღი" }},
    { field_type: "String", order: 9, output_order: 9, orig_title: "დახასიათება", title_translations: { ka: "დახასიათება" }}
  ],
  [ # 9.3
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "აქტივობის დასახელება", title_translations: { ka: "აქტივობის დასახელება" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "მიზანი", title_translations: { ka: "მიზანი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "აქტივობის განხორციელების პერიოდი", title_translations: { ka: "აქტივობის განხორციელების პერიოდი" }},
    { field_type: "Float", order: 5, output_order: 5, orig_title: "აქტივობის მონაწილე მოხალისეთა რაოდენობა", title_translations: { ka: "აქტივობის მონაწილე მოხალისეთა რაოდენობა" }},
    { field_type: "Float", required: :and, order: 6, output_order: 6, orig_title: "აქტივობაზე გახარჯული მატერიალური მარაგების მოცულობა", title_translations: { ka: "აქტივობაზე გახარჯული მატერიალური მარაგების მოცულობა" }},
    { field_type: "String", order: 7, output_order: 7, orig_title: "შენიშვნა", title_translations: { ka: "შენიშვნა" }},
  ],
  [ # 9.4
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "იჯარით აღებული ობიექტის მისამართი", title_translations: { ka: "იჯარით აღებული ობიექტის მისამართი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "ობიექტის სახეობა", title_translations: { ka: "ობიექტის სახეობა" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "იჯარის ვადა", title_translations: { ka: "იჯარის ვადა" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "ფართი (ხელშეკრულების მიხედვით)", title_translations: { ka: "ფართი (ხელშეკრულების მიხედვით)" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "ყოველთვური საიჯარო გადასახადი (ლარში)", title_translations: { ka: "ყოველთვური საიჯარო გადასახადი (ლარში)" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "მეიჯარის პირადი ნომერი (ფიზიკური პირი)", title_translations: { ka: "მეიჯარის პირადი ნომერი (ფიზიკური პირი)" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "მეიჯარის სახელი", title_translations: { ka: "მეიჯარის სახელი" }},
    { field_type: "String", order: 9, output_order: 9, orig_title: "მეიჯარის გვარი", title_translations: { ka: "მეიჯარის გვარი" }},
    { field_type: "String", order: 10, output_order: 10, orig_title: "მეიჯარე ორგანიზაციის საიდენტიფიკაციო ნომერი", title_translations: { ka: "მეიჯარე ორგანიზაციის საიდენტიფიკაციო ნომერი" }},
    { field_type: "String", order: 11, output_order: 11, orig_title: "მეიჯარე ორგანიზაციის დასახელება", title_translations: { ka: "მეიჯარე ორგანიზაციის დასახელება" }}
  ],
  [ # 9.5
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სატრანსპორტო საშუალების ტიპი", title_translations: { ka: "სატრანსპორტო საშუალების ტიპი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "მარკა", title_translations: { ka: "მარკა" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "მოდელი", title_translations: { ka: "მოდელი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "წარმოების წელი", title_translations: { ka: "წარმოების წელი" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "სახელმწიფო ნომერი", title_translations: { ka: "სახელმწიფო ნომერი" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ყოველთვური საიჯარო გადასახადი (ლარში)", title_translations: { ka: "ყოველთვური საიჯარო გადასახადი (ლარში)" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "მეიჯარის პირადი ნომერი (ფიზიკური პირი)", title_translations: { ka: "მეიჯარის პირადი ნომერი (ფიზიკური პირი)" }},
    { field_type: "String", order: 9, output_order: 9, orig_title: "მეიჯარის სახელი", title_translations: { ka: "მეიჯარის სახელი" }},
    { field_type: "String", order: 10, output_order: 10, orig_title: "მეიჯარის გვარი", title_translations: { ka: "მეიჯარის გვარი" }},
    { field_type: "String", order: 11, output_order: 11, orig_title: "მეიჯარე ორგანიზაციის საიდენტიფიკაციო ნომერი", title_translations: { ka: "მეიჯარე ორგანიზაციის საიდენტიფიკაციო ნომერი" }},
    { field_type: "String", order: 12, output_order: 12, orig_title: "მეიჯარე ორგანიზაციის დასახელება", title_translations: { ka: "მეიჯარე ორგანიზაციის დასახელება" }}
  ],
  [ # 9.6
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "იჯარის ობიექტის სახეობა", title_translations: { ka: "იჯარის ობიექტის სახეობა" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "ტექნიკური მახასიათებლები", title_translations: { ka: "ტექნიკური მახასიათებლები" }},
    { field_type: "Float", order: 4, output_order: 4, orig_title: "ყოველთვური საიჯარო გადასახადი (ლარში)", title_translations: { ka: "ყოველთვური საიჯარო გადასახადი (ლარში)" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "მეიჯარის პირადი ნომერი (ფიზიკური პირი)", title_translations: { ka: "მეიჯარის პირადი ნომერი (ფიზიკური პირი)" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "მეიჯარის სახელი", title_translations: { ka: "მეიჯარის სახელი" }},
    { field_type: "String", order: 7, output_order: 7, orig_title: "მეიჯარის გვარი", title_translations: { ka: "მეიჯარის გვარი" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "მეიჯარე ორგანიზაციის საიდენტიფიკაციო ნომერი", title_translations: { ka: "მეიჯარე ორგანიზაციის საიდენტიფიკაციო ნომერი" }},
    { field_type: "String", order: 9, output_order: 9, orig_title: "მეიჯარე ორგანიზაციის დასახელება", title_translations: { ka: "მეიჯარე ორგანიზაციის დასახელება" }}
  ],
  [ # 9.7
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "ხელშეკრულების დადების თარიღი", title_translations: { ka: "ხელშეკრულების დადების თარიღი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "კონტრაგენტის დასახელება (იურიდიული პირი)/სახელი, გვარი (ფიზიკური პირი)", title_translations: { ka: "კონტრაგენტის დასახელება (იურიდიული პირი)/სახელი, გვარი (ფიზიკური პირი)" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "კონტრაგენტის საიდენტიფიკაციო ნომერი/პირადი ნომერი", title_translations: { ka: "კონტრაგენტის საიდენტიფიკაციო ნომერი/პირადი ნომერი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "ხელშეკრულების საგანი", title_translations: { ka: "ხელშეკრულების საგანი" }},
    { field_type: "Float", order: 6, output_order: 6, orig_title: "ხელშეკრულების თანხა (ლარში)", title_translations: { ka: "ხელშეკრულების თანხა (ლარში)" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "მოწოდებული საქონლის/მომსახურების ღირებულება (ლარში)", title_translations: { ka: "მოწოდებული საქონლის/მომსახურების ღირებულება (ლარში)" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "კონტრაგენტისათვის გადახდილი თანხა (ლარში)", title_translations: { ka: "კონტრაგენტისათვის გადახდილი თანხა (ლარში)" }},
    { field_type: "Float", order: 9, output_order: 9, orig_title: "ვალდებულების ნაშთი (ლარში) საანგარიშგებო პერიოდის ბოლოს", footer: :sum, title_translations: { ka: "ვალდებულების ნაშთი (ლარში) საანგარიშგებო პერიოდის ბოლოს" }}
  ],
  [ # 9.7.1
    { field_type: "String", order: 1, output_order: 1, orig_title: "N", skip: true, title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სესხის აღების თარიღი", title_translations: { ka: "სესხის აღების თარიღი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "სესხის გამცემი ბანკი", title_translations: { ka: "სესხის გამცემი ბანკი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "სესხის ტიპი", title_translations: { ka: "სესხის ტიპი" }},
    { field_type: "Float", order: 5, output_order: 5, orig_title: "ვალუტა", title_translations: { ka: "ვალუტა" }},
    { field_type: "Float", order: 6, output_order: 6, orig_title: "სესხის ოდენობა", title_translations: { ka: "სესხის ოდენობა" }},
    { field_type: "String", order: 7, output_order: 7, orig_title: "სესხის ვადა (თვეების რაოდენ.)", title_translations: { ka: "სესხის ვადა (თვეების რაოდენ.)" }},
    { field_type: "String", order: 8, output_order: 8, orig_title: "საკონტრაქტო წლიური საპროცენტო განაკვეთი", title_translations: { ka: "საკონტრაქტო წლიური საპროცენტო განაკვეთი" }},
    { field_type: "String", order: 9, output_order: 9, orig_title: "სესხის დაფარვის პირობები", footer: :sum, title_translations: { ka: "სესხის დაფარვის პირობები" }},
    { field_type: "String", order: 10, output_order: 10, orig_title: "სესხის უზრუნვ.", footer: :sum, title_translations: { ka: "სესხის უზრუნვ." }},
    { field_type: "String", order: 11, output_order: 11, orig_title: "თავდებობა (კი/არა)", footer: :sum, title_translations: { ka: "თავდებობა (კი/არა)" }},
    { field_type: "String", order: 12, output_order: 12, orig_title: "თავდები პირის (ფიზიკური/იურიდიული) სახელი", footer: :sum, title_translations: { ka: "თავდები პირის (ფიზიკური/იურიდიული)" }},
    { field_type: "String", order: 13, output_order: 13, orig_title: "გაგზავნის თარიღი", footer: :sum, title_translations: { ka: "სახელი გაგზავნის თარიღი" }}
  ]
]

notes_data = [
  [ # 1
    { star: 1, text_translations: { ka: "შემოსავლის ტიპი-ს ველში იწერება: ფულადი შემოწირულება, არაფულადი შემოწირულება, საწევრო შენატანი." }},
    { star: 2, text_translations: { ka: "'მოქალაქეთა პოლიტიკური გაერთიანებების შესახებ' საქართველოს ორგანული კანონის 25-ე მუხლის მეორე პუნქტის 'ბ' ქვეპუნქტის შესაბამისად შემოწირულობის განმახორციელებელი იურიდიული პირის პარტიონრები და საბოლოო ბენეფიციარები უნდა იყვნენ მხოლოდ საქართველოს მოქალაქეები." }},
    { star: 3, text_translations: { ka: "არაფულად შემოსავალში შედის უძრავი და მოძრავი ნივთი, არამატერიალური ქონებრივი სიკეთე და მომსახურება. სახელმწიფო აუდიტის სამსახური  უფლებას იტოვებს გადაამოწმოს შემოწირული ქონების საბაზრო ღირებულება და მოახდინოს შესაბამისი კორექტირება." }},
    { star: 4, text_translations: { ka: "მიუთითეთ დეტალური ინფორმაცია ქონების შესახებ (მად.: მიწა, მისი ფართობი, ადგილმდებარეობა, საკადასტრო კოდი და ა.შ);   აღნიშნულ ველში ივსება ინფორმაცია შემოწირულობის სახით მირებული ქონების შესახებ." }}
  ],
  [ # 4.1
    { star: 1, text_translations: { ka: "* ფორმა N4.1 ივსება მხოლოდ იმ შემთხვევებში, თუ ფორმა N4 ში წარმოდგენილი სხვადასხდა ხარჯები (1.6.4), სხვა დანარჩენი საქონლისა და მომსახურების (1.2.15)  ფაქტიური და საკასო ხარჯის მოცულობა ცალ ცალკე ან ერთად აღებული აღემატება ამავე ფორმის  N1.2 ან N1.6 მუხლების შესაბამისი მნიშვნელობების 5%-ს ან 1,000 ლარს." }},
    { star: 2, text_translations: { ka: "** ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N4-ში წარმოდგენილ N 1.2.15 და N1.6.4 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [ # 4.2
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N4-ში და N5-ში წარმოდგენილი N 1.1.1 და N1.1.2 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [ # 4.3
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N4-ში და N5-ში წარმოდგენილი N 1.2.1 და ფორმა N6-ში წარმოდგენილი N 1.3  მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [ # 4.4
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N4-ში და N5-ში წარმოდგენილი N1.3 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [ # 5.1
    { star: 1, text_translations: { ka: "* ფორმა N5.1 ივსება მხოლოდ იმ შემთხვევებში, თუ ფორმა N5 ში წარმოდგენილი სხვადასხდა ხარჯები (1.6.4), ხვა დანარჩენი საქონლისა და მომსახურების (1.2.15) ფაქტიური და საკასო ხარჯის მოცულობა ცალ ცალკე ან ერთად აღებული აღემატება ამავე ფორმის N1.2 ან N1.6 მუხლების შესაბამისი მნიშვნელობების 5%-ს ან 1,000 ლარს." }},
    { star: 2, text_translations: { ka: "** ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N5-ში წარმოდგენილ  N 1.2.15 და N1.6.4 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [ # 5.2
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა  N5-ში წარმოდგენილი N 1.1.1 და N1.1.2 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [ # 5.3
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა  N5-ში წარმოდგენილი N 1.2.1 მუხლის  შესაბამის მნიშვნელობებს." }}
  ],
  [ # 5.4
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N5-ში წარმოდგენილ N1.3 მუხლის შესაბამის მნიშვნელობებს." }}
  ],
  [ # 5.5
    { star: 1, text_translations: { ka: "* რეკლამის დამკვეთი შესაძლებელია იყოს დეკლარაციის წარმომდგენი სუბიექტი ან მიღებულ იქნეს შემოწირულების სახით, რომელიც ასევე უნდა აისახოს ფორმა N1-ში" }},
    { star: 2, text_translations: { ka: "** ბეჭდვური და ინტერნეტ რეკლამის შემთხვევაში" }},
    { star: 3, text_translations: { ka: "*** რეკლამაზე გამოსახული კანდიდატის ან პარტიის ვინაობა/დასახელება" }},
    { star: 4, text_translations: { ka: "**** ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა  N5-ში წარმოდგენილი N 1.2.8 მუხლის  შესაბამის მნიშვნელობებს" }}
  ],
  [ # 6.1
    { star: 1, text_translations: { ka: "* ფორმა N6.1 ივსება მხოლოდ იმ შემთხვევებში, როდესაც ფორმა N6-ში წარმოდგენილი სხვა ხარჯების (მუხლი N 1.6) ფაქტიური ან საკასო ხარჯის მოცულობა აღემატება ამავე ფორმის  N1 მუხლის შესაბამისი მნიშვნელობების 5%-ს ან 1,000 ლარს." }},
    { star: 2, text_translations: { ka: "** ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N6-ში წარმოდგენილ N1.6 მუხლის შესაბამის მნიშვნელობებს." }}
  ],
  [ ], # 8.1
  [ ], # 9.1
  [ ], # 9.2
  [ ], # 9.3
  [ ], # 9.4
  [ ], # 9.5
  [ ], # 9.6
  [ # 9.7
    { star: 1, text_translations: { ka: "* სულ ვალდებულებები უნდა ედრებოდეს ფორმა N7-ში წარმოდგენილ ვალდებულებების შესაბამის ანგარიშთა ნაშთებს საანგარიშგებო პერიოდის ბოლოს." }}
  ],
  [ ] # 9.7.1
]

terminators_data = [
  [ # 1
    { term: "სულ", field_index: 1 },
    { term: "შემოსავლის ტიპი-ს", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 4.1
    { term: "სულ**", field_index: 2 },
    { term: "სულ **", field_index: 2 },
    { term: "* ფორმა N4.1", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 4.2
    { term: "სულ:*", field_index: 6 },
    { term: "სულ: *", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 4.3
    { term: "სულ:*", field_index: 6 },
    { term: "სულ: *", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 4.4
    { term: "სულ:*", field_index: 6 },
    { term: "სულ: *", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 5.1
    { term: "სულ**", field_index: 2 },
    { term: "სულ **", field_index: 2 },
    { term: "* ფორმა N5.1", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 5.2
    { term: "სულ**", field_index: 6 },
    { term: "სულ **", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 5.3
    { term: "სულ**", field_index: 6 },
    { term: "სულ **", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 5.4
    { term: "სულ:*", field_index: 6 },
    { term: "სულ: *", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 5.5
    { term: "* რეკლამის დამკვეთი", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 6.1
    { term: "სულ**", field_index: 2 },
    { term: "სულ **", field_index: 2 },
    { term: "* ფორმა N6.1", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 8.1
    { term: "სალაროს ნაშთი პერიოდის ბოლოს", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 9.1
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 9.2
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 9.3
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 9.4
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 9.5
    { term: "ხელმოწერები:", field_index: 3 }
  ],
  [ # 9.6
    { term: "ხელმოწერები:", field_index: 1 }
  ],
  [ # 9.7
    { term: "სულ:", field_index: 8 },
    { term: "* სულ ვალდებულებები უნდა:", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 2 }
  ],
  [ # 9.7.1
    { term: "ხელმოწერები:", field_index: 2 }
  ]
]

# -----------------------------------------------------------------
# # -----------------------------------------------------------------


puts "Creating phase ----------------------"

  puts "  Party meta data"
  I18n.locale = :ka
  parties_data.each_with_index do |d,i|
    party = Party.create!(d)
    puts "    #{party.name} was added"
  end

  puts "  Period meta data"
  periods_data.each_with_index do |d,i|
    d[:start_date] = Date.strptime(d[:start_date], "%d.%m.%Y")
    d[:end_date] = Date.strptime(d[:end_date], "%d.%m.%Y")

    period = Period.create!(d)
    puts "    #{period.type} #{period.title} was added"
  end

  puts "  Party data"
  details_data.each_with_index{ |d,i|
    notes = d.delete(:note)

    detail = Detail.new(d)
    if notes.present?
      detail.notes.concat( notes.map{|r| Note.new(notes_data[i].select{|rr| rr[:star] == r}.first) } )
    end

    # putting detail schema
    detail_schemas_data[i].each {|dd|
      notes = dd.delete(:note)
      schema = DetailSchema.new(dd)
      if notes.present?
        schema.notes.concat( notes.map{|r| Note.new(notes_data[i].select{|rr| rr[:star] == r}.first) } )
      end

      detail.detail_schemas << schema
    }

    # putting terminators to detail
    terminators_data[i].each {|dd| detail.terminators << Terminator.new(dd) } if terminators_data[i].present?


    detail.save!
    puts "Detail #{detail.title} was added"
  }

  puts "  Category data"
  categories_data.each_with_index do |d,i|
    tmp_id = d.delete(:tmp_id)

    #puts d[:detail_id] if ["FF9", "FF8"].include?(d[:detail_id])

    d[:detail_id] = Detail.by_code(d[:detail_id])._id if (d[:detail_id].present? && !["FF9", "FF8"].include?(d[:detail_id]))

    cat = Category.create!(d)
    categories_data.each {|r| r[:parent_id] = cat._id if r[:parent_id] == tmp_id }
    virtuals_data.each {|r|
      ind = r[:virtual_ids].index(tmp_id)
      if ind.present?
        r[:virtual_ids][ind] = cat._id
      end
    }

    puts "    Category '#{cat.title_translations[:en]}' was added"
  end

  puts "  Virtual Category data"
  virtuals_data.each_with_index do |d,d_i|
    tmp_id = d.delete(:tmp_id)
    cat = Category.create!(d)
    virtuals_data.each {|r| r[:parent_id] = cat._id if r[:parent_id] == tmp_id }
    puts "    Virtual Category '#{d[:title_translations][:en]}' was added" #{d[:virtual_ids].inspect}
 end

  # begin
  #   period.valid?
  #   puts period.errors.inspect
  # rescue Exception=>e
  #   puts e.inspect
  # end
