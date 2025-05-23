require_relative "../services"
require "httpx/adapters/faraday"

module HathiTrust
  class PrintHoldingsAPI

    def self.connection 
      Thread.current[:holdings_api_conn] ||= Faraday.new( url: ENV["HOLDINGS_API_URL"] ) do |builder|
        builder.request :json
        # TODO: Perhaps if it fails we should retry instead of immediately raising an
        # error?
        builder.response :raise_error
        builder.adapter :httpx
      end.tap do |conn|
        Services.logger.info("Allocated new connection #{conn} for print holdings api")
      end
    end

    def self.get_print_holdings_hash(
      ht_json:,
      id:,
      format:,
      oclc:,
      oclc_search:
    )

      request_body = {
          id: id,
          format: format,
          oclc: oclc,
          oclc_search: oclc_search,
          ht_json: ht_json
        }

      conn = connection

      Services.logger.debug("Sending api request with #{conn}")
      response = conn.post('/v1/record_held_by', request_body)
      Services.logger.debug("Got response for api request with #{conn}")

      # map from an array like
      #
      # [
      #   { 
      #     item_id: id1,
      #     organizations: [org1, org2]
      #   },
      #   {
      #     item_id: id2,
      #     organizations: [org1]
      #   }
      #  ]
      #
      # to a hash like
      #
      # {
      #    id1 => [org1, org2],
      #    id2 => [org1]
      # }

      JSON.parse(response.body).map do |item|
        [item["item_id"], item["organizations"]]
      end.to_h
    rescue => e
      # Something went wrong; log the issue and return nothing
      # log: request_body, response.status, response.body, exception
      Services.logger.error("Error with holdings API: #{e.message}; request=#{request_body.to_json} status=#{response&.status} response_body=#{response&.body}")
      {}
    end
  end
end
