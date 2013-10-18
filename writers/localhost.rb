require 'traject'
require 'traject/solrj_writer'
require 'socket'


settings do
  if Socket.gethostname =~ /waffle/
    provide "solr.url", "http://localhost:8983/solr/catalog"
  else
    provide "solr.url", "http://solr-sdr-catalog:9033/catalog"
  end
#  provide "solrj_writer.parser_class_name", "BinaryResponseParser"
  provide "solrj_writer.parser_class_name", "XMLResponseParser"
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 2
  provide "solrj_writer.batch_size", 50
  provide "writer_class_name", "Traject::SolrJWriter"
  store 'processing_thread_pool', 8
  store "log.batch_size", 25_000

end