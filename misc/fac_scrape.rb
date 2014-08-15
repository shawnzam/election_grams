require '../web-scraping-tools/webScraper.rb'

require 'csv'
require 'iconv'

def go(filename, nexfile, candiate_name, opponent_name, election_year, party, result)

  filenames=  nexfile.split(";").map(&:strip) unless nexfile.nil?
  facfilenames=  filename.split(";").map(&:strip) unless filename.nil?


  nexTitleMap = Array.new
  nexPath = "/Users/zamechek/elections/#{ARGV[1]}_out2"

  filenames.each do |f|
    puts f
    CSV.foreach("#{nexPath}/#{f}_out.csv", :headers => true) do |row|
      nexTitleMap << row["title"].gsub(/\n+/, ' ').squeeze(' ').gsub(/\s+/, " ").gsub(/\t+/, " ").strip
    end
  end
  # puts nexTitleMap
  facfilenames.each_with_index do |filename, i|
    dir_name = "#{candiate_name}_#{ARGV[1]}"
    Dir.mkdir dir_name unless File.exists?(dir_name)
    outname = "#{dir_name}/#{candiate_name}_#{ARGV[1]}_#{i}_factiva.csv"
    puts "Starting #{filename}"
    wss = WebScraper.new
    wss.set file_path: "#{ARGV[1]}/#{filename}", debug: false, selector: "table"

    factivaArticleList = Array.new
    x = wss.select
    a = []
    x.css('tr').each do |x|
      a << x.css('td').first.text.strip
      a.uniq!
    end
    puts a
    x.css('table').each_with_index do |x, i|
      data = Hash.new
      data['candiate_name'] = candiate_name
      data['opponent_name'] = opponent_name
      data['election_year'] = election_year
      data['party'] = party
      data['result'] = result
      keyvals = {}
      x.css('tr').each do |row|
        # data[row.css('td').first.text.strip] = row.css('td').last.text.gsub(/\n+/, ' ').squeeze(' ').gsub(/\s+/, " ").gsub(/\t+/, " ").strip
        keyvals[row.css('td').first.text.strip] = row.css('td').last.text.gsub(/\n+/, ' ').squeeze(' ').gsub(/\s+/, " ").gsub(/\t+/, " ").strip
      end
      data["title"] = keyvals["HD"]
      data["doc_number"] = "#{i}"
      data["total_docs"] = "factiva"
      data["news_outlet"] = keyvals["SN"]
      data["news_outlet_location"] = "factiva"
      data["doc_date"] = keyvals["PD"]
      data["byline"] = keyvals["BY"]
      data["section_1"] = keyvals["SC"]
      data["section_2"] = keyvals["PG"]
      data["doc_length"] = keyvals["WC"]
      data["country"] = "factiva"
      data["state"] = "factiva"
      data["city"] = "factiva"
      data["geographic"] = "factiva"
      data["subject"] = "factiva"
      data["person"] = "factiva"
      data["language"] = keyvals["LA"]
      article_text = "#{keyvals["LP"]} #{keyvals["TD"]}"
      data["count_candidate_name"] = article_text.scan(/#{candiate_name}/).length
      data["count_opponent_name"] = article_text.scan(/#{opponent_name}/).length
      data["article_text"] = article_text
      factivaArticleList << data
      # candiate_name  opponent_name election_year party result  title doc_number  total_docs  news_outlet news_outlet_location  doc_date  byline  section_1 section_2 doc_length
      # country state city  geographic  subject person  language  count_candidate_name  count_opponent_name article_text
    end
    puts factivaArticleList.size

    factivaArticleList.delete_if { |x|  nexTitleMap.include? x['title'].gsub("\u00A0", "")} rescue nil

    puts factivaArticleList.size



    factivaArticleList.each do |d|
      if !File.exists?(outname)
        CSV.open(outname, "w") { |csv| csv << d.keys }
      end
      CSV.open(outname, "ab") do |csv|
        # csv << this_res.keys
        csv << d.values
      end
    end
  end
end

def go_alt(filename, nexfile, candiate_name, opponent_name, election_year, party, result, nolist)
  require 'nokogiri'
  require 'date'
  no = File.read(nolist)
  outlets =no.split("\n").map(&:strip).uniq

  filenames=  nexfile.split(";").map(&:strip) unless nexfile.nil?
  facfilenames =  filename.split(";").map(&:strip) unless filename.nil?


  nexTitleMap = Array.new
  nexPath = "/Users/zamechek/elections/#{ARGV[1]}_out"

  filenames.each do |f|
    puts f
    CSV.foreach("#{nexPath}/#{f}_out.csv", :headers => true) do |row|
      nexTitleMap << row["title"].gsub(/\n+/, ' ').squeeze(' ').gsub(/\s+/, " ").gsub(/\t+/, " ").strip
    end
  end
  factivaArticleList = Array.new
  facfilenames.each_with_index do |filename, i|
    outname = "factiva_#{candiate_name}_#{i}_out_.csv"
    puts "Starting #{filename}"
    text = File.read("#{ARGV[1]}/#{filename}")
    x = text.split("<br />")
    x = x[1..-1]

    x.each do |art|
      thisarticle= Hash.new
      header =  art.split("&#xa0;")[0..3]
      h = Nokogiri::HTML(header.join(" "))

      thisarticle['candiate_name'] = candiate_name
      thisarticle[:headline] =  h.css('strong').text
      thisarticle[:date] = ""
      thisarticle[:outlet]  = ""
      h.css('p').each do |line|
        date =  Date.strptime(line.text.strip, '%e %B %Y') rescue nil
        thisarticle[:date] = date.to_s unless date.nil?
        # puts line.text.strip
        if outlets.include?(line.text.strip)
          # puts line.text.strip
          thisarticle[:outlet] = line.text.strip
        end
      end
      if match = header.join(" ").match(/(\d*) words/)
        words = match.captures
        thisarticle[:words] = words.first
      end

      article=  art.split("&#xa0;")[3..-1]
      z = Nokogiri::HTML(article.join(" "))
      thisarticle[:text]  = z.text.gsub(/\n+/, ' ').squeeze(' ').gsub(/\s+/, " ").gsub(/\t+/, " ").strip
      factivaArticleList << thisarticle
    end
    puts factivaArticleList.size

    factivaArticleList.delete_if { |x|  nexTitleMap.include? x['title'].gsub("\u00A0", "")} rescue nil

    puts factivaArticleList.size
    factivaArticleList.each do |d|
      if !File.exists?(outname)
        CSV.open(outname, "w") { |csv| csv << d.keys }
      end
      CSV.open(outname, "ab") do |csv|
        # csv << this_res.keys
        csv << d.values
      end
    end
  end
end
