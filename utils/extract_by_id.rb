require 'marc'

marcfile = ARGV.shift
ids = ARGV

writer = MARC::Writer.new($stdout)

MARC::Reader.new(marcfile).each do |r|
  rid = r['001'].value
  if ids.include?(rid)
    writer.write(r) 
    ids.delete(rid)
    break if ids.empty?
  end
end
writer.close


