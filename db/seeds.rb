# This file should contain all the record creation needed to seed the database
# with its default values. The data can then be loaded with the rake db:seed
# (or created alongside the db with db:setup).

# roles = %w(super_admin site_admin content_manager)
# roles.each do |role|
#   Role.find_or_create_by(name: role)
# end
#
I18n.locale = :ka
destroy_mode = true
if destroy_mode
  puts "Destroy phase ----------------------"
  puts "  party data"
  Party.destroy_all
  puts "  period data"
  Period.destroy_all
  puts "  detail and its schema, with all embed documents"
  Detail.destroy_all
  puts "Destroy phase end ------------------"
end

parties_data = [
  { name_translations: { ka: 'ქართული ოცნება' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ნაციონალური მოძრაობა' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'კონსერვატიული პარტია' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'მრეწველობა გადაარჩენს საქართველოს' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'რესპუბლიკური პარტია' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ჩვენი საქართველო - თავისუფალი დემოკრატები' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ეროვნული ფორუმი' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ქრისტიან-კონსერვატიული პარტია' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'დემოკრატიული მოძრაობა' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'პატრიოტთა ალიანსი' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ლეიბორისტული პარტია' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'საქართველოს გზა' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ედპ' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'თავისუფალი საქართველო' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ახალი მემარჯვენეები' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'სამოქალაქო ალიანსი' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'სახალხო პარტია' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'საზოგადოება "ივერია"' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ახალი პოლიტიკური ცენტრი "გირჩი"' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'განახლებული საქართველოსთვის' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ჩერნოვეცკის პარტია' }, summary_translations: { ka: ''}},
  { name_translations: { ka: 'ბურჭულაძის ფონდი' }, summary_translations: { ka: ''}}
  #{ name_translations: { ka: '' }, summary_translations: { ka: ''}}
]

periods_data = [
  # type 'annual' 'election'
  { type: 'annual', start_date: '01.01.2012', end_date: '31.01.2012', title_translations: { ka: "2012" }, description_translations: { ka: "2012 description" }},
  { type: 'annual', start_date: '01.01.2013', end_date: '31.01.2013', title_translations: { ka: "2013" }, description_translations: { ka: "2013 description" }},
  { type: 'annual', start_date: '01.01.2014', end_date: '31.01.2014', title_translations: { ka: "2014" }, description_translations: { ka: "2014 description" }},
  { type: 'annual', start_date: '01.01.2015', end_date: '31.01.2015', title_translations: { ka: "2015" }, description_translations: { ka: "2015 description" }}
  #{ type: 'election', start_date: '01.01.2015', end_date: '31.03.2015', title_translations: { ka: "2015 election" }, description_translations: { ka: "2015 election description" }}
]

cats = [
  {
    title: "Income", cells: "FF2/C9+FF3/C9", simple: 1
  }
]




#1, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1, 8.1, 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7
details_data = [
  #{ code: "FF1", orig_code: "ფორმა N1", title_translations: { ka: "საწევრო შენატანები და შემოწირულებები" }, header_row: 8, content_row: 10, fields_count: 12, fields_to_skip: [1] },
  { code: "FF4.1", orig_code: "ფორმა N4.1", header_row: 9, content_row: 10, fields_count: 4, footer: 1, note: [1], title_translations: { ka: "სხვადასხვა ხარჯებისა და სხვა დანარჩენი საქონლისა და მომსახურების" } },
  { code: "FF4.2", orig_code: "ფორმა N4.2", header_row: 8, content_row: 9, fields_count: 9, footer: 1, note: [1], title_translations: { ka: "ხელფასები, პრემიები" }}#,
  # { code: "FF4.3", title_translations: { ka: "მივლინებები" }},
  # { code: "FF4.4", title_translations: { ka: "სხვა განაცემები ფიზიკურ პირებზე (ხელფასის და პრემიის გარდა)" }},
  # { code: "FF5.1", title_translations: { ka: "სხვადასხვა ხარჯებისა და სხვა დანარჩენი საქონლისა და მომსახურების" }},
  # { code: "FF6.1", title_translations: { ka: "სსიპ 'საარჩევნო სისტემების განვითარების, რეფორმებისა და სწავლების ცენტრიდან' მიღებული სახსრებით გაწეული ხარჯების" }},
  # { code: "FF8.1", title_translations: { ka: "ნაღდი ფულით განხორციელებულ სალაროს ოპერაციათა რეესტრი" }},
  # { code: "FF9.1", title_translations: { ka: "შენობა-ნაგებობების რეესტრი" }},
  # { code: "FF9.2", title_translations: { ka: "სატრანსპორტო საშუალებების რეესტრი" }},
  # { code: "FF9.3", title_translations: { ka: "მოხალისეთა აქტივობების რეესტრი" }},
  # { code: "FF9.4", title_translations: { ka: "იჯარით/ქირით აღებული უძრავი ქონების რეესტრი" }},
  # { code: "FF9.5", title_translations: { ka: "იჯარით/ქირით აღებული სატრანსპორტო საშუალებების რეესტრი" }},
  # { code: "FF9.6", title_translations: { ka: "იჯარით/ქირით აღებული სხვა მოძრავი ქონების რეესტრი" }},
  # { code: "FF9.7", title_translations: { ka: "ვალდებულებების რეესტრი" }},
  # { code: "FF9.7.1", title_translations: { ka: "საარჩევნო პერიოდში აღებული სესხი/კრედიტი" }}
]

detail_schemas_data = [
  # [
  #   { field_type: "String", order: 1, output_order: 1, orig_title: "N", title_translations: { ka: "N" }, skip: true },
  #   { field_type: "Date", order: 1, output_order: 1, orig_title: "ოპერაციის თარიღი", title_translations: { ka: "ოპერაციის თარიღი" }},
  #   { field_type: "String", order: 2, output_order: 2, orig_title: "შემოსავლის ტიპი *", title_translations: { ka: "შემოსავლის ტიპი" }, note: [1] },
  #   { field_type: "Float", order: 3, output_order: 3, orig_title: "თანხა / ღირებულება (ლარებში)", title_translations: { ka: "თანხა / ღირებულება (ლარებში)" }, footer: :sum},
  #   { field_type: "String", order: 4, output_order: 4, orig_title: "ფიზიკური პირის სახელი და გვარი / იურიდიული პირის დასახელება", title_translations: { ka: "ფიზიკური პირის სახელი და გვარი / იურიდიული პირის დასახელება" }},
  #   { field_type: "String", order: 5, output_order: 5, orig_title: "პირადი ნომერი / საიდ. კოდი", title_translations: { ka: "პირადი ნომერი / საიდ. კოდი" }},
  #   { field_type: "String", order: 6, output_order: 6, orig_title: "შემომწირავის საბანკო ანგარიშის ნომერი", title_translations: { ka: "შემომწირავის საბანკო ანგარიშის ნომერი" }},
  #   { field_type: "String", order: 7, output_order: 7, orig_title: "შემომწირავის ბანკი", title_translations: { ka: "შემომწირავის ბანკი" }},
  #   { field_type: "String", order: 8, output_order: 8, orig_title: "ქონების აღწერილობა ****", title_translations: { ka: "არაფულადი ფორმით ქონების აღწერილობა" }, note: [3,4] },
  #   { field_type: "String", order: 9, output_order: 9, orig_title: "მომსახურების მოკლე აღწერილობა", title_translations: { ka: "არაფულადი ფორმით მომსახურების მოკლე აღწერილობა"}, note: [3] },
  #   { field_type: "String", order: 10, output_order: 10, orig_title: "რაოდენობა/ მოცულობა", title_translations: { ka: "არაფულადი ფორმით რაოდენობა/ მოცულობა"}, note: [3] },
  #   { field_type: "String", order: 11, output_order: 11, orig_title: "დამატებითი ინფორმაცია", title_translations: { ka: "დამატებითი ინფორმაცია" }}
  # ],
  [
    { field_type: "String", order: 1, output_order: -1, orig_title: "N", title_translations: { ka: "N" }},
    { field_type: "String", default_value: "დაუზუსტებელი", order: 2, output_order: 2, orig_title: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით", title_translations: { ka: "ხარჯის კლასიფიკაცია ბუნებისა და შინაარსის მიხედვით" }}, # this is required but has default
    { field_type: "Float", default_value: 0, order: 3, output_order: -3, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, note: [2], title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", required: :and, default_value: 0, order: 4, output_order: 4, orig_title: "საკასო ხარჯი", footer: :sum, note: [2], title_translations: { ka: "საკასო ხარჯი" }}
  ],
  [
    { field_type: "String", order: 1, output_order: -1, skip: true, orig_title: "N", title_translations: { ka: "N" }},
    { field_type: "String", order: 2, output_order: 2, orig_title: "სახელი", title_translations: { ka: "სახელი" }},
    { field_type: "String", order: 3, output_order: 3, orig_title: "გვარი", title_translations: { ka: "გვარი" }},
    { field_type: "String", order: 4, output_order: 4, orig_title: "პირადი ნომერი", title_translations: { ka: "პირადი ნომერი" }},
    { field_type: "String", order: 5, output_order: 5, orig_title: "პოზიცია", title_translations: { ka: "პოზიცია" }},
    { field_type: "String", order: 6, output_order: 6, orig_title: "განაცემის ტიპი", title_translations: { ka: "განაცემის ტიპი" }},
    { field_type: "Float", order: 7, output_order: 7, orig_title: "ფაქტობრივი ხარჯი", footer: :sum, title_translations: { ka: "ფაქტობრივი ხარჯი" }},
    { field_type: "Float", order: 8, output_order: 8, orig_title: "საკასო ხარჯი", footer: :sum,  title_translations: { ka: "საკასო ხარჯი" }},
    { field_type: "Float", order: 9, output_order: 9, orig_title: "გადახდის წყაროსთან დაკავებული საშემოსავლო გადასახადი", footer: :sum, title_translations: { ka: "გადახდის წყაროსთან დაკავებული საშემოსავლო გადასახადი" }}
  ]
]

notes_data = [
  # [ # ** is not used
  #   { star: 1, text_translations: { ka: "შემოსავლის ტიპი-ს ველში იწერება: ფულადი შემოწირულება, არაფულადი შემოწირულება, საწევრო შენატანი." }},
  #   { star: 2, text_translations: { ka: "'მოქალაქეთა პოლიტიკური გაერთიანებების შესახებ' საქართველოს ორგანული კანონის 25-ე მუხლის მეორე პუნქტის 'ბ' ქვეპუნქტის შესაბამისად შემოწირულობის განმახორციელებელი იურიდიული პირის პარტიონრები და საბოლოო ბენეფიციარები უნდა იყვნენ მხოლოდ საქართველოს მოქალაქეები." }},
  #   { star: 3, text_translations: { ka: "არაფულად შემოსავალში შედის უძრავი და მოძრავი ნივთი, არამატერიალური ქონებრივი სიკეთე და მომსახურება. სახელმწიფო აუდიტის სამსახური  უფლებას იტოვებს გადაამოწმოს შემოწირული ქონების საბაზრო ღირებულება და მოახდინოს შესაბამისი კორექტირება." }},
  #   { star: 4, text_translations: { ka: "მიუთითეთ დეტალური ინფორმაცია ქონების შესახებ (მად.: მიწა, მისი ფართობი, ადგილმდებარეობა, საკადასტრო კოდი და ა.შ);   აღნიშნულ ველში ივსება ინფორმაცია შემოწირულობის სახით მირებული ქონების შესახებ." }}
  # ],
  [
    { star: 1, text_translations: { ka: "* ფორმა N4.1 ივსება მხოლოდ იმ შემთხვევებში, თუ ფორმა N4 ში წარმოდგენილი სხვადასხდა ხარჯები (1.6.4), სხვა დანარჩენი საქონლისა და მომსახურების (1.2.15)  ფაქტიური და საკასო ხარჯის მოცულობა ცალ ცალკე ან ერთად აღებული აღემატება ამავე ფორმის  N1.2 ან N1.6 მუხლების შესაბამისი მნიშვნელობების 5%-ს ან 1,000 ლარს." }},
    { star: 2, text_translations: { ka: "ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N4-ში წარმოდგენილ N 1.2.15 და N1.6.4 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ],
  [
    { star: 1, text_translations: { ka: "* ჯამური მაჩვენებლები უნდა ედრებოდეს ფორმა N4-ში და N5-ში წარმოდგენილი N 1.1.1 და N1.1.2 მუხლების შესაბამის მნიშვნელობათა ჯამს." }}
  ]
]


terminators_data = [
  # [ # ** is not used
  #   { star: 1, text_translations: { ka: "შემოსავლის ტიპი-ს ველში იწერება: ფულადი შემოწირულება, არაფულადი შემოწირულება, საწევრო შენატანი." }},
  #   { star: 2, text_translations: { ka: "'მოქალაქეთა პოლიტიკური გაერთიანებების შესახებ' საქართველოს ორგანული კანონის 25-ე მუხლის მეორე პუნქტის 'ბ' ქვეპუნქტის შესაბამისად შემოწირულობის განმახორციელებელი იურიდიული პირის პარტიონრები და საბოლოო ბენეფიციარები უნდა იყვნენ მხოლოდ საქართველოს მოქალაქეები." }},
  #   { star: 3, text_translations: { ka: "არაფულად შემოსავალში შედის უძრავი და მოძრავი ნივთი, არამატერიალური ქონებრივი სიკეთე და მომსახურება. სახელმწიფო აუდიტის სამსახური  უფლებას იტოვებს გადაამოწმოს შემოწირული ქონების საბაზრო ღირებულება და მოახდინოს შესაბამისი კორექტირება." }},
  #   { star: 4, text_translations: { ka: "მიუთითეთ დეტალური ინფორმაცია ქონების შესახებ (მად.: მიწა, მისი ფართობი, ადგილმდებარეობა, საკადასტრო კოდი და ა.შ);   აღნიშნულ ველში ივსება ინფორმაცია შემოწირულობის სახით მირებული ქონების შესახებ." }}
  # ],
  [
    { term: "სულ**", field_index: 2 },
    { term: "სულ **", field_index: 2 },
    { term: "* ფორმა N4.1", field_index: 1 }
  ],
  [
    { term: "სულ:*", field_index: 6 },
    { term: "* ჯამური მაჩვენებლები", field_index: 1 },
    { term: "ხელმოწერები:", field_index: 1 }
  ]

]

# -----------------------------------------------------------------
# # -----------------------------------------------------------------

# cats.each{|d,i|
#   Category.create!(d) #.map { |k, v| [k.to_s, v.to_s] }.to_h
#   puts "Category #{d[:title]} was added"
# }
puts "Creating phase ----------------------"

puts "  Party meta data"
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
details_data.each_with_index{|d,i|
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
  terminators_data[i].each {|dd| detail.terminators << Terminator.new(dd) }


  detail.save!
  puts "Detail #{detail.title} was added"
}



  # begin
  #   period.valid?
  #   puts period.errors.inspect
  # rescue Exception=>e
  #   puts e.inspect
  # end
