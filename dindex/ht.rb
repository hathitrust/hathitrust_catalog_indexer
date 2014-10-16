

#####################################
############ HATHITRUST STUFF #######
#####################################
#

# callnumber from the bib, instead of the item
to_dfield 'callnumber_s_s', extract_marc('050ab:090ab')
to_dfield 'callnoletters_s', extract_marc('050ab:090ab', :first=>true) do |rec, acc|
  unless acc.empty?
    m = /\A([A-Za-z]+)/.match(acc[0])
    acc[0] = m[1] if m
  end
end


# make use of the HathiTrust::ItemSet object stuffed into
# [:ht][:items] to pull out all the other stuff we need.


to_dfield 'ht_searchonly_bool' do |record, acc, context|
  acc << !context.clipboard[:ht][:items].us_fulltext?
end

to_dfield 'ht_searchonly_intl_bool' do |record, acc, context|
  acc << !context.clipboard[:ht][:items].intl_fulltext? 
end



