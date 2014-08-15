require "active_record"

require 'mysql2'

require 'sqlite3'



# ActiveRecord::Base.logger = Logger.new(File.open("database_#{ARGV[1]}.log", 'w'))

client = Mysql2::Client.new(:host => 'election3.cwet9ycvnvzd.us-east-1.rds.amazonaws.com', :username=>"root", :password=> "!QAZ2wsx")
client.query("CREATE DATABASE IF NOT EXISTS #{ARGV[1]};")
# client.query("USE #{ARGV[1]}")

ActiveRecord::Base.establish_connection(
  :adapter => "mysql2",
  :host => "election3.cwet9ycvnvzd.us-east-1.rds.amazonaws.com",
  :database => ARGV[1],
  :username => "root",
  :password => "!QAZ2wsx",  
  :encoding =>  "utf8",
  :reconnect =>  true,
  :pool =>  15,
  )



# ActiveRecord::Base.establish_connection(
#   :adapter => 'sqlite3',
#   :database =>ARGV[1]
# )

ActiveRecord::Schema.define do
  # unless ActiveRecord::Base.connection.tables.include? 'election_years'
  #   create_table :election_years do |table|
  #       table.column :candidate, :string
  #       table.column :year, :integer
  #   end
  # end
  unless ActiveRecord::Base.connection.tables.include? 'candidates'
    create_table :candidates do |table|
        table.column :name, :string
        table.column :opponent, :string
        table.column :party, :string
    end
  end
  unless ActiveRecord::Base.connection.tables.include? 'articles'
    create_table :articles do |table|
        table.column :title, :text
        table.column :doc_id, :integer
        table.column :publication, :string
    end
  end

  unless ActiveRecord::Base.connection.tables.include? 'bigrams'
    create_table :bigrams do |table|
        table.column :bigram, :string
        table.column :bicount, :integer
        table.references :article
        table.references :candidate
    end
    client.query("use #{ARGV[1]};");
    client.query("alter table bigrams add FOREIGN KEY (article_id) REFERENCES articles(id);");
    client.query("alter table bigrams add FOREIGN KEY (candidate_id) REFERENCES candidates(id);");
    puts "adding index bigrams #{add_index(:bigrams, :bigram)}"
  end

  unless ActiveRecord::Base.connection.tables.include? 'trigrams'
    create_table :trigrams do |table|
        table.column :trigram, :string
        table.column :tricount, :integer
        table.column :article_id, :integer
        table.column :candidate_id, :integer
    end
    client.query("use #{ARGV[1]};");
    client.query("alter table trigrams add FOREIGN KEY (article_id) REFERENCES articles(id);");
    client.query("alter table trigrams add FOREIGN KEY (candidate_id) REFERENCES candidates(id);");
    puts "adding index trigrams #{add_index(:trigrams, :trigram)}"
  end

  

end



# add_index(:suppliers, :name)
# rTdNSBPPMJmoyeYT

# # grid
# ActiveRecord::Base.establish_connection(
#   :adapter => "mysql",
#   :host => "localhost",
#   :database => "zamechek",
#   :username => "zamechek",
#   :password => "rTdNSBPPMJmoyeYT",  
#   :encoding =>  "utf8",
#   :reconnect =>  true,
#   :pool =>  5,

# )

# ActiveRecord::Schema.define do
#     create_table :election_years do |table|
#         table.column :candidate, :string
#         table.column :year, :integer
#     end
 
#     create_table :bigrams do |table|
#         table.column :bigram, :string
#         table.column :election_id, :integer
#     end

#     create_table :trigrams do |table|
#         table.column :trigram, :string
#         table.column :election_id, :integer
#     end
# end

Dir.glob('./models/*').each { |r| require r }


