$:.unshift "#{File.dirname(__FILE__)}/../lib"
require "services"

#################################
# COMMON HT STUFF
#################################

# Start off by building up a data structure representing all the 974s
# and stick it in ht_fields. Also, query the database for the print
# holdings along the way with #fill_print_holdings!

each_record do |r, context|
  itemset = HathiTrust::Traject::ItemSet.new

  r.each_by_tag('974') do |f|
    itemset.add HathiTrust::Traject::Item.new_from_974(f) if f['u']
  end

  context.clipboard[:ht][:has_items] = (itemset.size > 0)
  context.clipboard[:ht][:items] = itemset
end

# make use of the HathiTrust::ItemSet object stuffed into
# [:ht][:items] to pull out all the other stuff we need.

to_field 'ht_availability' do |_record, acc, context|
  acc.concat context.clipboard[:ht][:items].us_availability if context.clipboard[:ht][:has_items]
end

to_field 'ht_availability_intl' do |_record, acc, context|
  acc.concat context.clipboard[:ht][:items].intl_availability if context.clipboard[:ht][:has_items]
end

to_field 'ht_count' do |_record, acc, context|
  acc << context.clipboard[:ht][:items].size if context.clipboard[:ht][:has_items]
end

to_field 'ht_heldby' do |_record, acc, context|
  acc.concat context.clipboard[:ht][:items].print_holdings if context.clipboard[:ht][:has_items]
end

to_field 'ht_id' do |_record, acc, context|
  acc.concat context.clipboard[:ht][:items].ht_ids if context.clipboard[:ht][:has_items]
end

to_field 'ht_id_display' do |_record, acc, context|
  context.clipboard[:ht][:items].each do |item|
    dtitle = context.output_hash['title_display'].first.dup
    dtitle << ", #{item.enum_chron}" if item.enum_chron
    values = []
    values << item.htid
    values << item.last_update_date
    values << item.enum_chron
    values << item.enum_pubdate
    values << item.enum_pubdate_range
    values << item.title_sortkey
    values << item.author_sortkey
    values << dtitle
    values = values.map { |x| x.nil? ? '' : x.gsub('|', '/') }
    acc << values.join('|')
  end
end

to_field 'ht_id_update' do |_record, acc, context|
  acc.concat context.clipboard[:ht][:items].last_update_dates if context.clipboard[:ht][:has_items]
  acc.delete_if { |x| x.empty? }
end

to_field 'ht_rightscode' do |_record, acc, context|
  acc.concat context.clipboard[:ht][:items].rights_list if context.clipboard[:ht][:has_items]
end

to_field 'htsource' do |_record, acc, context|
  cc_to_of = HathiTrust::Services.collection_map
  if context.clipboard[:ht][:has_items]
    acc.concat context.clipboard[:ht][:items].collection_codes.map { |x| cc_to_of[x] }
  end
end
