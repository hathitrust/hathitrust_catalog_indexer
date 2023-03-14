#!/usr/bin/env ruby

# frozen_string_literal: true

# FIXME: use require_relative 'some_path/ht_db_config'
# if a DB connection is needed

require "date"
require "date_named_file"
require "httpx"
require "logger"
#require "open3"
require "pry"
require "socket"
require "thor"
require "yaml"
require 'zlib'

unless ENV["NO_DB"]
  require_relative "ht_traject/ht_dbh"
end

# Logs errors to STDERR as well as the log
class CopyLogger < Logger
  def error message
    STDERR.puts message
    super message
  end
end

module CICTL
  class CICTL < Thor
    class_option :verbose, :type => :boolean
    attr_accessor :logfile_path

    def self.exit_on_failure?
      true
    end

    desc "index_file FILE (LOGFILE)", "index a single file"
    def index_file(marcfile, logfile = nil)
      self.logfile_path = File.expand_path(logfile) if logfile
      run_traject marcfile
    end

    desc "index_date YYYYMMDD (LOGFILE)", "run the catchup (delete and index) for a particular date"
    option :reader, :type => :string, :banner => "<reader>"
    option :writer, :type => :string, :banner => "<writer>"
    def index_date(date_string, logfile = nil)
      self.logfile_path = File.expand_path(logfile) if logfile
      setup_environment
      delfile = del_file_for_date(date_string)
      if File.exist? delfile
        logger.info  "Deleting from #{delfile}, targeting #{ENV["SOLR_URL"]}"
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
    option :reader, :type => :string, :banner => "<reader>"
    option :writer, :type => :string, :banner => "<writer>"
    def catchup_today(logfile = nil)
      puts "OPTIONS: #{options}"
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
      logger.info "Working on #{Socket.gethostname} in #{hathitrust_catalog_indexer_path}"
      unless File.exist? marcfile
        fatal "No indexing: Could not find marcfile '#{marcfile}'"
      end
      #setup_environment
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
      call_traject_binary(marcfile)
    end

    def call_traject_binary(marcfile)
      logger.info "Indexing from #{marcfile}, reader #{reader_path} writer #{writer_path} (#{ENV["SOLR_URL"]})"

      cmd = ["bundle exec traject",
        "-c #{reader_path}",
        "-c #{writer_path}",
        "-c #{tdir}/indexers/common.rb",
        "-c #{tdir}/indexers/common_ht.rb",
        "-c #{tdir}/indexers/ht.rb",
        "-c #{tdir}/indexers/subjects.rb",
        "-s log.file=STDOUT",
        "#{marcfile}"
      ].join(" ")

      logger.debug "Indexing command '#{cmd}'"
      # Keep Open3 quiet when processing is interrupted with Ctrl-C.
      Thread.report_on_exception = false
      stdout_str, stderr_str, code = Open3.capture3(cmd)
      if stdout_str.length.positive?
        logger.info "traject output: #{stdout_str}"
      end
      if stderr_str.length.positive?
        logger.error "traject error: #{stderr_str}"
      end
      if !code.success?
        fatal "traject returned #{code.exitstatus}, shutting down"
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
      tmap_dir = File.join(hathitrust_catalog_indexer_path, 'lib', 'translation_maps', 'ht')
      File.open(File.join(tmap_dir, 'collection_code_to_original_from.yaml'), 'w:utf-8') do |f|
        f.puts ccof.to_yaml
      end
    end

    def logger
      @logger ||= begin
        target = logfile_path ? File.open(logfile_path, 'a+') : STDOUT
        level = options[:verbose] ? Logger::DEBUG : Logger::INFO
        Logger.new(target, level: level)
      end
    end

    # Logs error message and exits with nonzero status
    def fatal(message)
      logger.fatal message
      exit 1
    end

    # Do various JRuby / Java setup activities.
    # Only runs once to avoid spamming PATH.
    def setup_environment
      return if @setup_environment_finished
      logger.info "Setting up JRuby/Java environment"
      ENV["JRUBY_OPTS"] = "--server -J-Xmx2048m -Xcompile.invokedynamic=true"
      ENV["PATH"] = ENV["PATH"].split(":").unshift("/htsolr/catalog/bin/jruby/bin").join(":")
      ENV.delete "JAVA_HOME"
      ENV["SOLR_URL"] ||= "http://localhost:9033/solr/catalog"
      @setup_environment_finished = true
    end

    def solr_url
      setup_environment
      ENV["SOLR_URL"]
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
      @reader_path ||= begin
        [
          File.join(tdir, "readers", options["reader"]),
          File.join(tdir, "readers", options["reader"] + ".rb"),
          File.join(tdir, options["reader"]),
          File.join(tdir, options["reader"] + ".rb")
        ].find(default_reader_path) { |candidate| puts "CHECK #{candidate}" ; File.exist? candidate }
      end
    end
    
    # If --writer has been passed, try that as relative and absolute path.
    def writer_path
      return default_writer_path unless options["writer"]
      @writer_path ||= begin
        [
          File.join(tdir, "writers", options["writer"]),
          File.join(tdir, "writers", options["writer"] + ".rb"),
          File.join(tdir, options["writer"]),
          File.join(tdir, options["writer"] + ".rb")
        ].find(default_writer_path) { |candidate| File.exist? candidate }
      end
    end

    # FIXME: call this "jsonld"
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

    def deletes_url
      ENV['SOLR_URL'] + '/update'
    end

    def process_deletes(deletes_file)
      client = HTTPX.with(headers: {'Content-Type' => 'application/json'})
      total = 0
      begin
        file = File.open(deletes_file)
        if /\.gz\Z/.match(deletes_file)
          file = Zlib::GzipReader.new(file)
        end
        docs = file.map do |line|
          { id: line.chomp, deleted: true }
        end
        if docs.size > 0
          client.post(url, json: docs)
        else
          logger.error "File #{deletes_file} is empty"
        end
        logger.info "Deleted #{docs.size} ids from #{url}\n\n"
      rescue Exception => e
        puts "Problem deleting: #{e}"
      end
    end
  end
end

