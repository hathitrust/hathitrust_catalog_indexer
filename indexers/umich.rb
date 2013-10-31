#### Availability ####

# availability

### Last time the record was changed ####
# cat_date

#### Fund that was used to pay for it ####

# fund
# fund_display

##### Location ####

# institution
# building
# location

### High Level Browse ###

# hlb3
# hlb3Delimited




# UMich-specific stuff based on Hathitrust. For Mirlyn, we say something is
# htso iff it has no ht fulltext, and no other holdings. Basically, this is
# the "can I somehow get to the full text of this without resorting to
# ILL" field in Mirlyn

to_field 'ht_searchonly' do |record, acc, context|
  has_ht_fulltext = context.clipboard[:ht][:items].us_fulltext?
end

to_field 'ht_searchonly_intl' do |record, acc, context|
  has_ht_fulltext = context.clipboard[:ht][:items].intl_fulltext? 
end
