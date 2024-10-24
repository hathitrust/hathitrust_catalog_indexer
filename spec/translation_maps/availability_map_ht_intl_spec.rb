# frozen_string_literal: true

require "spec_helper"
require "ht_traject/ht_constants"

module AvailabilitynMapHTINTL
  TESTS = {
    "pd" => [HathiTrust::Constants::FT], # 1
    "ic" => [HathiTrust::Constants::SO], # 2
    "op" => [HathiTrust::Constants::SO], # 3
    "orph" => [HathiTrust::Constants::SO], # 4
    "und" => [HathiTrust::Constants::SO], # 5
    "umall" => [HathiTrust::Constants::SO], # 6
    "ic-world" => [HathiTrust::Constants::FT], # 7
    "nobody" => [HathiTrust::Constants::SO], # 8
    "pdus" => [HathiTrust::Constants::SO], # 9
    "cc-by-3.0" => [HathiTrust::Constants::FT], # 10
    "cc-by-nd-3.0" => [HathiTrust::Constants::FT], # 11
    "cc-by-nc-nd-3.0" => [HathiTrust::Constants::FT], # 12
    "cc-by-nc-3.0" => [HathiTrust::Constants::FT], # 13
    "cc-by-nc-sa-3.0" => [HathiTrust::Constants::FT], # 14
    "cc-by-sa-3.0" => [HathiTrust::Constants::FT], # 15
    "orphcand" => [HathiTrust::Constants::SO], # 16
    "cc-zero" => [HathiTrust::Constants::FT], # 17
    "und-world" => [HathiTrust::Constants::FT], # 18
    "icus" => [HathiTrust::Constants::FT], # 19
    "cc-by-4.0" => [HathiTrust::Constants::FT], # 20
    "cc-by-nd-4.0" => [HathiTrust::Constants::FT], # 21
    "cc-by-nc-nd-4.0" => [HathiTrust::Constants::FT], # 22
    "cc-by-nc-4.0" => [HathiTrust::Constants::FT], # 23
    "cc-by-nc-sa-4.0" => [HathiTrust::Constants::FT], # 24
    "cc-by-sa-4.0" => [HathiTrust::Constants::FT], # 25
    "pd-pvt" => [HathiTrust::Constants::SO], # 26
    "supp" => [HathiTrust::Constants::SO] # 27
  }.freeze

  RSpec.describe AvailabilitynMapHTINTL do
    let(:map) {
      rb_file = File.expand_path("../../lib/translation_maps/ht/availability_map_ht_intl.rb", __dir__)
      # Traject uses `eval` on these files, and alas so must we (apparently).
      eval(File.read(rb_file), binding, rb_file) # standard:disable Security/Eval
    }

    it "is non-nil" do
      expect(map).not_to eq nil
    end

    TESTS.each do |input, expected|
      it "maps #{input} to #{expected}" do
        expect(map[input]).to eq expected
      end
    end
  end
end
