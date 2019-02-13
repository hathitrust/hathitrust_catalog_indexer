require 'traject'
require 'traject/solrj_writer'
require 'socket'


settings do
  provide "solr.url", ENV["SOLR_URL"]
  provide "solrj_writer.parser_class_name", "XMLResponseParser"
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 2
  provide "solrj_writer.batch_size", 80
  provide "writer_class_name", "Traject::SolrJWriter"
  store 'processing_thread_pool', 15
  store "log.batch_size", 50_000

end
