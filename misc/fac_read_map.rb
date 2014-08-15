require 'csv'
require './fac_scrape.rb'

CSV.foreach(ARGV[0], :headers => true) do |row|

  # filenames.each do |f|/Users/zamechek/Dropbox/work/pinar_parsing/elections/1982_out
    # nexPath = "/Users/zamechek/Dropbox/work/pinar_parsing/elections/#{ARGV[1]}_out"
    puts row['facfilename']
    if row["yearelected"] == "#{ARGV[1]}"
      if ARGV[2] == "alt"
        go_alt("#{row['facfilename']}", "#{row['nexFilename']}", row["candidatename"], row["Opponent"], row["yearelected"], row["party"], row["result"], ARGV[3])
      else
        go("#{row['facfilename']}", "#{row['nexFilename']}", row["candidatename"], row["Opponent"], row["yearelected"], row["party"], row["result"])
      end
    end unless row['facfilename'].nil?
  # end unless filenames.nil?
end
