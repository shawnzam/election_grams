require 'csv'
csv = CSV.open(ARGV[0], headers: true)
p csv.headers
puts csv.headers
print csv.headers
puts csv.inspect