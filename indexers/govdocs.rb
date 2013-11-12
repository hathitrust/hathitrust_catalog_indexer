require 'yaml'

# Make sure we've got an ID
aint = java.util.concurrent.atomic::AtomicInteger.new(400_000_000)
each_record do |r, context|
  if context.output_hash['id'].nil? or context.output_hash['id'].empty?
    context.output_hash['id'] = [aint.getAndIncrement]
  end
end
    

# Get the source based on the filename
filename = ARGV[-1]
if filename =~ /umich/
  to_field 'source' do |r,a|
    a << 'UMICH'
  end
end

if filename =~ /minn_/ 
  to_field 'source' do |r, a|
    a << 'MINNESOTA'
  end
end

agencySubs = {}
agency_normalization_filename = "#{File.dirname(__FILE__)}/../lib/translation_maps/govdocs/agency_normalization.yaml"
YAML.load_file(agency_normalization_filename).each_pair do |k, v| 
  depunct = k.gsub /[\p{Punct}\p{Blank}]+$/, ''
  agencySubs[Regexp.new('\b' + Regexp.escape(depunct) + '\p{Punct}*(?=\b| |\Z)', Regexp::IGNORECASE)] = v
end

normalizeAgency = ->(a) do
  curr = a
  a.gsub! /\[for sale.*/i, ''
  agencySubs.each_pair do |re, v|
    curr.gsub!(re, v)
  end
  curr.gsub!  /[\p{Punct}\p{Blank}]+\Z/, ''
  curr
end
  

  
to_field 'agency', extract_marc('260b:533c:110ab') do |rec, acc|
  values = []
  acc.each do |a|
    values << normalizeAgency[a]
  end
  acc.replace values
end