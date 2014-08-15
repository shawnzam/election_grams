require 'csv'
require 'stemmify'


def prepare_text(text)
  text = text.encode('us-ascii', {:invalid => :replace, :undef => :replace, :replace => " "})
  grams = text.downcase.gsub(/\s+/, " ").gsub(/[^a-z\s]/, '').split(' ')
  grams = grams.delete_if {|w| @@common_words_hash.has_key? w}
  grams = grams.map(&:stem)
  return grams
end

def stemmify_name name
  # name_as_array = prepare_text name
  name_as_array = name.split(" ")
  if name_as_array.size == 2
    return name_as_array.map(&:downcase).map(&:strip).map(&:stem).join(" ")
  end
  name_as_array.delete_if {|x|
    ((x =~ /\Ajr[\s\.]*\z/i) == 0) ||
    ((x =~ /\Aiii[\s]*\z/i) == 0) ||
  ((x =~ /\A[a-z]\.*\z/i) == 0) }
  return name_as_array.map(&:downcase).map(&:strip).map(&:stem).join(" ")
end

def process_candidate_articles(filename)
  CSV.foreach(filename, :headers => true) do |row|
    if $. == 2
      # candiate_name mispelling exists on input header
      @candidate_name = row["candiate_name"]
      @opponent_name = row["opponent_name"]
      @candidate_name_stem = stemmify_name row["candiate_name"]
      @opponent_name_stem = stemmify_name row["opponent_name"]

    end
    candidate_bicounts =Hash.new(0)
    candidate_tricounts =Hash.new(0)
    string = row[-1]
    if string.nil?
      string = ""
    end
    grams = prepare_text(string)
    bigrams = grams.each_cons(2).to_a
    trigrams = grams.each_cons(3).to_a
    bigrams.each do |v|
      candidate_bicounts[v.join(" ")] += 1
    end
    if (candidate_bicounts[@candidate_name_stem] == 0) && (candidate_bicounts[@opponent_name_stem] == 0)
      CSV.open("out_#{@candidate_name}_removed_articles.csv", 'ab') do |csv|
        csv << row
      end
      next
    end
    # here is where a check needs to go for can and opp name counts, if b

    bigrams.each do |v|
      @candidate_master_bigram_counts[v.join(" ")] += 1
    end
    trigrams.each do |v|
      candidate_tricounts[v.join(" ")] += 1
      @candidate_master_trigram_counts[v.join(" ")] += 1
    end
    article_hash = Hash.new(0)
    row.to_a[0..-2].each_with_index do |g,i|
      article_hash[row.headers[i]] = row[i]
      article_hash[:bigrams] = candidate_bicounts
      article_hash[:trigrams] = candidate_tricounts
    end
    @candidate_per_article_grams << article_hash
  end
end

def process_opponent_articles(filename)
  CSV.foreach(filename, :headers => true) do |row|
    if $. == 2
      opponent_name = row["opponent_name"]
    end
    opponent_bicounts =Hash.new(0)
    opponent_tricounts =Hash.new(0)
    string = row[-1]
    if string.nil?
      string = ""
    end
    grams = prepare_text(string)
    bigrams = grams.each_cons(2).to_a
    trigrams = grams.each_cons(3).to_a
    bigrams.each do |v|
      opponent_bicounts[v.join(" ")] += 1
      @opponent_master_bigram_counts[v.join(" ")] += 1
    end
    trigrams.each do |v|
      opponent_tricounts[v.join(" ")] += 1
      @opponent_master_trigram_counts[v.join(" ")] += 1
    end
  end
end

def write_candiates_totals_csv
  CSV.open("out_#{@candidate_name}_totals.csv", 'ab') do |csv|
    # csv << %w(gram count opp_gram count)
    csv << ["#{@candidate_name}gram", "count", "#{@opponent_name}gram" ,"count"]
    @candidate_master_bigram_counts.zip(@opponent_master_bigram_counts).each {|elem| csv << elem.flatten}
    @candidate_master_trigram_counts.zip(@opponent_master_trigram_counts).each {|elem| csv << elem.flatten}
  end
