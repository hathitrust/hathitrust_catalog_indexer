require 'yaml'
require 'open-uri'

url = 'http://mirlyn-aleph.lib.umich.edu/hathitrust_collection_map.yaml'

tmap_dir = File.expand_path(File.join("..", 'lib', 'translation_maps', 'ht'), File.dirname(__FILE__))

begin
  data = YAML.load(open(url).read)
rescue OpenURI::HTTPError => e
  $stderr.puts "Problem getting #{url}: #{e}" 
  exit
end

# Create the "collection_code_to_original_from.yaml" map

output_file = 
ccof = {}
data.each_pair do |cc, h|
  ccof[cc] = h['original_from']
end

File.open(File.join(tmap_dir, 'collection_code_to_original_from.yaml'), 'w:utf-8') {|f| f.puts ccof.to_yaml}


