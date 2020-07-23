#####################################
############ HATHITRUST STUFF #######
#####################################
#

# Skip calling out to the print holdings database if I'm
# on a machine that doesn't have access
unless ENV['NO_DB']
  each_record do |_r, context|
    context.clipboard[:ht][:items].fill_print_holdings! if context.clipboard[:ht][:has_items]
  end
end

## OK, so one weird thing we need to do is have different ht_json docs for mirlyn vs hathitrust, since they have differently-formatted 974s. Pass in the :ht symbol only for HT and the to_json will do the Right Thing.

to_field 'ht_json' do |_record, acc, context|
  acc << context.clipboard[:ht][:items].to_json(:ht) if context.clipboard[:ht][:has_items]
end

# callnumber from the bib, instead of the item
LC_MAYBE = /\A\s*[A-Z]+\s*\d+/.freeze
to_field 'callnumber', extract_marc('050ab:090ab') do |_rec, acc|
  acc.delete_if { |x| !LC_MAYBE.match(x) }
end

to_field 'callnoletters', extract_marc('050ab:090ab', first: true) do |_rec, acc|
  unless acc.empty?
    m = /\A([A-Za-z]+)/.match(acc[0])
    acc[0] = m[1] if m
  end
end

# make use of the HathiTrust::ItemSet object stuffed into
# [:ht][:items] to pull out all the other stuff we need.

to_field 'ht_searchonly' do |_record, acc, context|
  acc << !context.clipboard[:ht][:items].us_fulltext?
end

to_field 'ht_searchonly_intl' do |_record, acc, context|
  acc << !context.clipboard[:ht][:items].intl_fulltext?
end

# Language 008 as string

to_field 'language008_full', marc_languages('008[35-37]') do |_record, acc|
  acc.map! { |x| x.gsub(/\|/, '') }
end

# HLB

logger.info 'Starting load of HLB'
require 'high_level_browse'
hlb = HighLevelBrowse.load(dir: Pathname.new(__dir__).parent.realpath + 'lib' + 'translation_maps')
logger.info 'Finished load of HLB'

to_field 'hlb3Delimited', extract_marc('050ab:082a:090ab:099a:086a:086z:852hij') do |_rec, acc, _context|
  acc.map! { |c| hlb[c] }
  acc.compact!
  acc.uniq!
  acc.flatten!(1)
  # Turn them into pipe-delimited strings
  acc.map! { |c| c.to_a.join(' | ') }
end

# Compute the title_item_sortkey and author_item_sortkey

each_record do |r, context|
  items = context.clipboard[:ht][:items]
  fields = context.output_hash
  bibdate = HathiTrust::BibDate.get_bib_date(r)

  items.each do |item|
    item.title_sortkey = [
      fields['title_sortkey'],
      fields['author_sortkey'],
      item.enum_pubdate, # from 974$y, which always has a value
      item.enumchron_sortstring
    ].join(' AAA ').downcase

    item.author_sortkey = [
      fields['author_sortkey'],
      fields['title_sortkey'],
      item.enum_pubdate, # from 974$y, which always has a value
      item.enumchron_sortstring
    ].join(' AAA ').downcase
  end
end

# All the print holdings from all the items
to_field 'print_holdings' do |_record, acc, context|
  acc.replace context.clipboard[:ht][:items].print_holdings
end
