require "active_record"
require "stemmify"
require 'mysql2'
require 'csv'


# ActiveRecord::Base.logger = Logger.new(File.open("database_#{ARGV[1]}.log", 'w'))
# ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "election.cwet9ycvnvzd.us-east-1.rds.amazonaws.com",
  :database => ARGV[0],
  :username => "root",
  :password => "!QAZ2wsx",  
  :encoding =>  "utf8",
  :reconnect =>  true,
  :pool =>  15,
  )
Dir.glob('./models/*').each { |r| require r }

@headers = %w(year candidate opponent title stemmed_name count stemmed_opp count)
@grams= []

def seachname(name, art)
  if name.size > 2        
        search_name = name[0..2].join(' ')
        x =  Trigram.find_by(article_id: art.id,  trigram: search_name)
        @grams << search_name
        x.nil? ? @grams << "0" : @grams << x.tricount
      elsif name.size == 2 
        search_name = name[0..1].join(' ')
        x =  Bigram.find_by(article_id: art.id,  bigram: search_name)
        @grams << search_name
        x.nil? ? @grams << "0" : @grams << x.bicount
      else
        @grams << name
        @grams << "0"
      end
end

def searchGrams(type, art, gramlist, candidate, opponent)
    case type
    when "bi"
        gramlist.each_with_index do |cbi, i |
            x =  Bigram.find_by(article_id: art.id,  bigram: cbi.bigram)
              line = "0"
            if x
                line = x.bicount
            end
            @grams << line
        end
    else
        gramlist.each_with_index do |cbi, i |
            x =  Trigram.find_by(article_id: art.id,  trigram: cbi.trigram)
            line = "0"
            if x
                line = x.tricount
            end
            @grams << line
        end
    end
end

count = Candidate.all.size
Candidate.all.each_with_index do |c, i|
    puts File.file?("#{ARGV[1]}/#{c.name}.csv")
    puts `pwd`
    if File.file?("#{ARGV[1]}/#{c.name}.csv") == true
        puts "file exists, moving on..."
        next
    end
    opp = Candidate.where(name: c.opponent).first
    if opp.nil?
        next
    end
    puts "#{c.name} VS. #{opp.name} #{i} of #{count}"
    can_bi =  Bigram.limit(500).select(:bigram, "sum(bicount) as bicount", :candidate_id).where(candidate_id: c.id).group("bigram").order("sum(bicount) desc, bigram")
    opp_bi =  Bigram.limit(500).select(:bigram, "sum(bicount) as bicount", :candidate_id).where(candidate_id: opp.id).group("bigram").order("sum(bicount) desc, bigram")
    can_tri =  Trigram.limit(500).select(:trigram, "sum(tricount) as tricount", :candidate_id).where(candidate_id: c.id).group("trigram").order("sum(tricount) desc, trigram")
    opp_tri =  Trigram.limit(500).select(:trigram, "sum(tricount) as tricount", :candidate_id).where(candidate_id: opp.id).group("trigram").order("sum(tricount) desc, trigram")
    if  opp_bi.length != can_bi.length
      min = [opp_bi.length, can_bi.length].min
      can_bi =  Bigram.limit(min).select(:bigram, "sum(bicount) as bicount", :candidate_id).where(candidate_id: c.id).group("bigram").order("sum(bicount) desc, bigram")
      opp_bi =  Bigram.limit(min).select(:bigram, "sum(bicount) as bicount", :candidate_id).where(candidate_id: opp.id).group("bigram").order("sum(bicount) desc, bigram")
    end
    if  opp_tri.length != can_tri.length
      min = [opp_tri.length, can_tri.length].min
      can_tri =  Trigram.limit(min).select(:trigram, "sum(tricount) as tricount", :candidate_id).where(candidate_id: c.id).group("trigram").order("sum(tricount) desc, trigram")
      opp_tri =  Trigram.limit(min).select(:trigram, "sum(tricount) as tricount", :candidate_id).where(candidate_id: opp.id).group("trigram").order("sum(tricount) desc, trigram")
    end
    CSV.open("#{ARGV[1]}/#{c.name}_totals.csv", 'ab') do |csv|
        csv << %w(candidate gram count candidate_id  - opponent gram count candidate_id)
        can_bi.zip(opp_bi).each do |cc,o|
            csv << cc.attributes.values.unshift(c.name)  + o.attributes.values.unshift(opp.name)    
        end
        can_tri.zip(opp_tri).each do |cc,o|
            csv << cc.attributes.values.unshift(c.name) + o.attributes.values.unshift(opp.name)
        end
        # csv << can_tri.pluck(:trigram, :tricount)
    end
    CSV.open("#{ARGV[1]}/#{c.name}.csv", 'ab') do |csv|
        csv <<  @headers + can_bi.map { |r| "Candidate Bigram #{r.bigram}" } + opp_bi.map { |r| "Opponent Bigram #{r.bigram}" }  + can_tri.map { |r| "Candidate Trigram #{r.trigram}" } + opp_tri.map { |r| "Opponent Trigram #{r.trigram}" } 
    end
    articles =  Bigram.joins(:article).select("articles.id, title").where(candidate_id: c.id).group(:article_id)
    article_size = articles.length
    stemmed_name = c.name.downcase.strip.gsub(/\s+/, " ").gsub(/[^a-z\s]/, '').split(" ")
    stemmed_opp = opp.name.downcase.strip.gsub(/\s+/, " ").gsub(/[^a-z\s]/, '').split(" ")
    stemmed_name = stemmed_name.map(&:stem)
    stemmed_opp = stemmed_opp.map(&:stem)
    articles.each_with_index do |art,i|
        puts "#{i} of #{article_size} - \t #{art.title}"
        @grams << ARGV[1]
        @grams << c.name
        @grams << opp.name
        @grams << art.title
        seachname(stemmed_name, art)
        seachname(stemmed_opp, art)
         searchGrams("bi", art, can_bi, c, opp)
         searchGrams("bi", art, opp_bi, opp, c)
         searchGrams("tri", art, can_tri, c, opp)
         searchGrams("tri", art, opp_tri, opp, c)
         CSV.open("#{ARGV[1]}/#{c.name}.csv", 'ab') do |csv|
                csv << @grams
            @grams = []
        end
    end
end