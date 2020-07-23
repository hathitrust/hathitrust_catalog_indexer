require 'yaml'

# Make sure we've got a unique ID
filename = ARGV[-1]

if filename =~ /all_minn_records/i
  aint = java.util.concurrent.atomic::AtomicInteger.new(400_000_000)
elsif filename =~ /itemless/i
  aint = java.util.concurrent.atomic::AtomicInteger.new(450_000_000)
elsif filename =~ /umich/
  aint = nil
elsif filename =~ /cic/i
  aint = java.util.concurrent.atomic::AtomicInteger.new(500_000_000)
end

if aint
  each_record do |_r, context|
    context.output_hash['original_id'] = context.output_hash['id'] if context.output_hash['id']
    context.output_hash['id'] = [aint.getAndIncrement]
  end
end

# Get the source based on the filename
if filename =~ /umich/
  to_field 'source' do |_r, a|
    a << 'UMICH'
  end
end

if filename =~ /minn/
  to_field 'source' do |_r, a|
    a << 'MINNESOTA'
  end
end

if filename =~ /cic/i
  to_field 'source' do |_r, a|
    a << 'CIC'
  end

  to_field 'oclc', extract_marc('001') do |_r, a, _c|
    a.map! { |x| x.gsub!(/\D/, '') }
  end
end

agencySubs = {}
agency_normalization_filename = "#{File.dirname(__FILE__)}/../lib/translation_maps/govdocs/agency_normalization.yaml"
YAML.load_file(agency_normalization_filename).each_pair do |k, v|
  depunct = k.gsub(/[\p{Punct}\p{Blank}]+$/, '')
  agencySubs[Regexp.new('\b' + Regexp.escape(depunct) + '\p{Punct}*(?=\b| |\Z)', Regexp::IGNORECASE)] = v
end

normalizeAgency = lambda do |a|
  curr = a
  a.gsub!(/\[for sale.*/i, '')
  agencySubs.each_pair do |re, v|
    curr.gsub!(re, v)
  end
  curr.gsub!(/[\p{Punct}\p{Blank}]+\Z/, '')
  curr
end

to_field 'agency', extract_marc('260b:533c:110ab') do |_rec, acc|
  values = []
  acc.each do |a|
    values << normalizeAgency[a]
  end
  acc.replace values
end
