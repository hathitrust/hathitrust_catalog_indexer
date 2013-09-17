require 'traject'

settings do
  provide "solr.url", "http://mojito.umdl.umich.edu:8024/solr/biblio"
  provide "solrj_writer.parser_class_name", "XMLResponseParser"
  provide "solrj_writer.commit_on_close", "true"
  provide "solrj_writer.thread_pool", 2
  provide "solrj_writer.batch_size", 50
  provide "writer_class_name", "Traject::SolrJWriter"
  store 'processing_thread_pool', 3
end