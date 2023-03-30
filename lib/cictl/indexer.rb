# frozen_string_literal: true

require "socket"

require_relative "common"

module CICTL
  class Indexer
    include Common
    DEFAULT_READER_NAME = "jsonl"
    DEFAULT_WRITER_NAME = "localhost"
    COLLECTION_MAP_FILE = "collection_code_to_original_from.yaml"

    def initialize(reader: nil, writer: nil)
      @reader = reader
      @writer = writer
      config_paths = [reader_path, writer_path]
      %w[common common_ht ht subjects].each do |conf|
        config_paths << File.join(home, "indexers", conf + ".rb")
      end
      @indexer = Traject::Indexer::MarcIndexer.new(logger: logger) do |ind|
        config_paths.each { |config_path| load_config_file(config_path) }
      end
    end

    def run!(marcfile)
      # Note: hostname will likely be gibberish under Docker
      logger.info "Working on #{Socket.gethostname} in #{home}"
      unless File.exist? marcfile
        fatal "No indexing: Could not find marcfile '#{marcfile}'"
      end
      fatal "Can't find reader #{reader_path}" unless File.exist?(reader_path)
      fatal "Can't find writer #{writer_path}" unless File.exist?(writer_path)
      logger.debug "reader: #{reader_path}; writer: #{writer_path}"
      update_collection_map
      call_indexer marcfile
    end

    private

    def call_indexer(marcfile)
      logger.info "Indexing from #{marcfile}, reader #{reader_path} writer #{writer_path} (#{Services[:solr]})"
      success = @indexer.process File.open(marcfile, "r")
      unless success
        fatal "traject failed, shutting down"
      end
    end

    # Absolute path to traject reader file
    def reader_path
      return default_reader_path unless @reader
      @reader_path ||= find_custom_config_file("readers", @reader)
    end

    # Absolute path to traject writer file
    def writer_path
      return default_writer_path unless @writer
      @writer_path ||= find_custom_config_file("writers", @writer)
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

    # FIXME: does this belong here or cictl.rb?
    def update_collection_map
      logger.info "updating collection map"
      tmap_dir = File.join(home, "lib", "translation_maps", "ht")
      File.open(File.join(tmap_dir, COLLECTION_MAP_FILE), "w:utf-8") do |f|
        f.puts CollectionMap.new.to_yaml
      end
    end
  end
end
