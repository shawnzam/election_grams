# ruby alt_election_parse.rb 1980 input/candidate_list_1980.csv

require 'csv'
require 'stemmify'
require 'date'

def articles_to_hash filename
    csv = CSV.open(filename, :headers => true)
    return csv.to_a.map {|row| row.to_hash }
end

def prepare_text(text)
    common_words_hash = Hash[*File.read("./common_words/cw.txt").split(/[, \n]+/)]
    grams = text.downcase.gsub(/\s+/, " ").gsub(/[^a-z\s]/, '').split(' ')
    grams = grams.delete_if {|w| common_words_hash.has_key? w}
    grams = grams.map(&:stem)
    return grams
end

def count_bigrams bigrams, limit
    bicounts = Hash.new(0)
    bigrams.each do |v|
        bicounts[v.join(" ")] += 1
    end
    return bicounts.sort_by{|k,v| v}.reverse[0..limit].to_h unless limit == 0
    return bicounts.sort_by{|k,v| v}.reverse.to_h
end

def count_trigrams trigrams, limit
    tricounts = Hash.new(0)
    trigrams.each do |v|
        tricounts[v.join(" ")] += 1
    end
    return tricounts.sort_by{|k,v| v}.reverse[0..limit].to_h unless limit == 0
    return tricounts.sort_by{|k,v| v}.reverse.to_h
end

def last_name name
    name = name.encode('us-ascii', {:invalid => :replace, :undef => :replace, :replace => " "})
    name_as_array = name.split(" ")
    if name_as_array.size == 2
        return name_as_array.map(&:downcase).map(&:strip)[-1]
    end
    name_as_array.delete_if {|x|
        ((x =~ /\Ajr[\s\.]*\z/i) == 0) ||
        ((x =~ /\Asr[\s\.]*\z/i) == 0) ||
    ((x =~ /\Aiii[\s]*\z/i) == 0)}
    return name_as_array.map(&:downcase).map(&:strip)[-1].gsub(",", "")
end

def clean_name name
    name = name.encode('us-ascii', {:invalid => :replace, :undef => :replace, :replace => " "})
    name_as_array = name.split(" ")
    if name_as_array.size == 2
        return name_as_array.map(&:downcase).map(&:strip).join(" ")
    end
    name_as_array.delete_if {|x|
        ((x =~ /\Ajr[\s\.]*\z/i) == 0) ||
        ((x =~ /\Asr[\s\.]*\z/i) == 0) ||
    ((x =~ /\Aiii[\s]*\z/i) == 0)}
    return name_as_array.map(&:downcase).map(&:strip).join(" ").gsub(",", "")
end

def count_last_names_in_text row
    candidate_last_name = Regexp.escape(last_name row["candiate_name"].strip)
    opponent_last_name = Regexp.escape(last_name row["opponent_name"].strip)
    article_text = row["article_text"]
    article_text = article_text.encode('us-ascii', {:invalid => :replace, :undef => :replace, :replace => " "})
    row["article_text"]= article_text
    row['count_candidate_name'] = "#{candidate_last_name}, #{article_text.scan(/#{candidate_last_name}/i).size}"
    row['count_opponent_name'] = "#{opponent_last_name}, #{article_text.scan(/#{opponent_last_name}/i).size}"
end

def process_dates row
    begin
        row["doc_date"] = Date.parse(row["doc_date"]) unless (row["doc_date"].nil?) || (row["doc_date"].empty?)
    rescue ArgumentError
        puts "Error - #{row["doc_date"] }"
    end
end

def make_grams row, type
    article_text = row["article_text"]
    grams = prepare_text(article_text)
    return grams.each_cons(type).to_a
end

def remove_dupes articles
    articles.uniq { |e| [e["title"], e["news_outlet"]].join(":") }
end

