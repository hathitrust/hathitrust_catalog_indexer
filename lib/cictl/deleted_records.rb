# frozen_string_literal: true

require "pathname"
require "date_named_file"
require_relative "common"

module CICTL
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
      daily_template.reverse.find { |f| f.size > 0 }
    end
  end
end
