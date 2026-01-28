# frozen_string_literal: true

require "spec_helper"
require "cictl/deleted_records"
require "cictl/journal"
require "cictl/stop_release"
require "timecop"

RSpec.describe CICTL::IndexCommand do
  # Do we have metrics for this job?
  # Metrics are cleared before each `with_test_environment`
  def metrics?
    job_name = HathiTrust::Services[:job_name]
    metrics = Faraday.get("#{ENV["PUSHGATEWAY"]}/metrics").body
    metrics.match?(/^job_last_success\S*job="#{job_name}"\S* \S+/m) &&
      metrics.match?(/^job_duration_seconds\S*job="#{job_name}"\S* \S+/m) &&
      metrics.match?(/^job_records_processed\S*job="#{job_name}"\S* \S+/m)
  end

  # records may be updated multiple times, so we need to dedupe those
  def unique_id_count(examples)
    examples
      .map { |ex| ex[:ids] }
      .flatten
      .uniq
      .count
  end

  # Is the STOPCATALOGRELEASE file in place?
  def stop_release?
    File.exist?(CICTL::StopRelease.new.path)
  end

  around(:each) do |example|
    job_name = HathiTrust::Services[:job_name]
    # Trailing slash on URL is needed because we are matching instance with blank name
    Faraday.delete("#{ENV["PUSHGATEWAY"]}/metrics/job/#{job_name}/instance/")
    with_test_environment do |tmpdir|
      example.run
    end
  end

  describe "#index continue" do
    before(:each) { Timecop.travel(Date.parse("2023-01-04")) }

    context "with no journal" do
      it "indexes all example records" do
        file_count = CICTL::Examples.of_type(:full, :upd).count
        CICTL::Commands.start(["index", "continue", "--quiet"])
        expect(solr_count).to eq CICTL::Examples.all_ids.count
        expect(Dir.children(HathiTrust::Services[:journal_directory]).count).to eq(file_count)
        expect(metrics?).to eq true
        expect(stop_release?).to eq false
      end
    end

    context "with only the full file" do
      it "indexes only the update files and writes a journal for each" do
        CICTL::Examples.of_type(:full).each do |ex|
          CICTL::Examples.journal_for(example: ex).write!
        end
        update_file_count = CICTL::Examples.of_type(:upd).count
        update_id_count = unique_id_count(CICTL::Examples.of_type(:upd, :delete))
        old_journal_count = Dir.children(HathiTrust::Services[:journal_directory]).count
        CICTL::Commands.start(["index", "continue", "--quiet"])
        expect(solr_count).to eq update_id_count
        expect(Dir.children(HathiTrust::Services[:journal_directory]).count).to eq(old_journal_count + update_file_count)
        expect(metrics?).to eq true
        expect(stop_release?).to eq false
      end
    end

    context "with a full journal" do
      it "indexes nothing and writes no journals" do
        CICTL::Examples.of_type(:full, :upd).each do |ex|
          CICTL::Examples.journal_for(example: ex).write!
        end
        old_journal_count = Dir.children(HathiTrust::Services[:journal_directory]).count
        CICTL::Commands.start(["index", "continue", "--quiet"])
        expect(solr_count).to eq 0
        expect(Dir.children(HathiTrust::Services[:journal_directory]).count).to eq(old_journal_count)
        expect(metrics?).to eq true
        expect(stop_release?).to eq false
      end
    end

    context "with one day to process" do
      it "indexes it and writes the journal" do
        latest_examples = CICTL::Examples.of_type(:upd, :delete).select { |e| e[:date] == "20230103" }

        CICTL::Examples.of_type(:full, :upd)
          .reject { |e| e[:date] == "20230103" }
          .each do |ex|
            CICTL::Examples.journal_for(example: ex).write!
        end

        CICTL::Commands.start(["index", "continue", "--quiet"])
        expect(solr_count).to eq unique_id_count(latest_examples)
        expect(File.exist?(File.join(HathiTrust::Services[:journal_directory], "hathitrust_catalog_indexer_journal_upd_20230103.txt"))).to be(true)
        expect(stop_release?).to eq false
      end
    end
  end

  describe "#index all" do
    before(:each) { Timecop.travel(Date.parse("2023-01-04")) }

    it "indexes all example records" do
      # Make a fake delete entry for a bogus id
      bogus_delete = "000000000"
      CICTL::SolrClient.new.set_deleted [bogus_delete]
      CICTL::Commands.start(["index", "all", "--no-wait", "--quiet"])
      expect(solr_count).to eq CICTL::Examples.all_ids.count + 1
      expect(solr_deleted_count).to be > 0
      expect(solr_ids("deleted:true")).to include(bogus_delete)
      expect(Dir.children(HathiTrust::Services[:journal_directory]).count).to be > 0
      expect(metrics?).to eq true
      expect(stop_release?).to eq false
    end

    context "using nonexistent redirect file" do
      override_service(:redirect_file) { "no_such_redirects_file.gz.txt" }
      override_service(:no_redirects?) { false }

      it "bails out" do
        expect {
          CICTL::Commands.start(["index", "all", "--no-wait", "--quiet"])
        }.to raise_error(CICTL::CICTLError)
        expect(metrics?).to eq false
        expect(stop_release?).to eq true
      end

      it "does not touch the index" do
        pre_run_solr_count = solr_count

        begin
          CICTL::Commands.start(["index", "all", "--no-wait", "--quiet"])
        rescue CICTL::CICTLError
        end

        expect(solr_count).to eq pre_run_solr_count
        expect(metrics?).to eq false
        expect(stop_release?).to eq true
      end
    end

    context "without using redirect file" do
      override_service(:redirect_file) { "no_such_redirects_file.gz.txt" }
      override_service(:no_redirects?) { true }

      it "runs to completion" do
        expect {
          CICTL::Commands.start(["index", "all", "--no-wait", "--quiet"])
        }.not_to raise_error
        expect(metrics?).to eq true
        expect(stop_release?).to eq false
      end
    end
  end

  describe "#index date" do
    it "indexes full records and deleted record from example date" do
      examples = CICTL::Examples.for_date("20230103")
      CICTL::Commands.start(["index", "date", "20230103", "--quiet"])
      expect(solr_count).to eq unique_id_count(examples)
      expect(File.exist?(CICTL::Journal.new(date: Date.new(2023, 1, 3)).path)).to eq(true)
      expect(metrics?).to eq true
      expect(stop_release?).to eq false
    end

    it "raises on bogus date" do
      expect { CICTL::Commands.start(["index", "date", "this is not even remotely datelike", "--quiet"]) }
        .to raise_error(CICTL::CICTLError)
      expect(metrics?).to eq false
      expect(stop_release?).to eq true
    end
  end

  describe "#index file" do
    context "with no additional parameters" do
      it "indexes full records and no deletes from example file" do
        example = CICTL::Examples.for_date("20230103", type: :upd).first
        file = File.join(HathiTrust::Services[:data_directory], example[:file])
        CICTL::Commands.start(["index", "file", file, "--quiet"])
        expect(solr_count).to eq example[:ids].count
        expect(metrics?).to eq true
        expect(stop_release?).to eq false
      end
    end

    context "that does not exist" do
      it "fails" do
        file = File.join(HathiTrust::Services[:data_directory], "there_is_no_file_by_that_name_here.json.gz")
        expect {
          CICTL::Commands.start(["index", "file", file, "--quiet"])
        }.to raise_error(CICTL::CICTLError)
        expect(metrics?).to eq false
        expect(stop_release?).to eq true
      end
    end

    context "with an explicit reader" do
      context "that exists" do
        it "indexes full records and no deletes from example file" do
          example = CICTL::Examples.for_date("20230103", type: :upd).first
          file = File.join(HathiTrust::Services[:data_directory], example[:file])
          CICTL::Commands.start(["index", "file", file, "--reader", "readers/jsonl", "--quiet"])
          expect(solr_count).to eq example[:ids].count
          expect(metrics?).to eq true
          expect(stop_release?).to eq false
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(HathiTrust::Services[:data_directory], "sample_upd_20230223.json.gz")
          expect {
            CICTL::Commands.start(["index", "file", file, "--reader", "no_such_reader", "--quiet"])
          }.to raise_error(CICTL::CICTLError)
          expect(metrics?).to eq false
          expect(stop_release?).to eq true
        end
      end
    end

    context "with an explicit writer" do
      context "that exists" do
        it "indexes full records and no deletes from example file" do
          example = CICTL::Examples.for_date("20230103", type: :upd).first
          file = File.join(HathiTrust::Services[:data_directory], example[:file])
          CICTL::Commands.start(["index", "file", file, "--writer", "writers/localhost", "--quiet"])
          expect(solr_count).to eq example[:ids].count
          expect(metrics?).to eq true
          expect(stop_release?).to eq false
        end
      end

      context "that does not exist" do
        it "fails" do
          file = File.join(HathiTrust::Services[:data_directory], "sample_upd_20230103.json.gz")
          expect {
            CICTL::Commands.start(["index", "file", file, "--writer", "no_such_writer", "--quiet"])
          }.to raise_error(CICTL::CICTLError)
          expect(metrics?).to eq false
          expect(stop_release?).to eq true
        end
      end
    end
  end

  describe "#index today" do
    # Create new update and delete files in a temp directory based on fixtures.
    after(:each) { HathiTrust::Services.register(:data_directory) { @save_dd } }

    # Note that "today" means "index today, using the file dated yesterday"
    it "indexes 'today' and produces deletes file and journal file" do
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

      CICTL::Commands.start(%w[index today --quiet])

      expect(solr_count).to eq(zcount + delcount)
      expect(CICTL::DeletedRecords.daily_file.readable?)
      expect(Zinzout.zin(CICTL::DeletedRecords.daily_file).count).to eq(delcount)
      expect(File.exist?(CICTL::Journal.new(date: Date.today - 1).path)).to eq(true)
      expect(metrics?).to eq true
      expect(stop_release?).to eq false
    end
  end
end
