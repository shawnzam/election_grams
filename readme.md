# Election Article Parsing and Analysis - MKTG-1

### Bigrams and Trigrams are counted on a per head to head election basis. A matrix is returned containing occurrences for a candidate's & opponent's most popular bigrams within the candidate's text corpus. A list of the most popular grams is also returned.


#####Articles are removed if we find no mention of a temmed version of the candidate's name within the corpus.

#####Elections years analyzed run from 1980 - 2012 

Using: 

- Ruby
- Stemmify


Each candidate has a directory containing at most two input files. These files are scrapes from a set of Factive and/or Nexus articles. The article text along with the following meta data fields may beParsing present within the input files (located within `input/`):

- candiate_name
- opponent_name
- election_year
- party
- result
- title
- doc_number
- total_docs
- news_outlet
- news_outlet_location
- doc_date
- byline
- section_1
- section_2
- doc_length
- country
- state
- city
- geographic
- subject
- person
- language
- count_candidate_name
- count_opponent_name

Also within `input/` is a candidate list file for each election year. These file map candidates to opponents.

###Usage


    $ ruby election_parse.rb 1980 input candidate_list_1980.csv
    
This will start processing all elections in 1980.

###Output

Up to three and at most two files will be outputted for each election. For candidate **Gary Hart** for example:

1. `out_Gary Hart _per_article.csv` contains the matrix           
2. `out_Gary Hart _removed_articles.csv` containts  articles that did not contain any mention of stemmed Gary Hart's named             
3. `out_Gary Hart _totals.csv` Contains the top 500 bigrams and trigrams for the candidate and opponent.

###Methodology for Candidate Name Searching

Since articles that do not mention the candidate by name need to be removed form the curpos I implemented the following algorithm to filter potential *nameless* artiles:

    def stemmify_name name
      name_as_array = prepare_text name
      if name_as_array.size == 2
        return name_as_array.map(&:downcase).map(&:strip).map(&:stem).join(" ")
      end
      name_as_array.delete_if {|x|
        ((x =~ /\Ajr[\s\.]*\z/i) == 0) ||
        ((x =~ /\Asr[\s\.]*\z/i) == 0) ||
        ((x =~ /\Aiii[\s]*\z/i) == 0) ||
      ((x =~ /\A[a-z]\.*\z/i) == 0) }
      return name_as_array.map(&:downcase).map(&:strip).map(&:stem).join(" ")
    end

This function prepares the name by splitting it on spaces and removing any non recognized characters. If the name splits nicely into two parts, say *Dale Bumpers*, a bigram consisting of *dale bumper* is returned. If the name consists of two or more parts, any mention of Jr, Sr, III or a initial is removed. 
At this point a name like *Henry D. McMaster* would return *henri mcmaster*.

*James David Santin* becomes *jame david santin*

As you can see it is possible for a bi, tri or possibly a longer gram to be returned. If the gram is a bigram, the set of bigrams is searched, and the same for trigrams. If the gram is longer than a trigram, it is truncated to a trigram.


 


