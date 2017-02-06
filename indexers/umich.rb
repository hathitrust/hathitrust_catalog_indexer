require 'umich_traject'

## OK, so one weird thing we need to do is have different ht_json docs for mirlyn vs hathitrust, since they have differently-formatted 974s. Pass in the :mirlyn symbol and the to_json will do the Right Thing.

to_field 'ht_json' do |record, acc, context|
  acc << context.clipboard[:ht][:items].to_json(:mirlyn) if context.clipboard[:ht][:has_items]
end


# callnumber from the items
to_field 'callnumber', extract_marc('852hij')
to_field 'callnoletters', extract_marc('852hij:050ab:090ab', :first=>true) do |rec, acc|
  unless acc.empty?
    m = /\A([A-Za-z]+)/.match(acc[0])
    acc[0] = m[1] if m
  end
end


### Last time the record was changed ####
# cat_date -- the maximum value in a 972c

to_field 'cat_date', extract_marc('972c') do |rec, acc, context|
  acc << '00000000'
  acc.replace [acc.max]
end
  

#### Fund that was used to pay for it ####

to_field 'fund', extract_marc('975a')
to_field 'fund_display' do |rec, acc|
  acc.concat Traject::MarcExtractor.cached('975ad', :separator=>' - ').extract(rec)
end


##### Location ####

to_field 'institution', extract_marc('971a', :translation_map=>'umich/institution_map')

building_map = Traject::UMich.building_map
to_field 'building', extract_marc('852bc:971a') do |rec, acc|
  acc.map!{|code| building_map[code.strip]}
  acc.flatten!
end

location_map = Traject::UMich.location_map
to_field 'location', extract_marc('971a:852b:852bc') do |rec, acc|
  acc.map!{|code| location_map[code.strip]}
  acc.flatten!
end


  
  
  
### High Level Browse ###

# Load up the .json file already downloaded from
# https://mirlyn.lib.umich.edu/static/hlb3/hlb3.json


require 'hlb3_load'
HLB.initialize(File.join(File.dirname(__FILE__), '../lib/translation_maps', 'hlb3.json'))




to_field 'hlb3Delimited', extract_marc('050ab:082a:090ab:099|*0|a:086a:086z:852|0*|hij') do |rec, acc, context|
  errs = 0
  begin
    acc.map! {|c| HLB.categories(c)}
    acc.compact!
    acc.uniq!
    acc.flatten!(1)

    # Get the individual conmponents and stash them
    components = acc.flatten.to_a
    context.output_hash['hlb3'] = components unless components.empty?

    # Turn them into pipe-delimited strings
    acc.map! {|c| c.join(' | ')}

  rescue => e
    errs += 1
    abort(0) if errs > 2
    retry
  end
end 
  



# UMich-specific stuff based on Hathitrust. For Mirlyn, we say something is
# htso iff it has no ht fulltext, and no other holdings. Basically, this is
# the "can I somehow get to the full text of this without resorting to
# ILL" field in Mirlyn


# An item in Mirlyn is search only if
#  - there's no HT fulltext
#  - there's no other physical or electronic holdings


# First we'll figure out whether we have holdings
F973b = Traject::MarcExtractor.cached('973b')
F852b = Traject::MarcExtractor.cached('852b')

each_record do |rec, context|
  has_non_ht_holding = false
  
  F973b.extract(rec).each do |val|
    has_non_ht_holding = true if ['avail_online', 'avail_circ'].include? val
  end
  
  F852b.extract(rec).each do |val|
    has_non_ht_holding = true unless val == 'SDR'
  end
  
  context.clipboard[:ht][:has_non_ht_holding] = has_non_ht_holding
end


to_field 'ht_searchonly' do |record, acc, context|
  has_ht_fulltext = context.clipboard[:ht][:items].us_fulltext?
  if has_ht_fulltext or context.clipboard[:ht][:has_non_ht_holding]
    acc << false
  else
    acc << true
  end
end

to_field 'ht_searchonly_intl' do |record, acc, context|
  has_ht_fulltext = context.clipboard[:ht][:items].intl_fulltext? 
  if has_ht_fulltext or context.clipboard[:ht][:has_non_ht_holding]
    acc << false
  else
    acc << true
  end
end


#### Availability ####
#
to_field 'availability', extract_marc('973b', :translation_map => 'umich/availability_map_umich')
