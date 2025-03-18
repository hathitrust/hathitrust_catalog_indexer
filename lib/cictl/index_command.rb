# frozen_string_literal: true

require_relative "base_command"
require_relative "deleted_records"
require_relative "journal"
require_relative "stop_release"
require_relative "zephir_file"

module CICTL
  class IndexCommand < BaseCommand
    class_option :reader, type: :string, desc: "Reader name/path"
    class_option :writer, type: :string, desc: "Writer name/path"

    desc "continue", "Index all files not represented in the indexer journals"
    def continue
      last_full = ZephirFile.full_files.last
      fatal "unable to find full Zephir file" unless last_full
      # Index the most recent full file and subsequent ones if the
      # full file journal is missing.
      full_journal = Journal.new(date: last_full.to_datetime.to_date, full: true)
      if full_journal.missing?
        logger.info "missing full journal #{full_journal}, calling `cictl all`"
        call_all_command
      # Otherwise, iterate from the last full file date to yesterday.
      # If there is a missing journal, start indexing from that point.
      else
        (last_full.to_datetime.to_date..(Date.today - 1)).each do |date|
          journal = Journal.new(date: date, full: false)
          if journal.missing?
            logger.info "missing update journal #{journal}, calling `cictl since #{journal.date}`"
            call_since_command(journal.date)
            break
          end
        end
      end
      postflight
    end

    desc "all", "Empty the catalog and index the most recent monthly followed by subsequent daily updates"
    option :wait, type: :boolean, desc: "Wait 5 seconds for Control-C", default: true
    def all
      if options[:wait]
        puts "5 second delay if you need it..."
        sleep 5
      end

      # Make sure there is a full MARC file to work on
      preflight(last_full_marc_file)

      logger.info "Empty full Solr records"
      solr_client.empty_records!

      load_deleted_records

      index_full_file(last_full_marc_file)

      # "since" command for a month starts on the last day of last month
      # because there will generally be both an "upd" and a "full" file.
      call_since_command last_full_marc_file.to_datetime
      postflight
    end

    # Note: this command does not write a journal since it only processes the MARC file
    # but not the deletes.
    option :commit, type: :boolean, desc: "Commit changes to Solr", default: true
    desc "file FILE", "Index a single MARC file"
    def file(marcfile)
      preflight(marcfile)
      Indexer.new(reader: options[:reader], writer: options[:writer]).run marcfile
      solr_client.commit! if options[:commit]
      postflight
    end

    desc "date YYYYMMDD", "Process the delete and index files with the date YYYYMMDD in its name"
    def date(date)
      preflight
      with_date(date) do |date|
        index_deletes_for_date date
        if index_records_for_date date
          journal = Journal.new(date: date)
          logger.info("write journal file #{journal.path}")
          journal.write!
        end
      end
      postflight
    end

    desc "since YYYYMMDD", "Processes all deletes/marcfiles with a date on or after YYYYMMDD in its name in order"
    def since(date)
      with_date(date) do |start_date|
        yesterday = Date.today - 1
        logger.debug "index since(#{start_date}): #{start_date} to #{yesterday}"
        (start_date..yesterday).each do |index_date|
          logger.info("\n------- #{index_date} -----------\n")
          call_date_command index_date
        end
      end
      postflight
    end

    desc "today", "Process the catchup (delete and index) for last night's files"
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
      postflight
    end

    no_commands do
      alias_method :call_all_command, :all
      alias_method :call_date_command, :date
      alias_method :call_file_command, :file
      alias_method :call_since_command, :since
    end

    private

    def stop_release
      @stop_release ||= StopRelease.new
    end

    def preflight(*files)
      logger.info "write stop release at #{stop_release.path}"
      stop_release.write
      files.each do |file|
        fatal "Missing expected filename for this operation" unless file
        fatal "Can't find #{file}" unless File.exist?(file)
        fatal "Can't read #{file}" unless File.readable?(file)
      end
      load_redirects
    end

    # Wrap up metrics on a potentially multi-file and multi-indexer command.
    def postflight
      HathiTrust::Services[:push_metrics].log_final_line
      logger.info "remove stop release at #{stop_release.path}"
      stop_release.remove
    end

    def load_redirects
      HathiTrust::Services[:redirects].load
    rescue SystemCallError, RuntimeError => e
      fatal e.message
    end

    def last_full_marc_file
      @last_full_marc_file ||= ZephirFile.full_files.last
    end

    def delete_file_for_date(date)
      ZephirFile.delete_files.at(date)
    end

    def marc_file_for_date(date)
      ZephirFile.update_files.at(date)
    end

    # @return [Boolean] true if the marcfile for the given date exists
    def index_records_for_date(date)
      marcfile = marc_file_for_date date
      if File.exist? marcfile
        Indexer.new(reader: options[:reader], writer: options[:writer]).run marcfile
        solr_client.commit!
        logger.debug "index date(#{date}): Solr count now #{solr_client.count}"
        true
      else
        logger.warn "could not find marcfile '#{marcfile}'"
        false
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

    def load_deleted_records
      logger.info "Load most recent set of deleted records into solr"
      if DeletedRecords.most_recent_non_empty_file
        logger.info "Found #{DeletedRecords.most_recent_non_empty_file}"
        solr_client.send_jsonl(DeletedRecords.most_recent_non_empty_file)
      else
        logger.error "Can't find any non_empty deleted_record files in #{DeletedRecords.save_directory}"
      end
    end

    # Loads a full file and (assuming no exceptions were thrown)
    # records that to the journal
    def index_full_file(file)
      logger.info "Using full marcfile #{file}"
      # Calling the Thor "file" command.
      call_file_command file

      logger.info "Commit"
      solr_client.commit!

      journal = Journal.new(date: file.to_datetime.to_date, full: true)
      logger.info("write journal file #{journal.path}")
      journal.write!
    end
  end
end
