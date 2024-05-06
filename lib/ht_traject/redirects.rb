# frozen_string_literal: true

require 'zinzout'
require_relative "../services"

# Redirect file is .txt.gz file with each line in the format
# "old_cid\tnew_cid"
#
# The example file contains the line "000004165	006215998" (old, new) so
# redirects["006215998"] -> ["000004165"]

module HathiTrust
  class Redirects
    def self.redirects_file_name(date: Date.today)
      "redirects_#{date.strftime "%Y%m"}.txt.gz"
    end

    def self.default_redirects_file(directory: "/htapps/babel/hathifiles/catalog_redirects/redirects")
      default_file = File.join(directory, redirects_file_name)
      if !File.exist?(default_file)
        # Fall back to previous month's (that's what the << method does) file
        default_file = File.join(directory, redirects_file_name(date: Date.today << 1))
      end
      default_file
    end

    def old_ids_for(id)
      redirects[id] || []
    end

    def load
      if !@redirects
        Services[:logger].info("Loading redirects from #{Services[:redirect_file]}")
        redirects
      end
    end

    private

    def redirects
      @redirects ||= Zinzout.zin(Services[:redirect_file]).each_with_object({}) do |line, h|
        old_id, new_id = line.chomp.split(/\t/)
        h[new_id] ||= Array.new
        h[new_id] << old_id
      end
    end
  end
end
