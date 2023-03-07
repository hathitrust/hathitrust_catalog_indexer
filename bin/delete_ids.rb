require 'httpx'
require 'zlib'

filename = ARGV[0]


url = ENV['SOLR_URL'] + '/update'

unless url
  raise "SOLR_URL environment variable not defined"
end


client = HTTPX.with(headers: {'Content-Type' => 'application/json'})

def deleted_doc(id)
  {id: id, deleted: true }
end

total = 0
begin
  file = File.open(filename)
  if /\.gz\Z/.match(filename)
    file = Zlib::GzipReader.new(file)
  end

  docs = file.map{|x| deleted_doc(x.chomp) }
  if docs.size > 0
    client.post(url, json: docs)
  else
    puts "File #{filename} is empty"
  end
  puts "Deleted #{docs.size} ids from #{url}\n\n"
rescue Exception => e
  puts "Problem deleting: #{e}"
end
    
