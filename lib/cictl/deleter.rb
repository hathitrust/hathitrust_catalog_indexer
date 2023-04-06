# frozen_string_literal: true

require "date_named_file"

require_relative "common"

module CICTL
  class Deleter
    include Common

    def run(deletes_file)
      File.open(deletes_file) do |file|
        if /\.gz\Z/.match? deletes_file.to_s
          file = Zlib::GzipReader.new(file)
        end
        ids = file.map { |line| line.chomp }
        if ids.size > 0
          solr_client.set_deleted ids
        else
          logger.info "#{deletes_file} is empty"
        end
        logger.info "Deleted #{ids.size} ids from #{solr_client}"
      end
    end
  end
end
