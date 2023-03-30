require "spec_helper"

RSpec.describe Date do
  describe ".with" do
    it "returns Date unchanged" do
      today = described_class.today
      expect(described_class.with(today)).to equal today
    end

    it "returns Date based on String" do
      expect(described_class.with("2000-01-01")).to eq Date.parse("2000-01-01")
    end
  end

  describe ".last_day_of_last_month" do
    it "returns the last day of the previous month given a date" do
      expect(described_class.last_day_of_last_month(Date.parse("2020-01-01")).to_s).to eq "2019-12-31"
    end

    it "returns the last day of the previous month by default" do
      expect(described_class.last_day_of_last_month).to eq Date.today - Date.today.mday
    end
  end
end
