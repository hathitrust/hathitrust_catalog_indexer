require 'traject'
require 'traject/null_writer'

settings do
  store "writer_class_name", "Traject::NullWriter"
  store "output_file", "debug.json"
  store 'processing_thread_pool', 3
end

