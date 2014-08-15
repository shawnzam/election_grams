require './web-scraping-tools/webScraper.rb'

require 'csv'
require 'iconv'
def find_title_css_class(filename, default, search_string)
  wss = WebScraper.new
  wss.set file_path: filename, debug: false, selector: "style"
  x = wss.select
  csslines = x.text.lines.to_a.keep_if {|l| l.include? search_string }
  thisclass = default
  if csslines.any?
    thisclass =  csslines[-1][/^\.c\d+/]
  end
  return thisclass
end
# can_map = CSV.read(ARGV[0], headers:true, header_converters: :symbol, converters: :all).collect { |row| Hash[row.collect { |c,r| [c,r] }] }
def docscrape(filename, year, candidate, opponent, party, result, firstpass)

  # outname = "#{filename}_out.csv"
  Dir.mkdir("localparse/input/#{year}/#{candidate}_#{year}") unless Dir.exists?("localparse/input/#{year}/#{candidate}_#{year}")
  outname = "localparse/input/#{year}/#{candidate}_#{year}/#{candidate}_out.csv"
  puts "doing #{filename}, #{candidate}, #{opponent}"
  if (firstpass)
    text = File.read(filename)
    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    text = ic.iconv(text)
    replace = text.gsub!("<DOCFULL> -->", "<DOCFULL> --><div class='doc_start'>")
    File.open(filename, "w") { |filename| filename.puts replace }
    text = File.read(filename)
    replace = text.gsub!("</DOC> -->", "</DOC> --></div>")
    File.open(filename, "w") { |filename| filename.puts replace }
  end

  title_class = find_title_css_class(filename, ".c7", "font-family: 'Times New Roman'; font-size: 14pt; font-style: normal; font-weight: bold; color: #000000; text-decoration: none;")
  token_class = find_title_css_class(filename, ".c8", "font-family: 'Times New Roman'; font-size: 10pt; font-style: normal; font-weight: bold; color: #000000; text-decoration: none;")
  puts token_class
  puts title_class
  ws = WebScraper.new
  ws.set file_path: filename, debug: false, selector: ".doc_start"
  resultSet = ws.select
  res = []
  resultSet.each_with_index do |doc, i|
    this_res = {}
    this_res[:candiate_name] = candidate
    this_res[:opponent_name] = opponent
    this_res[:election_year] = year
    this_res[:party] = party
    this_res[:result] = result

    #title
    title = doc.css(title_class).text rescue nil
    this_res[:title] = title

    #assuming c2[0] = doc counts
    #assuming c2[1] = news outlet and location

    #doc number / #total docs
    doc_number, total_docs = 0
    doc.css(".c2")[0].text  =~ /^(\d+)\sof\s(\d+)\sDOCUMENTS/ rescue nil
    doc_number, total_docs = [$1, $2]
    this_res[:doc_number] = doc_number
    this_res[:total_docs] = total_docs

    #News Outlet
    news_outlet = doc.css(".c2")[1].text rescue nil
    this_res[:news_outlet] = news_outlet.split("(")[0] rescue nil

    #News Outlet / Location
    news_outlet = doc.css(".c2")[1].text  rescue nil
    news_outlet_location = ""
    if match = news_outlet.match(/\(.+\)/) rescue nil
      news_outlet_location = news_outlet.scan(/\(.+\)/)[0] rescue nil
    end
    this_res[:news_outlet_location] = news_outlet_location.gsub(/[\(\)]/,"") rescue nil

    #Article Date
    doc_date = "#{doc.css(".c4")[0].text} #{doc.css(".c4")[0].next_element.text}" rescue nil
    this_res[:doc_date] = doc_date
    # doc_date.remove
    # puts doc_date

    #Byline
    byline= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^BYLINE:\s*$/ )
        byline = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    # puts byline
    this_res[:byline] = byline


    # Section
    section= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^SECTION:\s*$/ )
        section = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    this_res[:section_1] = section.split(";")[0] rescue nil
    this_res[:section_2] = section.split(";")[1] rescue nil
    # puts section

    #Length
    doc_length= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^LENGTH:\s*$/ )
        doc_length = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    # puts doc_length
    this_res[:doc_length] = doc_length

    #Country
    country= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^COUNTRY:\s*$/ )
        country = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    this_res[:country] = country

    #state
    state= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^STATE:\s*$/ )
        state = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    this_res[:state] = state


    #city
    city= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^CITY:\s*$/ )
        city = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end

    this_res[:city] = city




    #GEOGRAPHIC
    geographic= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^GEOGRAPHIC:\s*$/ )
        geographic = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    # puts geographic
    this_res[:geographic] = geographic


    #SUBJECT
    subject= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^SUBJECT:\s*$/ )
        subject = c.next_element().text rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    # puts subject
    this_res[:subject] = subject


    #PERSON
    person= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^PERSON:\s*$/ )
        person = c.next_element().text  rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    # puts person
    this_res[:person] = person



    # LANGUAGE
    language= ""
    doc.css(token_class).each do |c|
      if match = c.text.match(/^LANGUAGE:\s*$/ )
        language = c.next_element().text  rescue nil
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end
    # puts language
    this_res[:language] = language

    # remove existing tokens
    doc.css(token_class).each do |c|
      if match = c.text.match(/^[A-Z\-]+:\s*$/ )
        # puts c.text
        c.next_element.remove rescue nil
        c.remove rescue nil
      end
    end

    # Count of Candidate Name
    # name = this_res[:candiate_name].split(" ")
    count = doc.text.scan(/#{this_res[:candiate_name]}/).length
    # puts "count for #{this_res[:title]} is #{count}"
    this_res[:count_candidate_name] = count

    # Count of opponnet Name
    # name = this_res[:opponent_name].split(" ")
    count = doc.text.scan(/#{this_res[:opponent_name]}/).length
    # puts "count for #{this_res[:title]} is #{count}"
    this_res[:count_opponent_name] = count

    # Bob[\s\n]+[a-z]?\.?[\s\n]*Dole
    #ARTICLE TEXT
    doc_text = doc.css('.c5').text  rescue nil
    # puts doc.text if i == 58
    this_res[:article_text] = doc_text.gsub(/\n+/, ' ').squeeze(' ').gsub(/\s+/, " ").gsub(/\t+/, " ").strip unless doc_text.empty?

    res << this_res

    if !File.exists?(outname)
      CSV.open(outname, "w") { |csv| csv << this_res.keys }
    end
    CSV.open(outname, "ab") do |csv|
      # csv << this_res.keys
      csv << this_res.values
    end
  end
end
# puts res
