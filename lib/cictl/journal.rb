# frozen_string_literal: true

require_relative "../services"

module CICTL
  # A class that enables date-independent catalog indexing using the filesystem.
  #
  # Each time a full or update file is indexed, writes an (empty) file of the form
  # hathitrust_catalog_indexer_journal_upd_YYYYMMDD.txt or
  # hathitrust_catalog_indexer_journal_full_YYYYMMDD.txt in the journal directory.
  #
  # When we use the index command `cictl continue`
  # we calculate the earliest zephir file not yet indexed and proceed in order from
  # that point.
  #
  # Nomenclature note: "journal" is the closest semantic match to "log" I could find.
  # This is a log, of sorts, but the term was already taken.
  class Journal
    attr_reader :date

    FILENAME_PATTERN = /hathitrust_catalog_indexer_journal_(full|upd)_(\d{8})\.txt/

    def self.filename_for(date:, full:)
      yyyymmdd = date.strftime "%Y%m%d"
      type = full ? "full" : "upd"
      "hathitrust_catalog_indexer_journal_#{type}_#{yyyymmdd}.txt"
    end

    def initialize(date: Date.today - 1, full: false)
      @date = date
      @full = full
    end

    # Use the built-in but append the date and full/upd because that's what we care about.
    def to_s
      super.tap do |s|
        s.gsub!(/>$/, " [#{date} #{full? ? "full" : "upd"}]>")
      end
    end

    def full?
      @full
    end

    # Of the form `hathitrust_catalog_indexer_journal_(full|upd)_YYYYMMDD.txt`
    def file
      self.class.filename_for(date: date, full: full?)
    end

    def path
      File.join(HathiTrust::Services[:journal_directory], file)
    end

    def exist?
      File.exist? path
    end

    def missing?
      !exist?
    end

    def write!
      FileUtils.touch path
    end
  end
end
