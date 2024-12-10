# frozen_string_literal: true

require "traject"

require_relative "common"
require_relative "../services"

module CICTL
  class Indexer
    include Common
    DEFAULT_READER_NAME = "jsonl"
    DEFAULT_WRITER_NAME = "localhost"
    COLLECTION_MAP_FILE = "collection_code_to_original_from.yaml"

    attr_reader :reader_path, :writer_path

    def initialize(reader: nil, writer: nil)
      @reader_path = find_reader reader
      @writer_path = find_writer writer
      config_paths = [reader_path, writer_path]
      %w[common common_ht ht subjects].each do |conf|
        config_paths << File.join(home, "indexers", conf + ".rb")
      end
      traject_logger = HathiTrust::Services[:logger_factory].logger(owner: "Traject")
      @indexer = Traject::Indexer::MarcIndexer.new(logger: traject_logger) do |ind|
        config_paths.each { |config_path| load_config_file(config_path) }
      end
    end

    def run(marcfile)
      logger.info "Working in #{home}"
      fatal "Can't read marcfile '#{marcfile}'" unless File.readable?(marcfile)
      fatal "Can't find reader #{reader_path}" unless File.exist?(reader_path)
      fatal "Can't find writer #{writer_path}" unless File.exist?(writer_path)
      logger.debug "reader: #{reader_path}; writer: #{writer_path}"
      call_indexer marcfile
    end

    private

    def call_indexer(marcfile)
      logger.info "Indexing from #{marcfile}, reader #{reader_path} writer #{writer_path} (#{HathiTrust::Services[:solr_url]})"
      success = @indexer.process File.open(marcfile, "r")
      unless success
        fatal "traject failed, shutting down"
      end
    end

    # Returns full path to traject reader file based on name or partial path
    def find_reader(reader_name)
      return default_reader_path unless reader_name
      find_custom_config_file("readers", reader_name)
    end

    # Returns full path to traject writer file based on name or partial path
    def find_writer(writer_name)
      return default_writer_path unless writer_name
      find_custom_config_file("writers", writer_name)
    end

    def default_reader_path
      @default_reader_path ||= File.join(home, "readers", DEFAULT_READER_NAME + ".rb")
    end

    def default_writer_path
      @default_writer_path ||= File.join(home, "writers", DEFAULT_WRITER_NAME + ".rb")
    end

    # Find custom --reader or --writer path as absolute or relative,
    # with or without the ".rb" suffix.
    def find_custom_config_file(default_dir, custom_file)
      [
        File.expand_path(custom_file),
        File.expand_path(custom_file + ".rb"),
        File.join(home, default_dir, custom_file),
        File.join(home, default_dir, custom_file + ".rb")
      ].find { |path| File.exist? path } || fatal("Unable to find requested config file #{custom_file}")
    end

    def collection_map_directory
      @collection_map_directory ||= File.join(home, "lib", "translation_maps", "ht")
    end
  end
end
