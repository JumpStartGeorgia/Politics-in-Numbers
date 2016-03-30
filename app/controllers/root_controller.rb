# Non-resource pages
class RootController < ApplicationController
  def index
  end

  def about
  end

  def read
    @p = []
    start = Time.now
    upload_path = Rails.public_path.join("upload")
    files = []
    Dir.entries(upload_path).each {|f| 
      files << "#{upload_path}/#{f}" if File.file? "#{upload_path}/#{f}"
    }
    #raise RuntimeError, "#{files.join(', ')}"

    # sheets = ["ფორმა N1", "ფორმა N2", "ფორმა N3" , "ფორმა N4", "ფორმა N4.1", "ფორმა N4.2", "ფორმა N4.3", "ფორმა 4.4", "ფორმა N5", "ფორმა N5.1",  "ფორმა N5.2",  "ფორმა N5.3", "ფორმა N5.4", "ფორმა N6", "ფორმა N6.1", "ფორმა N7", "ფორმა N8", "ფორმა N 8.1", "ფორმა N9", "ფორმა N9.1", "ფორმა N9.2", "ფორმა N9.3", "ფორმა N9.4", "ფორმა N9.5", "ფორმა N9.6", "ფორმა N9.7", "ფორმა N9.7.1", "Validation"]
    sheets = ["1", "2", "3", "4" , "4.1" , "4.2" , "4.3" , "4.4" , "5" , "5.1" , "5.2" , "5.3" , "5.4", "5.5", "6" , "6.1" , "7", "8", "8.1" , "9" , "9.1" , "9.2" , "9.3", "9.4" , "9.5", "9.6", "9.7", "9.7.1" , "Validation"]
    sheets_abbr = ["FF1", "FF2", "FF3", "FF4" , "FF4.1" , "FF4.2" , "FF4.3" , "FF4.4" , "FF5" , "FF5.1" , "FF5.2" , "FF5.3" , "FF5.4" , "FF5.5" , "FF6" , "FF6.1" , "FF7", "FF8", "FF8.1" , "FF9" , "FF9.1" , "FF9.2" , "FF9.3", "FF9.4" , "FF9.5", "FF9.6", "FF9.7", "FF9.7.1" , "V"]
    files.each{|f|
    
      workbook = RubyXL::Parser.parse(f)
      missed_sheets = []
      extra_sheets = []
      workbook_sheets = []
      workbook_sheets_map = {}
      error = false

      workbook.worksheets.each_with_index { |w, wi|
        sheet_id = get_sheet_id(w.sheet_name)
        workbook_sheets << w.sheet_name
        if sheet_id != "Validation"
          extra_sheets << w.sheet_name if !sheets.include? sheet_id
          workbook_sheets_map["FF#{sheet_id}"] = wi
        end
      }
      # d(workbook_sheets_map.inspect)

      sheets.each_with_index { |w, wi|
        missed_sheets << w if !workbook_sheets.include? w
      }
      # puts missed_sheets.inspect
      # puts "0000"
      # puts extra_sheets.inspect
      if missed_sheets.present? || extra_sheets.present?
        error = true
        d("This sheets should be in file: #{missed_sheets.join(",")}") if missed_sheets.present?
        d("This sheets shouldn't be in file: #{extra_sheets.join(",")}") if extra_sheets.present?
      end

      if !error
        # Category.each {|cat|
        #   d(cat.title)
        #   d(cat.cells)
        #   allcells = cat.cells.delete(' ')
        #   cells = []
        #   operations = []
        #   allowed_operations = ["+", "-"]
        #   tmp_cell = ""
        #   for i in 0..allcells.length-1
        #     c = allcells[i]
        #     if allowed_operations.include? c
        #       cells << tmp_cell
        #       tmp_cell = ""
        #       operations << c
        #     else
        #       tmp_cell << c
        #     end            
        #   end
        #   cells << tmp_cell if tmp_cell.present?
        #   d(cells)
        #   d(operations)

        #   cells_value = 0
        #   cells.each_with_index {|cell_info, ind|
        #     meta = cell_info.split("/")
        #     form = meta[0]
        #     cell = meta[1]
        #     if sheets_abbr.include? form
        #       abbr_index = sheets_abbr.index(form)
        #       address = RubyXL::Reference.ref2ind(cell)
              
        #       tmp = workbook[sheets[abbr_index]][address[0]][address[1]]
        #       val = tmp.present? ? tmp.value.to_f : 0.0
        #       if ind == 0
        #         cells_value = val if ind == 0
        #       else
        #         oper = operations[ind-1]
        #         if oper == "+"
        #           cells_value = cells_value + val
        #         elsif oper = "-"
        #           cells_value = cells_value - val
        #         end
        #       end
        #       d("#{sheets[abbr_index]}:#{address}:#{val}")
        #     else 
        #       d("Missing form #{form}")
        #     end
        #   }
        #   d(cells_value)
        # }
        flag = false
        @tables = []
        Detail.each{|item|
          #d(item.title)
          
          #worksheet = workbook[item.orig_code]
          worksheet = workbook[workbook_sheets_map[item.code]]
          #d("#{workbook_sheets_map[item.code]}#{workbook_sheets_map}#{item.code}")
          #next
          #worksheet_to_table(worksheet)

          header = worksheet[item.header_row-1] && worksheet[item.header_row-1].cells
          ln = header.length
          d(ln)
          if ln > 0
            item.detail_schemas.each_with_index {|field, field_index|
              if field_index < ln 
                cell = header[field_index] && header[field_index].value
                if field.orig_title == cell
                  d("Passed #{field.orig_title}")
                else
                  d("Unexpected detail header title should be #{field.orig_title} is #{cell}  for #{item.orig_code}")
                  flag = true
                  break
                end
              else
                d("Detail form #{item.orig_code} has no column named - #{field.orig_title} ")
                flag = true
                break
              end
            }
          end
          content_index = item.content_row-1
          row = worksheet[content_index] && worksheet[content_index].cells
          terms = {}
          item.terminators.each{|r| 
            terms[r.field_index] = [] if !terms.key?(r.field_index)
            terms[r.field_index] << r.term
          }
          d(terms.inspect)
          while(row)  
            stop = false
            rr = []
            has_value = false
            row.each_with_index {|cell, cell_index| 
              # if whole row is empty skip
              # skip field
              if cell_index < item.fields_count
                if cell && cell.value.present?
                  break if cell_index == 0 && cell.value == "..." 
                  #d("#{terms.key?(cell_index+1)}>#{cell.value}<>#{terms[cell_index+1]}<#{cell.value==terms[cell_index+1]}")
                  (stop = true; break;) if terms.key?(cell_index+1) && terms[cell_index+1].include?(cell.value)
                  rr.push(cell.value)
                  has_value = true
                else                  
                  rr.push('nil')
                end
              end
            }
            if stop 
              d("Stopped here")
              break
            end

            if has_value
              d("#{rr.join('; ')}")
            else
              #d("empty line")
            end
            content_index += 1
            row = worksheet[content_index] && worksheet[content_index].cells
          end
          if !flag 

          else
            d("Fix previous detail form before moving forward")
            break
          end
     
        }
      end
      d("Time elapsed #{(Time.now - start).round(2)} seconds")
    }
  end

