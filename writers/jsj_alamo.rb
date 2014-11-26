require 'traject'
require 'traject/solrj_writer'
require 'socket'
require 'traject/jruby_solr_json_writer'


settings do
  provide "solr.url", "http://alamo.umdl.umich.edu:9033/catalog4/core-1"

#  provide "solrj_writer.parser_class_name", "BinaryResponseParser"
  provide "solrj_writer.parser_class_name", "XMLResponseParser"
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 2
  provide "solrj_writer.batch_size", 50
  provide "writer_class_name", "Traject::JRubySolrJSONWriter"
  store 'processing_thread_pool', 3
  store "log.batch_size", 5_000

end
