# frozen_string_literal: true

require "spec_helper"
require "zinzout"

RSpec.describe CICTL::DeletedRecords do
  override_service(:data_directory) { Dir.mktmpdir }

  it "gets something for today's file" do
    expect(described_class.daily_file.to_s).to match(/deleted_records/)
  end

  it "will write to a file" do
    arbitrary_past_date = 20230101
    File.open(described_class.daily_file(arbitrary_past_date), "w:utf-8") { |f| f.puts "Hello world" }
    expect(described_class.daily_file(arbitrary_past_date).size).to eq(12)
  end

  it "will find the most recent non-empty file" do
    arbitrary_past_date = 20230101
    next_day = arbitrary_past_date + 1
    Zinzout.zout(described_class.daily_file(arbitrary_past_date)) { |f| f.puts "Hello world" }
    Zinzout.zout(described_class.daily_file(next_day)) { |f| } # create empty file
    expect(described_class.daily_template.count).to eq(2)
    expect(described_class.most_recent_non_empty_file.to_s).to match(/#{arbitrary_past_date}/)
  end
end
