require 'nokogiri'
require 'date'
no = File.read(ARGV[1])
outlets =no.split("\n").map(&:strip).uniq
# puts outlets

text = File.read(ARGV[0])
x = text.split("<br />")
x = x[1..-1]
out = []
x.each do |art|
    thisarticle= Hash.new
    header =  art.split("&#xa0;")[0..3]
    h = Nokogiri::HTML(header.join(" "))
    thisarticle[:headline] =  h.css('strong').text
    thisarticle[:date] = ""
    thisarticle[:outlet]  = ""
    h.css('p').each do |line|
        date =  Date.strptime(line.text.strip, '%e %B %Y') rescue nil
        thisarticle[:date] = date.to_s unless date.nil?
        # puts line.text.strip
        if outlets.include?(line.text.strip) 
            puts line.text.strip
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
    out << thisarticle
end
puts out