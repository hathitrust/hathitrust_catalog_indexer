RSpec.describe HathiTrust::CLI::Environment do
  describe "#solr_url" do
    context "with ENV set" do
      let(:sdoc) { JSON.parse(File.read("spec/data/001718542.json")) }
      it "does not output empty tags" do
        expect(dc_elements.any? { |e| e.children.empty? }).to be false
      end

      it "returns expected fields" do
        expect(dc_elements.map(&:name)).to include(
          *%w[ title creator subject description
            publisher date type format
            identifier language rights]
        )
      end
    end

    context "with minimal record" do
      let(:sdoc) { JSON.parse(File.read("spec/data/minimal.json")) }
      it "does not output empty tags" do
        expect(dc_elements.any? { |e| e.children.empty? }).to be false
      end

      it "includes minimal fields" do
        expect(dc_elements.map(&:name)).to include(
          *%w[title type identifier rights]
        )
      end
    end
  end
end
