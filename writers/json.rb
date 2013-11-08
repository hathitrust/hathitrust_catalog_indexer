require 'traject'
require 'traject/json_writer'

settings do
  store "writer_class_name", "Traject::JsonWriter"
  store "output_file", "debug.json"
  store 'processing_thread_pool', 0
end

