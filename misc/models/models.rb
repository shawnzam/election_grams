# require './db_config.rb'
require 'stemmify'
# class ElectionYear < ActiveRecord::Base

# end
class Article < ActiveRecord::Base
  has_many :bigrams
  has_many :trigrams
  #maybe add belongs_to candidate here
end
class Candidate < ActiveRecord::Base
  has_many :bigrams
  has_many :trigrams
end

class Bigram < ActiveRecord::Base
  @@common_words_hash = Hash[*File.read("common_words/cw.txt").split(/[, \n]+/)]
  belongs_to :article
  belongs_to :candidate
  def self.grams(string, candidate, article)
    if string.nil?
  string = ""
    end
    string = string.encode('us-ascii', {:invalid => :replace, :undef => :replace, :replace => ' '})
    grams =string.downcase.gsub(/\s+/, " ").gsub(/[^a-z\s]/, '').split(' ')#.each_cons(2).to_a
    grams = grams.delete_if {|w| @@common_words_hash.has_key? w}
    grams = grams.map(&:stem)
    grams = grams.each_cons(2).to_a
    b = Hash.new(0)
    # grams.sort!
    grams.each do |v|
      b[v.join(" ")] += 1
    end
    b = b.sort_by{|k,v| v}.reverse
    bigrams = []
    count = 0
    b.each do |k, v|
      # count += 1
      # if count <= 500
        bigrams <<  {bigram: k, candidate_id: candidate.id, article_id: article.id, bicount: v}
      # end
    end
    Bigram.create bigrams
  end
end

class Trigram < ActiveRecord::Base
  @@common_words_hash = Hash[*File.read("common_words/cw.txt").split(/[, \n]+/)]
  belongs_to :article
  belongs_to :candidate
  def self.grams(string, candidate, article)
    if string.nil?
      string = ""
    end
    string = string.encode('us-ascii', {:invalid => :replace, :undef => :replace, :replace => ' '})
    grams =string.downcase.gsub(/\s+/, " ").gsub(/[^a-z\s]/, '').split(' ')#.each_cons(2).to_a
    grams = grams.delete_if {|w| @@common_words_hash.has_key? w}
    grams = grams.map(&:stem)
    grams = grams.each_cons(3).to_a
    b = Hash.new(0)
    # grams.sort!
    grams.each do |v|
      b[v.join(" ")] += 1
    end
    b = b.sort_by{|k,v| v}.reverse
    trigrams = []
    count = 0
    b.each do |k, v|
      # count += 1
      # if count <= 500
        trigrams <<  {trigram: k, candidate_id: candidate.id, article_id: article.id, tricount: v}
      # end
    end
    Trigram.create trigrams
  end
end
