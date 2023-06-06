require "thor"

require_relative "common"
require_relative "solr_client"

module CICTL
  class SolrCommand < Thor
    include Common

    desc "commit", "Send a commit command to solr"

    def commit
      solr_client.commit!
    end

    desc "dump-deleted FILE", "Dump the solr docs marked as `deleted` to the given .jsonl file"
    def dump_deleted(filename)
      solr_client.dump_deletes_as_jsonl(filename)
    end

    desc "send-jsonl FILE", "Send pre-created records from a .jsonl(.gz.) file into solr"
    option :batch_size, type: :numeric, desc: "Batch size when sending records", default: 1000

    def send_jsonl(filename)
      raise CICTLError, "'#{filename}' not readable" unless File.readable?(filename)
      solr_client.send_jsonl(filename, batch_size: options[:batch_size]).commit!
    end

    desc "ping", "Check to see if the solr core is responding"
    option :silent, type: :boolean, desc: "Skip output and correctly set exit code"
    option :timeout, type: :numeric, desc: "Timeout (seconds) to wait for reply", default: 1

    def ping
      client = CICTL::SolrClient.new(timeout: 1)
      if solr_client.alive?
        if options[:silent]
          exit 0
        else
          puts "SUCCESS: #{client.solr_url} is alive"
        end
      elsif options[:silent]
        exit 1
      else
        puts "FAILURE: #{client.solr_url} could not be reached"
      end
    end
  end
end
