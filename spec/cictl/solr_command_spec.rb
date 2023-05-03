# frozen_string_literal: true

require "spec_helper"
require "tempfile"

RSpec.describe CICTL::SolrCommand, :livesolr do
  describe "ping" do
    it "pings the live solr" do
      expect { CICTL::Command.start(["solr", "ping"]) }.to output(/SUCCESS/).to_stdout
    end

    it "fails to ping a fake solr url" do
      old_solr_url = HathiTrust::Services[:solr_url]
      HathiTrust::Services.register(:solr_url) { "http://solr-sdr-catalog:1111/solr/catalog" }
      expect { CICTL::Command.start(["solr", "ping"]) }.to output(/FAILURE/).to_stdout
      HathiTrust::Services.register(:solr_url) { old_solr_url }
    end
  end

  describe "deleted records" do
    let(:client) { CICTL::SolrClient.new }

    # Generate a list of random ints to use as IDs
    def random_ids(n = 3)
      n.times.each_with_object([]) { |i, arr| arr << Random.rand(10_000_000).to_s}
    end

    # Construct a couple solr documents representing deletes, so we can test the
    # re-upload functionality
    let(:del_docs) {
      random_ids(2).map{|id| {id: id.to_s, deleted: true, time_of_index: "2022-08-03T12:54:40.298Z"} }
    }

    # Make sure there are at least a couple deletes in there for this suite,
    # and remove them after we're done
    before(:all) do
      @del_ids = random_ids(4)
      c = CICTL::SolrClient.new
      c.set_deleted(@del_ids)
      c.commit!
    end

    after(:all) do
      c = CICTL::SolrClient.new
      c.delete_by_query("id:(#{@del_ids.join(" OR ")})")
      c.commit!
    end

    # Run the block with newly-created deleted records for each id in ids,
    # deleting them again once the block is done.
    # @param [Array<String>] ids A set of ids that look like numbers
    def with_temp_deleted_records(n = 3)
      ids = random_ids(n)
      client.set_deleted(ids)
      client.commit!
      yield
      client.delete_by_query("id:(#{ids.join(" OR ")})")
      client.commit!
    end

    it "adds deleted records" do
      initial_deleted_count = client.count_deleted
      tmpfile = Tempfile.create
      del_docs.each { |doc| tmpfile.puts doc.to_json }
      tmpfile.flush
      tmpfile.close
      CICTL::Command.start(["solr", "send_jsonl", tmpfile.path])

      File.delete(tmpfile.path)

      expect(client.count_deleted).to eq(initial_deleted_count + del_docs.count)

      ids = del_docs.map { |d| d[:id] }
      client.delete_by_query("id:(#{ids.join(" OR ")})")
      client.commit!
      expect(client.count_deleted).to eq(initial_deleted_count)
    end

    it "dumps deleted records" do
      with_temp_deleted_records do
        deleted_count = client.count_deleted
        tmpfile = Tempfile.create
        client.dump_deletes_as_jsonl(tmpfile.path)
        tmpfile.close

        expect(File.open(tmpfile.path).count).to eq(deleted_count)
        File.delete(tmpfile.path)
      end
    end
  end
end
