# frozen_string_literal: true

require 'zinzout'
require_relative "../services"

# Redirect file is .txt.gz file with each line in the format
# "old_cid\tnew_cid"
#
# The example file contains the line "000004165	006215998" (old, new) so
# redirects["006215998"] -> ["000004165"]

module HathiTrust
  class MockRedirects
    def old_ids_for(id)
      []
    end

    def load
    end
  end
end
