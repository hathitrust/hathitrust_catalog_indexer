# frozen_string_literal: true

require "date_named_file"
require "zinzout"

require_relative "common"

module CICTL
  class Deleter
    include Common

    def run(deletes_file)
      Zinzout.zin(deletes_file) do |file|
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