end

def count_per_article
  @candidate_per_article_grams.each do |article|
    thisrow = Array.new
    @candidate_master_bigram_counts.each do |bi|
      thisrow << article[:bigrams][bi.first]
    end
    @candidate_master_trigram_counts.each do |tri|
      thisrow << article[:trigrams][tri.first]
    end
    @opponent_master_bigram_counts.each do |bi|
      thisrow << article[:bigrams][bi.first]
    end
    @opponent_master_trigram_counts.each do |tri|
      thisrow << article[:trigrams][tri.first]
    end
    @countrows << thisrow.flatten
  end
end

def write_candidate_per_article_totals
  # remove bi and trigram headers
  headers =  @candidate_per_article_grams.first.keys.delete_if {|h| h.class == Symbol}
  headers +=
    @candidate_master_bigram_counts.map {|row| "Candidate Bigram ; #{row.first}"} +
    @candidate_master_trigram_counts.map {|row| "Candidate Trigram ; #{row.first}"} +
    @opponent_master_bigram_counts.map {|row| "Opponnent Bigram ; #{row.first}"} +
    @opponent_master_trigram_counts.map {|row| "Opponnent Trigram ; #{row.first}"}
  CSV.open("out_#{@candidate_name}_per_article.csv", 'ab') do |csv|
    csv << headers
    @candidate_per_article_grams.each_with_index do |article, i|
      article_info = article.select {|k,v|  not v.is_a?(Hash)}
      foo = article_info.values + @countrows[i]
      csv << foo
    end
  end
end
#globals
@@common_words_hash = Hash[*File.read("./common_words/cw.txt").split(/[, \n]+/)]
@candidate_master_bigram_counts = Hash.new(0)
@candidate_master_trigram_counts = Hash.new(0)
@opponent_master_bigram_counts = Hash.new(0)
@opponent_master_trigram_counts = Hash.new(0)
@candidate_per_article_grams = Array.new
@candidate_name = ""
@opponent_name = ""
@candidate_name_stem = ""
@opponent_name_stem = ""

def main
  # filenames=  ARGV[0].split(";").map(&:strip) unless ARGV[0].nil?
  # puts ARGV[0], ARGV[1]
  filenames=   Dir[ARGV[0]]
  f_size = filenames.length
  filenames.each_with_index do |filename, i|
    puts "Candidate\t#{i+1} of #{f_size}\tStarting #{filename}"
    process_candidate_articles filename
  end
  # filenames=  ARGV[1].split(";").map(&:strip) unless ARGV[0].nil?
  opp_filenames=  Dir[ARGV[1]]
  f_size = opp_filenames.length

  opp_filenames.each_with_index do |filename, i|
    puts "Opponent\t#{i+1} of #{f_size}\tStarting #{filename}"
    process_opponent_articles filename
  end


  #trim lists to 500
  puts "Candidate\tTask 1 of 7\tTrimming bigrams"
  @candidate_master_bigram_counts = @candidate_master_bigram_counts.sort_by{|k,v| v}.reverse[0..499]
  puts "Candidate\tTask 2 of 7\tTrimming trigrams"
  @candidate_master_trigram_counts = @candidate_master_trigram_counts.sort_by{|k,v| v}.reverse[0..499]
  puts "Opponnent\tTask 3 of 7\tTrimming bigrams"
  @opponent_master_bigram_counts = @opponent_master_bigram_counts.sort_by{|k,v| v}.reverse[0..499]
  puts "Opponnet\tTask 4 of 7\tTrimming trigrams"
  @opponent_master_trigram_counts = @opponent_master_trigram_counts.sort_by{|k,v| v}.reverse[0..499]

  puts "Candidate\tTask 5 of 7\tWriting totals"
  write_candiates_totals_csv

  @countrows =Array.new
  puts "Candidate\tTask 6 of 7\tCounting article totals"
  count_per_article
  puts "Candidate\tTask 7 of 7\tWriting article totals"
  write_candidate_per_article_totals
end

main
