# frozen_string_literal: true

require "thor"

require_relative "common"
require_relative "date_extra"
require_relative "zephir_file"

module CICTL
  class IndexCommand < Thor
    include Common

    class_option :reader, type: :string, desc: "Reader name/path"
    class_option :writer, type: :string, desc: "Writer name/path"

    desc "all", "Empty the catalog and index the most recent monthly followed by subsequent daily updates"
    option :today, type: :string, desc: "Specify date other than today as YYYYMMDD"
    option :wait, type: :boolean, desc: "Wait 5 seconds for Control-C", default: true
    def all
      if options[:wait]
        puts "5 second delay if you need it..."
        sleep 5
      end
      logger.info "Empty full Solr records"
      solr_client.empty_records!
      logger.info "Commit"
      solr_client.commit!
      reference_date = Date.with(options[:today] || Date.today)
      logger.info "Looking for full marcfile #{last_full_marc_file(reference_date)}"
      file last_full_marc_file(reference_date)
      # "since" command for a month starts on the second day of the month
      # because it is looking for a file dated the previous day.
      since Date.last_day_of_last_month(reference_date) + 2
      logger.info "Commit"
      solr_client.commit!
    end

    desc "file FILE", "Index a single file"
    def file(marcfile)
      Indexer.new(reader: options[:reader], writer: options[:writer]).run marcfile
      solr_client.commit!
    end

    desc "date YYYYMMDD", "Process the delete and index files timestamped YYYYMMDD"
    def date(date)
      date = Date.with date
      index_deletes_for_date date
      index_records_for_date date
    end

    desc "since YYYYMMDD", "Run all deletes/includes in order since the given date"
    def since(date)
      date = Date.with date
      yesterday = Date.today - 1
      begin
        start_date = date - 1
      rescue Date::Error => e
        fatal e.message
      end
      logger.debug "index since(#{date}): #{start_date} to #{yesterday}"
      (start_date..yesterday).each do |index_date|
        logger.info("\n------- #{index_date} -----------\n")
        date index_date
      end
    end

    desc "today", "Run the catchup (delete and index) for last night's files"
    def today
      # HT's "today" file is dated yesterday
      yesterday = (Date.today - 1).strftime("%Y%m%d")
      # We'll use the actual date in the logfile, though
      # today = Date.today.strftime("%Y%m%d")
      logger.debug "index today: using #{yesterday} as file date"
      # FIXME: why does this have a default logfile where catchup_since does not?
      # _logfile ||= File.join(home, "logs/daily_#{today}.txt")
      date yesterday
    end

    private

    def last_full_marc_file(reference_date = today)
      DateNamedFile.new(ZephirFile.full_template)
        .in_dir(data_directory)
        .at(Date.last_day_of_last_month(reference_date))
    end

    def delete_file_for_date(date)
      DateNamedFile.new(ZephirFile.delete_template)
        .in_dir(data_directory)
        .at(date)
    end

    def marc_file_for_date(date)
      DateNamedFile.new(ZephirFile.update_template)
        .in_dir(data_directory)
        .at(date)
    end

    def index_records_for_date(date)
      marcfile = marc_file_for_date date
      if File.exist? marcfile
        Indexer.new(reader: options[:reader], writer: options[:writer]).run marcfile
        solr_client.commit!
        logger.debug "index date(#{date}): Solr count now #{solr_client.count}"
      else
        logger.warn "could not find marcfile '#{marcfile}'"
      end
    end

    def index_deletes_for_date(date)
      delfile = delete_file_for_date date
      if File.exist? delfile
        logger.info "Deleting from #{delfile}, targeting #{solr_client}"
        Deleter.new.run delfile
        solr_client.commit!
      else
        logger.warn "could not find delfile '#{delfile}'"
      end
    end
  end
end
