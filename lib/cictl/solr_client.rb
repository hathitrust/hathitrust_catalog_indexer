#!/usr/bin/env ruby

# frozen_string_literal: true

require "httpx"
require "pry"

module CICTL
  class SolrClient
    def initialize(httpx = nil)
      @httpx_client = httpx
    end

    def to_s
      "CICTL::SolrClient for #{solr_url}"
    end

    def commit!
      post!("commit" => {})
    end

    def empty!
      post!("delete" => {"query" => "deleted:(NOT true)"})
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
