require 'csv'
require './doc_scrape.rb'

CSV.foreach(ARGV[0], :headers => true) do |row|
  filenames=  row["filename"].split(";").map(&:strip) unless row["filename"].nil?

  filenames.each do |f|
    nex_path = "1980_out"

    if row["yearelected"] == "#{ARGV[1]}"
      docscrape("#{ARGV[1]}/#{f}", row["yearelected"], row["candidatename"], row["Opponent"], row["party"], row["result"], true)
    end
  end unless filenames.nil?
end
