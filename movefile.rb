files = Dir[ARGV[0]]

files.each do |f|
  puts f
  name = f.match(/out2\/(.*)_/).captures[0]
  if Dir.exists?("input/1980/#{name}_1980/")
    system "cp '#{f}' 'input/1980/#{name}_1980/'"
  else
    Dir.mkdir("input/1980/#{name}_1980/")
    system "cp '#{f}' 'input/1980/#{name}_1980/'"
  end

end
