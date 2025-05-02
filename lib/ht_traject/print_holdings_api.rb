require_relative "../services"

module HathiTrust
  class PrintHoldingsAPI

    def self.connection 
      @conn ||= Faraday.new( url: ENV["HOLDINGS_API_URL"] ) do |builder|
        builder.request :json
        builder.response :json
        # TODO: Perhaps if it fails we should retry instead of immediately raising an
        # error?
        builder.response :raise_error
      end
    end

    def self.get_print_holdings_hash(
      ht_items:,
      id:,
      format:,
      oclc:,
      oclc_search:
    )



      response = connection.post('/v1/record_held_by',
        {
          id: id,
          format: format,
          oclc: oclc,
          oclc_search: oclc_search,
          ht_json: ht_items.to_json(:ht)
        })

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
      
      response.body.map do |item|
        [item["item_id"], item["organizations"]]
      end.to_h
    end
  end
end
