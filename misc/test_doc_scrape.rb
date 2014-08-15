require 'iconv'
require './web-scraping-tools/webScraper.rb'
filename = ARGV[0]
# text = File.read(filename)
# ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
# text = ic.iconv(text)
# replace = text.gsub!("<DOCFULL> -->", "<DOCFULL> --><div class='doc_start'>")
# File.open(filename, "w") { |filename| filename.puts replace }
# text = File.read(filename)
# replace = text.gsub!("</DOC> -->", "</DOC> --></div>")
# File.open(filename, "w") { |filename| filename.puts replace }

ws = WebScraper.new
ws.set file_path: filename, debug: false, selector: ".doc_start"
resultSet = ws.select
res = []
wss = WebScraper.new
wss.set file_path: filename, debug: false, selector: "style"
x = wss.select
csslines = x.text.lines.to_a.keep_if {|l| l.include? "font-size: 14pt;" }
title_class = ".c7"
if csslines.any?
  title_class =  csslines[0][/^\.c\d+/] 
end
puts title_class


resultSet.each_with_index do |doc, i|
  # puts doc
end