def keep_article? row, alt_names_hash, candidate_name
    candidate_name = clean_name candidate_name if (candidate_name =~ /\sjr\.*\s|\ssr\.*\s|\siii\.*\s/i)
    alt_names = alt_names_hash[candidate_name.strip]
    return true if (row["article_text"] =~ /#{candidate_name.strip}/i)
    return true if (row["article_text"] =~ /#{candidate_name.strip.split(" ").join('\s+')}/i)
    if alt_names
        alt_names.each do |name|
            return false if name.empty?
            begin
                name = Regexp.escape(name)
            rescue ArgumentError
                puts "Error (name) REGEX - #{name}"
            end
            # stange hack due, still unsure of why this is needed....
            name.gsub!("\\", "")
            last_name = last_name(name)
            begin
                last_name = Regexp.escape(last_name)
            rescue ArgumentError
                puts "Error (last_name) REGEX - #{last_name}"
            end
            return true if (row["article_text"] =~ /#{name.strip}/i)
            return true if (row["article_text"] =~ /mr\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /miss\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /mrs\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /gov\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /rep\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /sen\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /senator\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /representative\.*\s+#{last_name}/i)
            return true if (row["article_text"] =~ /governor\.*\s+#{last_name}/i)
        end
    end
    return false
end

def process_counts articles, bicounts, tricounts, total_articles_to_process
    local_bigrams, local_trigrams = [],[]
    articles.each_with_index do |row, i|
        puts "#{i} of #{total_articles_to_process} complete" if i % 10 == 0
        local_bigrams, local_trigrams = make_grams(row, 2), make_grams(row, 3)
        bigrams = count_bigrams(local_bigrams, 0)
        trigrams = count_trigrams(local_trigrams, 0)
        # bigrams = make_grams(row, 2)
        # trigrams = make_grams(row, 3)

        row["bicounts"] = []
        row["tricounts"] = []
        bicounts.each do |k,v|
            row["bicounts"] << {"gram" => k,  "count" => bigrams[k] || 0 }
        end
        tricounts.each do |k,v|
            row["tricounts"] << {"gram" => k,  "count" => trigrams[k] || 0 }
        end
        row.delete("bigrams")
        row.delete("trigrams")
        # mem_test
        # row.delete("article_text")
    end
end

def write_totals bicounts, tricounts, path_prefix, candidate_name, opponent_name
    CSV.open("#{path_prefix}out_#{candidate_name.strip}_#{opponent_name.strip}_totals.csv", 'ab') do |csv|
        csv << ["bigram", "count", "trigram", "count"]
        bicounts.to_a.zip(tricounts.to_a).each do |bi|
            csv << bi.flatten
        end
    end
end

def write_per_article_totals articles, path_prefix, candidate_name, opponent_name
    return if articles.empty?
    headers = articles.first.keys
    headers.delete_if { |e| (e == "bicounts" || e == "tricounts") }
    headers += articles.first["bicounts"].each_with_index.map{|e,i| "bi #{i+1}"}
    headers += articles.first["tricounts"].each_with_index.map{|e,i|  "tri #{i+1}"}
    CSV.open("#{path_prefix}out_#{candidate_name.strip}_#{opponent_name.strip}_per_article_totals.csv", 'ab') do |csv|
        csv << headers
        articles.each do |row|
            bicounts = row["bicounts"]
            tricounts = row["tricounts"]
            row.delete("bicounts")
            row.delete("tricounts")
            row["article_text"] = row["article_text"].slice(0..MAX_TEXT)
            csv << row.values + bicounts.map{|e| e["count"]} + tricounts.map{|e| e["count"]}
        end
    end
end

def write_removed_file row, path_prefix
    candidate_name = row["candiate_name"]
    opponent_name = row["opponent_name"]
    # row.delete("article_text")
    row["article_text"] = row["article_text"].slice(0..MAX_TEXT)
    if !File.exists?("#{path_prefix}out_#{candidate_name.strip}_#{opponent_name.strip}_removed.csv")
        headers = row.keys
        headers.delete_if { |e| (e == "bicounts" || e == "tricounts") }
        CSV.open("#{path_prefix}out_#{candidate_name.strip}_#{opponent_name.strip}_removed.csv", 'ab')  do |csv|
            csv << headers
        end
    end
    CSV.open("#{path_prefix}out_#{candidate_name.strip}_#{opponent_name.strip}_removed.csv", 'ab') do |csv|
        csv << row.values
    end
end

def remove_articles(articles, candidate_articles, opponent_articles, removed_articles, alt_names_hash, candidate_name, opponent_name, path_prefix)
    candidate_articles.map {|row|
        count_last_names_in_text(row)
        if not(keep_article? row, alt_names_hash, candidate_name)
            removed_articles << row
            write_removed_file row, path_prefix
            articles.delete(row)
        end
    }
    opponent_articles.map{|row|
        count_last_names_in_text(row)
        if not(keep_article? row, alt_names_hash, opponent_name)
            removed_articles << row
            write_removed_file row, path_prefix
            articles.delete(row)
        end
    }
end

def main(candidate_folder, opponent_folder, path_prefix, candidate_name, opponent_name, alt_names_hash)
    filenames =   Dir["#{candidate_folder}"]
    filenames += Dir["#{opponent_folder}"]
    bigrams, trigrams, bicounts, tricounts, articles, removed_articles = [],[],[],[],[],[]
    filenames_size = filenames.length
    filenames.each_with_index do |filename, i|
        puts "#{i+1} of #{filenames_size}\tStarting #{filename}"
        articles += articles_to_hash filename
    end
    articles = remove_dupes articles
    candidate_articles = articles.select{ |row| row['candiate_name'] == candidate_name}
    opponent_articles = articles.select{ |row| row['candiate_name'] == opponent_name}
    articles.size
    puts "#{candidate_name} vs #{opponent_name}"
    puts "#{articles.size} total articles"
    # can be optimized
    puts "removing dupes..."
    remove_articles(articles, candidate_articles, opponent_articles, removed_articles, alt_names_hash, candidate_name, opponent_name, path_prefix)
    total_articles_to_process = articles.size
    puts "#{removed_articles.size} articles removed"
    removed_articles
    candidate_articles = []
    opponent_articles = []
    puts "#{total_articles_to_process} articles remain"
    articles.each_with_index.map { |row, i|
        puts "#{i} of #{total_articles_to_process} complete" if i % 10 == 0
        process_dates(row)
        # local_bigrams, local_trigrams = make_grams(row, 2), make_grams(row, 3)
        # row["bigrams"] = count_bigrams(local_bigrams, 0)
        # row["trigrams"] = count_trigrams(local_trigrams, 0)
        bigrams += make_grams(row, 2)
        trigrams += make_grams(row, 3)
        puts bigrams.size if i % 10 == 0
        puts trigrams.size if i % 10 == 0
    }
    bicounts = count_bigrams bigrams, LIMIT_GRAMS
    tricounts = count_trigrams trigrams, LIMIT_GRAMS
    puts "pricessing counts"
    process_counts(articles, bicounts, tricounts, total_articles_to_process)
    write_totals(bicounts, tricounts, path_prefix, candidate_name, opponent_name)
    write_per_article_totals(articles, path_prefix, candidate_name, opponent_name)
end

LIMIT_GRAMS = 999
MAX_TEXT = 32000
completed_canidates = []
alt_names_hash = {}
CSV.foreach("./clean_alt_names.csv", headers: true) do |row|
    alt_names_hash[row[0].strip] = row.fields[1..-1].compact.map(&:strip)
end
CSV.foreach(ARGV[1], :headers => true) do |row|
    candidate = row['candidatename']
    opponent = row['Opponent']
    next if completed_canidates.include? candidate
    completed_canidates << candidate
    completed_canidates << opponent
    path_prefix = "output/#{ARGV[0]}/"
    Dir.mkdir(path_prefix) unless Dir.exists?(path_prefix)
    main "input/#{ARGV[0]}/#{candidate}_#{ARGV[0]}/*.csv", "input/#{ARGV[0]}/#{opponent}_#{ARGV[0]}/*.csv", path_prefix, candidate, opponent, alt_names_hash# if candidate == "Hillary Rodham Clinton "
end
