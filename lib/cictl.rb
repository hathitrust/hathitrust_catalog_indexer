#!/usr/bin/env ruby

# frozen_string_literal: true

require "date"
require "date_named_file"
require "dotenv"
require "httpx"
require "pry"
require "socket"
require "thor"
require "traject"
require "yaml"
require "yell"
require "zlib"

unless ENV["NO_DB"]
  require_relative "ht_traject/ht_dbh"
end

module CICTL
  class CICTL < Thor
    class_option :verbose, type: :boolean
    attr_accessor :logfile_path

    def self.exit_on_failure?
      true
    end

    def initialize(args = [], local_options = {}, config = {})
      Dotenv.load
      super args, local_options, config
    end

    desc "index_file FILE (LOGFILE)", "index a single file"
    def index_file(marcfile, logfile = nil)
      self.logfile_path = File.expand_path(logfile) if logfile
      run_traject marcfile
    end

    desc "index_date YYYYMMDD (LOGFILE)", "run the catchup (delete and index) for a particular date"
    option :reader, type: :string, banner: "<reader>"
    option :writer, type: :string, banner: "<writer>"
    def index_date(date_string, logfile = nil)
      self.logfile_path = File.expand_path(logfile) if logfile
      delfile = del_file_for_date(date_string)
      if File.exist? delfile
        logger.info "Deleting from #{delfile}, targeting #{ENV["SOLR_URL"]}"
        process_deletes delfile
      else
        logger.warn "No deletes: could not find delfile '#{delfile}'"
      end
      marcfile = marc_file_for_date(date_string)
      if File.exist? marcfile
        run_traject marcfile
        commit
      else
        fatal "No indexing: Could not find marcfile '#{marcfile}'"
      end
    end

    desc "catchup_today (LOGFILE)", "run the catchup (delete and index) for last night's files"
    option :reader, type: :string, banner: "<reader>"
    option :writer, type: :string, banner: "<writer>"
    def catchup_today(logfile = nil)
      # HT's "today" file is dated yesterday
      yesterday = (Date.today - 1).strftime("%Y%m%d")
      # We'll use the actual date in the logfile, though
      today = Date.today.strftime("%Y%m%d")
      logger.debug "catchup_today: using #{yesterday} as file date"
      logfile ||= File.join(hathitrust_catalog_indexer_path, "logs/daily_#{today}.txt")
      index_date yesterday, logfile
    end

    private

    # Read the data directory from ENV falling back to the default.
    def data_directory
      ENV["DDIR"] || "/htsolr/catalog/prep"
    end

    def marc_file_for_date(date_string)
      DateNamedFile.new("zephir_upd_%Y%m%d.json.gz")
        .in_dir(data_directory)
        .at(date_string)
    end

    def del_file_for_date(date_string)
      DateNamedFile.new("zephir_upd_%Y%m%d_delete.txt.gz")
        .in_dir(data_directory)
        .at(date_string)
    end

    def run_traject(marcfile)
      # Note: hostname will likely be gibberish under Docker
      logger.info "Working on #{Socket.gethostname} in #{tdir}"
      unless File.exist? marcfile
        fatal "No indexing: Could not find marcfile '#{marcfile}'"
      end
      if File.exist? reader_path
        logger.debug "reader at #{reader_path}"
      else
        fatal "Can't find reader #{reader_path}"
      end
      if File.exist? writer_path
        logger.debug "writer at #{writer_path}"
      else
        fatal "Can't find writer #{writer_path}"
      end
      update_collection_map
      call_indexer marcfile
    end

    def call_indexer(marcfile)
      logger.info "Indexing from #{marcfile}, reader #{reader_path} writer #{writer_path} (#{ENV["SOLR_URL"]})"
      success = indexer.process File.open(marcfile, "r")
      unless success
        fatal "traject returned #{code.exitstatus}, shutting down"
      end
    end

    def indexer
      @indexer ||= begin
        config_paths = [
          reader_path,
          writer_path,
          "#{tdir}/indexers/common.rb",
          "#{tdir}/indexers/common_ht.rb",
          "#{tdir}/indexers/ht.rb",
          "#{tdir}/indexers/subjects.rb"
        ]
        Traject::Indexer::MarcIndexer.new(logger: logger) do |ind|
          config_paths.each { |config_path| load_config_file(config_path) }
        end
      end
    end

    def update_collection_map
      if ENV["NO_DB"]
        logger.info "NO_DB set: not updating collection map"
        return
      end
      logger.info "updating collection map"
      db = HathiTrust::DBH::DB
      sql = <<~SQL
        select collection, coalesce(mapto_name,name) name
        from ht_institutions i join ht_collections c
        on c.original_from_inst_id = i.inst_id
      SQL
      ccof = {}
      db[sql].order(:collection).each do |h|
        ccof[h[:collection].downcase] = h[:name]
      end
      tmap_dir = File.join(hathitrust_catalog_indexer_path, "lib", "translation_maps", "ht")
      File.open(File.join(tmap_dir, "collection_code_to_original_from.yaml"), "w:utf-8") do |f|
        f.puts ccof.to_yaml
      end
    end

    def logger
      @logger ||= Yell.new do |l|
        l.level = options[:verbose] ? "gte.debug" : "gte.info"
        if logfile_path
          l.adapter :file, logfile_path
        else
          l.adapter :stdout, level: [:debug, :info, :warn]
        end
        # Always log errors to STDOUT even if there is a log file.
        l.adapter :stderr, level: [:error, :fatal]
      end
    end

    # Logs error message and exits with nonzero status
    def fatal(message)
      logger.fatal message
      exit 1
    end

    def solr_url
      ENV["SOLR_URL"]
    end

    def deletes_url
      solr_url + "/update"
    end

    # The top-level repo path.
    # In Docker likely to be "/app/"
    # Appears as $TDIR in the shell scripts
    def hathitrust_catalog_indexer_path
      File.expand_path(File.join(File.dirname(__FILE__), ".."))
    end

    alias_method :tdir, :hathitrust_catalog_indexer_path

    # If --reader has been passed, try that as relative and absolute path.
    def reader_path
      return default_reader_path unless options["reader"]
      @reader_path ||=
        if File.exist? File.expand_path(options["reader"])
          File.expand_path(options["reader"])
        else
          File.join(tdir, "readers", options["reader"])
        end
    end

    # If --writer has been passed, try that as relative and absolute path.
    def writer_path
      return default_writer_path unless options["writer"]
      @writer_path ||=
        if File.exist? File.expand_path(options["writer"])
          File.expand_path(options["writer"])
        else
          File.join(tdir, "writers", options["writer"])
        end
    end

    # FIXME: call this "jsonld"
    # FIXME: nope, it kinda looks like it should be ndjson
    def default_reader_path
      @default_reader_path ||= File.join(tdir, "readers", "ndj.rb")
    end

    def default_writer_path
      @default_writer_path ||= File.join(tdir, "writers", "localhost.rb")
    end

    def commit
      logger.info "Committing"
      `curl  -H "Content-Type: application/json" -X POST -d'{"commit": {}}' "#{solr_url}/update?wt=json"`
    end

    def process_deletes(deletes_file)
      file = File.open deletes_file
      if /\.gz\Z/.match? deletes_file
        file = Zlib::GzipReader.new(file)
      end
      docs = file.map do |line|
        {id: line.chomp, deleted: true}
      end
      if docs.size > 0
        client = HTTPX.with(headers: {"Content-Type" => "application/json"})
        client.post(deletes_url, json: docs)
      else
        logger.error "File #{deletes_file} is empty"
      end
      logger.info "Deleted #{docs.size} ids from #{deletes_url}\n\n"
    end
  end
end
