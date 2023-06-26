# frozen_string_literal: true

require_relative "base_command"

module CICTL
  class DeleteCommand < BaseCommand
    desc "all", "Delete all records from the Solr index"
    def all
      logger.info "Empty Solr"
      solr_client.empty!
      logger.info "Commit"
      solr_client.commit!
    end

    desc "file FILE", "Delete records from a single file"
    def file(delfile)
      fatal "Could not read deletes file '#{delfile}'" unless File.readable?(delfile)
      logger.info "Deleting from #{delfile}, targeting #{solr_client}"
      Deleter.new.run delfile
      logger.info "Commit"
      solr_client.commit!
    end
  end
end
