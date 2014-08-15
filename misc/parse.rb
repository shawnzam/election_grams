require './db_config.rb'
require 'csv'
# for f in input/1982/*; do ruby parse.rb $f yy1982; done
# usage: ruby parse.rb <candidate.csv> <year.db>
CSV.foreach(ARGV[0], :headers => true) do |row|
  puts "#{ARGV[0]} , #{$.}"

  c = Candidate.where(name: row["candiate_name"], opponent: row["opponent_name"], party: row["party"]).first_or_create
  a = Article.create title: row['title'], doc_id: row["doc_number"], publication: ARGV[0].start_with?('1982/factiva_') ? "factiva" : "nexus"
  Bigram.grams(row[-1], c, a)
  Trigram.grams(row[-1], c, a)
 end