end

     #d(worksheet_header) 
          # worksheet_header && worksheet_header.each{|cell|
          #   d(cell && cell.value)
          # }
          # tmp = workbook[item.orig_code][address[0]][address[1]]
          #     val = tmp.present? ? tmp.value.to_f : 0.0
          #     if ind == 0
          #       cells_value = val if ind == 0
          #     else
          #       oper = operations[ind-1]
          #       if oper == "+"
          #         cells_value = cells_value + val
          #       elsif oper = "-"
          #         cells_value = cells_value - val
          #       end
          #     end


  #               field :code, type: String
  # field :orig_code, type: String
  # field :title, type: String, localize: true
  # field :header_row, type: Integer
  # field :content_row, type: Integer
  # field :fields_count, type: Integer
  # field :fields_to_skip, type: Array, default: []
  # field :footer, type: Integer, default: 0
      #  }
        # workbook.worksheets.each_with_index do |worksheet, wi|
        #   (break;) if wi != 0

        #   worksheet.each_with_index { |row, ri|
        #     @p << ri
        #     if ri < 7 
        #       @p << "header"
        #     else
        #       row && row.cells.each { |cell|
        #         val = cell && cell.value
        #         @p << val
        #       } 
        #       break
        #     end
        #   }
        #   @p << "Worksheet is #{worksheet.sheet_name}"      
        #end
