require 'simple_solr_client'

client = SimpleSolrClient::Client.new(9022)
core = client.core('catalog')
core.reload
