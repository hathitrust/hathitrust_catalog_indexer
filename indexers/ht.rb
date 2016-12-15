

#####################################
############ HATHITRUST STUFF #######
#####################################
#


# Skip calling out to the print holdings database if I'm
# on a machine that doesn't have access
unless ENV['SKIP_PH']
  each_record do |r, context|
    context.clipboard[:ht][:items].fill_print_holdings! if context.clipboard[:ht][:has_items]
  end
end


## OK, so one weird thing we need to do is have different ht_json docs for mirlyn vs hathitrust, since they have differently-formatted 974s. Pass in the :ht symbol only for HT and the to_json will do the Right Thing.

to_field 'ht_json' do |record, acc, context|
  acc << context.clipboard[:ht][:items].to_json(:ht) if context.clipboard[:ht][:has_items]
end


# callnumber from the bib, instead of the item
LC_MAYBE = /\A\s*[A-Z]+\s*\d+/
to_field 'callnumber', extract_marc('050ab:090ab') do |rec, acc|
  acc.delete_if{|x| !(LC_MAYBE.match(x))}
end


to_field 'callnoletters', extract_marc('050ab:090ab', :first=>true) do |rec, acc|
  unless acc.empty?
    m = /\A([A-Za-z]+)/.match(acc[0])
    acc[0] = m[1] if m
  end
end


# make use of the HathiTrust::ItemSet object stuffed into
# [:ht][:items] to pull out all the other stuff we need.


to_field 'ht_searchonly' do |record, acc, context|
  acc << !context.clipboard[:ht][:items].us_fulltext?
end

to_field 'ht_searchonly_intl' do |record, acc, context|
  acc << !context.clipboard[:ht][:items].intl_fulltext? 
end

# Language 008 as string

to_field 'language008_full', marc_languages("008[35-37]") do |record, acc|
  acc.map! {|x| x.gsub(/\|/, '')}
end

# HLB

# Load up the .json file already downloaded from
# https://mirlyn.lib.umich.edu/static/hlb3/hlb3.json

require 'hlb3_load'
HLB.initialize(File.join(File.dirname(__FILE__), '../lib/translation_maps', 'hlb3.json'))


to_field 'hlb3Delimited', extract_marc('050ab:082a:090ab:099a:086a:086z:852hij') do |rec, acc, context|
  acc.map!{|c|  HLB.categories(c).to_a.join('|') }
  acc.compact!
end
