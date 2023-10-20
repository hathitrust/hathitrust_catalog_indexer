# frozen_string_literal: true

require_relative "base_command"
require_relative "zephir_file"
require_relative "deleted_records"

module CICTL
  class IndexCommand < BaseCommand
    class_option :reader, type: :string, desc: "Reader name/path"
    class_option :writer, type: :string, desc: "Writer name/path"

    desc "all", "Empty the catalog and index the most recent monthly followed by subsequent daily updates"
    option :wait, type: :boolean, desc: "Wait 5 seconds for Control-C", default: true
    def all
      if options[:wait]
        puts "5 second delay if you need it..."
        sleep 5
      end
      # Make sure there is a full MARC file to work on
      if last_full_marc_file.nil? || !last_full_marc_file.readable?
        fatal "Unable to find or read full marcfile '#{last_full_marc_file}'"
      end
      logger.info "Empty full Solr records"
      solr_client.empty_records!
      logger.info "Load most recent set of deleted records into solr"
      if DeletedRecords.most_recent_non_empty_file
        logger.info "Found #{DeletedRecords.most_recent_non_empty_file}"
        solr_client.send_jsonl(DeletedRecords.most_recent_non_empty_file)
      else
        logger.error "Can't find any non_empty deleted_record files in #{DeletedRecords.save_directory}"
      end
      logger.info "Commit"
      solr_client.commit!
      logger.info "Using full marcfile #{last_full_marc_file}"
      # Calling the Thor "file" command.
      call_file_command last_full_marc_file
      # "since" command for a month starts on the last day of last month
      # because there will generally be both an "upd" and a "full" file.
      call_since_command last_full_marc_file.to_datetime
      logger.info "Commit"
      solr_client.commit!
    end

    option :commit, type: :boolean, desc: "Commit changes to Solr", default: true
    desc "file FILE", "Index a single MARC file"
    def file(marcfile)
      Indexer.new(reader: options[:reader], writer: options[:writer]).run marcfile
      solr_client.commit! if options[:commit]
    end

    desc "date YYYYMMDD", "Process the delete and index files timestamped YYYYMMDD"
    def date(date)
      with_date(date) do |date|
        index_deletes_for_date date
        index_records_for_date date
      end
    end

    desc "since YYYYMMDD", "Run all deletes/marcfiles in order since the given date"
    def since(date)
      with_date(date) do |date|
        yesterday = Date.today - 1
        begin
          start_date = date - 1
        rescue Date::Error => e
          fatal e.message
        end
        logger.debug "index since(#{date}): #{start_date} to #{yesterday}"
        (start_date..yesterday).each do |index_date|
          logger.info("\n------- #{index_date} -----------\n")
          call_date_command index_date
        end
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
      call_date_command yesterday

      logger.info "Dump deleted_records to #{DeletedRecords.daily_file}"
      solr_client.dump_deletes_as_jsonl(DeletedRecords.daily_file)
    end

    no_commands do
      alias_method :call_date_command, :date
      alias_method :call_file_command, :file
      alias_method :call_since_command, :since
    end

    private

    def last_full_marc_file
      @last_full_marc_file ||= ZephirFile.full_files.last
    end

    def delete_file_for_date(date)
      ZephirFile.delete_files.at(date)
    end

    def marc_file_for_date(date)
      ZephirFile.update_files.at(date)
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
