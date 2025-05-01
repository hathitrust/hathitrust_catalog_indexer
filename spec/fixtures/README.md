sample_record_output_json:

This is the record as output from (not indexed to) solr on 2025-05-01.  This
test passes as of 2025-05-01 and is included as descriptive output of what
traject generates that mostly matches what Solr returns

The following fields are not included that are automatically computed by solr
and/or that require extra data:

authorStr
countryOfPubStr
id_int
oclc_search
callnosort
callnosearch
country_of_pub_facet
deleted

print_holdings (tested separately)
ht_json.heldby (tested separately)

publishDateRange - solr also has the publishDate here?
ht_id_update - is a string as output by traject, int in solr

Several fields output by traject are not included in the output solr record,
and those are not tested here either:
