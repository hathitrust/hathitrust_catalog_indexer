# frozen_string_literal: true

require "date_named_file"
require "socket"

require_relative "common"

module CICTL
  class Deleter
    include Common

    def run!(deletes_file)
      File.open(deletes_file) do |file|
        if /\.gz\Z/.match? deletes_file.to_s
          file = Zlib::GzipReader.new(file)
        end
        ids = file.map { |line| line.chomp }
        if ids.size > 0
          solr_client.delete! ids
        else
          logger.error "File #{deletes_file} is empty"
        end
        logger.info "Deleted #{ids.size} ids from #{solr_client}\n\n"
      end
    end
  end
end
