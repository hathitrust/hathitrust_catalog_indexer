$:.unshift '../lib'
require 'ht_dbh'

dbh = HathiTrust::DBH.new

dbh.execute("select namespace, institution from ht_namespaces").each do |row|
  puts row[0..1].join("\t")
end
