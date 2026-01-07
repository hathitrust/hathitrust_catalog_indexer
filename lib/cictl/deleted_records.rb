# frozen_string_literal: true

require "pathname"
require "date_named_file"
require_relative "common"
require "zinzout"

module CICTL
  # Support for backing up and restoring stub solr documents for deleted
  # catalog records. This is used to support reporting in OAI about catalog
  # records that have been deleted.
  module DeletedRecords
    extend Common
    extend self

    def save_directory
      dir = Pathname.new(data_directory) + "deleted_records"
      dir.mkpath(mode: 0o775)
      dir
    end

    # @return [DateNamedFile::Directory] a date named file template
    def daily_template
      DateNamedFile.new("deleted_records_upd_%Y%m%d.jsonl.gz").in_dir(save_directory)
    end

    def full_template
      DateNamedFile.new("deleted_records_full_%Y%m%d.jsonl.gz").in_dir(save_directory)
    end

    def daily_file(date = nil)
      date ? daily_template.at(date) : daily_template.today
    end

    def full_file(date = nil)
      date ? full_template.at(date) : full_template.today
    end

    def most_recent_non_empty_file
      daily_template.to_a.reverse.find { |f| deleted_record_file_not_empty?(f) }
    end

    private

    # Determining if we have an empty file is made more difficult by the fact that an
    # empty gzipped file isn't itself empty. Just look to see if the first line has
    # any non-spaces in it. This works for our purposes here, but of course not
    # in the general case.
    def deleted_record_file_not_empty?(f)
      z = Zinzout.zin(f)
      full = /\S/.match?(z.first)
      z.close
      full
    end
  end
end
