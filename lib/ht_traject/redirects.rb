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
    def old_ids_for(id)
      redirects[id] || []
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
