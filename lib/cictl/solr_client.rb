#!/usr/bin/env ruby

# frozen_string_literal: true

#require "date"
#require "date_named_file"
#require "dotenv"
require "httpx"
require "pry"
#require "socket"
#require "thor"
#require "traject"
#require "yaml"
#require "yell"
#require "zlib"


module CICTL
  class SolrClient
    def to_s
      "CICTL::SolrClient for #{solr_url}"
    end

    def commit!
      post! **{"commit" => {}}
    end

    def empty!
      post! **{"delete" => {"query" => "deleted:(NOT true)"}}
    end

    def post!(json)
      httpx_client.post update_url, json: json
    end

    private

    def solr_url
      ENV["SOLR_URL"]
    end

    def update_url
      solr_url + "/update"
    end

    def httpx_client
      @httpx_client ||= HTTPX.with(headers: {"Content-Type" => "application/json"})
    end
  end
end
    
