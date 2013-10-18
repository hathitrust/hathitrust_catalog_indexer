require 'traject/marc4j_reader'

marcfile = ARGV.shift
id = ARGV.shift

reader = Traject::Marc4JReader.new(File.open(marcfile), {})
reader.each do |r|
  if r['001'].value == id
    puts r 
    break
  end
end