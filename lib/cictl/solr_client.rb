require "rsolr"
require "delegate"
require "pathname"
require "zinzout"
require "faraday"
require "httpx/adapters/faraday"
require_relative "../services"

module CICTL
  class SolrClient < SimpleDelegator

    # @param [RSolr] rsolr An existing rsolr instance
    # @param [Fixnum] timeout Timeout, in seconds
    def initialize(rsolr = nil, timeout: 15)
      rsolr ||= RSolr.connect url: solr_url, timeout: timeout, open_timeout: 2
      super rsolr
    end

    def to_s
      "CICTL::SolrClient for #{solr_url}, #{count} documents"
    end

    # Count all records including those with the "deleted" flag set.
    def count(q = "*:*")
      solr_params = {q: q, wt: "ruby", rows: 1}
      get("select", params: solr_params)["response"]["numFound"]
    end

    # Count only records with the "deleted" flag.
    def count_deleted
      count "deleted:true"
    end

    def alive?
      head("admin/ping").response[:status] == 200
    rescue RSolr::Error::ConnectionRefused
      false
    end

    def commit!
      commit
      self
    end

    # FIXME: not happy about the naming convention.
    # This removes full records but leaves intact the tombstoned "deletes"
    def empty_records!
      delete_by_query "deleted:(NOT true)"
      self
    end

    # FIXME: ditto above re not happy about the naming convention.
    def empty!
      delete_by_query "*:*"
      self
    end

    def set_deleted(ids)
      solr_data = Array(ids).map { |id| deleted_id id }
      update data: solr_data.to_json, headers: {"Content-Type" => "application/json"}
    end

    # An http client for sending jsonl (nee "ndj") documents to solr in batches
    def batch_sender_client
      @batch_sender ||= begin
        Faraday.new(request: {params_encoder: Faraday::FlatParamsEncoder}) do |builder|
          builder.use Faraday::Response::RaiseError
          builder.request :url_encoded
          builder.response :json
          builder.adapter :httpx
          builder.headers['Content-Type'] = 'application/json'
        end
      end
    end

    # Send the solr documents in an jsonl/ndj file in batches
    # @param [String] filename The (possibly .gz) file with one solr doc on each line
    # @option [Fixnum] batch_size How many document to send at a time
    # @return [SolrClient] self
    def send_jsonl(filename, batch_size: 1000)
      Zinzout.zin(filename) do |infile|
        infile.each_slice(batch_size) do |batch|
          body = "[" << batch.join(",") << "]"
          batch_sender_client.post(update_url, body)
        end
      end
      commit!
      self
    end

    # Query solr for all the deleted record documents, and dump them as .jsonl to the
    # given file/filename
    # @param [String,File] filename The file(name) you want to dump to
    # @option [Fixnum] batchsize How many to fetch at once
    # @return [SolrClient] self
    def dump_deletes_as_jsonl(filename, batch_size: 1000)
      Zinzout.zout(filename) do |out|
        page = 0
        loop do
          resp = paginate page, batch_size, "select", params: {q: "deleted:true"}
          docs = resp["response"]["docs"]
          docs.each do |doc|
            doc.delete "id_int"
            out.puts doc.to_json
          end
          break if docs.size < batch_size
          page += 1
        end
      end
      self
    end

    def solr_url
      HathiTrust::Services[:solr_url]
    end

    def update_url
      solr_url.chomp("/") + "/update"
    end

    def ping_url
      solr_url.chomp("/") + "/admin/ping"
    end

    private

    def deleted_id(id)
      {id: id, deleted: true}
    end

  end
end
