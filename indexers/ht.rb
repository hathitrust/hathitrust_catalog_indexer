
#####################################
############ HATHITRUST STUFF #######
#####################################
#



# make use of the HathiTrust::ItemSet object stuffed into
# [:ht][:items] to pull out all the other stuff we need.


to_field 'ht_searchonly' do |record, acc, context|
  acc << !context.clipboard[:ht][:items].us_fulltext?
end

to_field 'ht_searchonly_intl' do |record, acc, context|
  acc << !context.clipboard[:ht][:items].intl_fulltext? 
end



