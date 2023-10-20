# frozen_string_literal: true

require "spec_helper"
require "cictl/deleted_records"

RSpec.describe CICTL::IndexCommand do
  before(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV["CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"] = "sample"
  end

  after(:each) do
    CICTL::SolrClient.new.empty!.commit!
    ENV.delete "CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"
    remove_test_log
  end

  describe "#index all" do
    it "indexes all example records" do
      # Make a fake delete entry for a bogus id
      bogus_delete = "000000000"
      CICTL::SolrClient.new.set_deleted [bogus_delete]
      CICTL::Commands.start(["index", "all", "--no-wait", "--quiet", "--log", test_log])
      expect(solr_count).to eq CICTL::Examples.all_ids.count + 1
      expect(solr_deleted_count).to be > 0
      expect(solr_ids("deleted:true")).to include(bogus_delete)
    end

    context "using nonexistent redirect file" do
      override_service(:redirect_file) { "no_such_redirects_file.gz.txt" }
      override_service(:no_redirects?) { false }

      it "bails out" do
        expect {
          CICTL::Commands.start(["index", "all", "--no-wait", "--quiet", "--log", test_log])
        }.to raise_error(Errno::ENOENT)
      end
    end
  end

  describe "#index date" do
    it "indexes full records and deleted record from example date" do
      examples = CICTL::Examples.for_date("20230103")
      CICTL::Commands.start(["index", "date", "20230103", "--log", test_log])
      expect(solr_count).to eq examples.map { |ex| ex[:ids] }.flatten.uniq.count
    end

    it "raises on bogus date" do
      expect { CICTL::Commands.start(["index", "date", "this is not even remotely datelike", "--log", test_log]) }
        .to raise_error(CICTL::CICTLError)
    end
  end

  describe "#index file" do
    context "with no additional parameters" do
      it "indexes full records and no deletes from example file" do
        example = CICTL::Examples.for_date("20230103", type: :upd).first
        file = File.join(HathiTrust::Services[:data_directory], example[:file])
        CICTL::Commands.start(["index", "file", file, "--log", test_log])
        expect(solr_count).to eq example[:ids].count
      end
    end

    context "that does not exist" do
      it "fails" do
        file = File.join(HathiTrust::Services[:data_directory], "there_is_no_file_by_that_name_here.json.gz")
        expect {
          CICTL::Commands.start(["index", "file", file, "--log", test_log])
        }.to raise_error(CICTL::CICTLError)
      end
    end

    context "with an explicit reader" do
      context "that exists" do
        it "indexes full records and no deletes from example file" do
          example = CICTL::Examples.for_date("20230103", type: :upd).first
          file = File.join(HathiTrust::Services[:data_directory], example[:file])
          CICTL::Commands.start(["index", "file", file, "--reader", "readers/jsonl", "--log", test_log])
          expect(solr_count).to eq example[:ids].count
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(HathiTrust::Services[:data_directory], "sample_upd_20230223.json.gz")
          expect {
            CICTL::Commands.start(["index", "file", file, "--reader", "no_such_reader", "--log", test_log])
          }.to raise_error(CICTL::CICTLError)
        end
      end
    end

    context "with an explicit writer" do
      context "that exists" do
        it "indexes full records and no deletes from example file" do
          example = CICTL::Examples.for_date("20230103", type: :upd).first
          file = File.join(HathiTrust::Services[:data_directory], example[:file])
          CICTL::Commands.start(["index", "file", file, "--writer", "writers/localhost", "--log", test_log])
          expect(solr_count).to eq example[:ids].count
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(HathiTrust::Services[:data_directory], "sample_upd_20230103.json.gz")
          expect {
            CICTL::Commands.start(["index", "file", file, "--writer", "no_such_writer", "--log", test_log])
          }.to raise_error(CICTL::CICTLError)
        end
      end
    end
  end

  describe "#index today" do
    # Create new update and delete files in a temp directory based on fixtures.
    after(:each) { HathiTrust::Services.register(:data_directory) { @save_dd } }

    # Note that "today" means "index today, using the file dated yesterday"
    it "indexes 'today' and produces deletes file" do
      update_source = CICTL::ZephirFile.update_files.last
      del_source = CICTL::ZephirFile.delete_files.last

      @save_dd = HathiTrust::Services[:data_directory]
      HathiTrust::Services.register(:data_directory) { Dir.mktmpdir }

      zyesterday = CICTL::ZephirFile.update_files.yesterday
      delyesterday = CICTL::ZephirFile.delete_files.yesterday

      # Get some data into those files
      FileUtils.cp(update_source, zyesterday)
      FileUtils.cp(del_source, delyesterday)

      # How many records/deletes do we have?
      zcount = Zinzout.zin(zyesterday).count
      delcount = Zinzout.zin(delyesterday).count

      CICTL::Commands.start(%w[index today])

      expect(solr_count).to eq(zcount + delcount)
      expect(CICTL::DeletedRecords.daily_file.readable?)
      expect(Zinzout.zin(CICTL::DeletedRecords.daily_file).count).to eq(delcount)
    end
  end
end
