# frozen_string_literal: true

# Redirect file is .txt.gz file with each line in the format
# "old_cid\tnew_cid"
#
# The example file contains the line "000004165	006215998" (old, new) so
# redirects["006215998"] -> ["000004165"]

require 'zinzout'

module HathiTrust
  class Redirects
    def initialize(redirect_file = nil)
      @redirect_file = redirect_file
    end

    # Raising an exception inside Canister is a bad idea so we leave error handling
    # to the host.
    def exist?
      File.exist? @redirect_file
    end

    def old_ids_for(id)
      redirects[id] || []
    end
    alias_method :[], :old_ids_for

    private

    # Map each old->new into new -> [old1, old2] structure
    def redirects
      return {} unless exist?

      @redirects ||= Zinzout.zin(@redirect_file).each_with_object({}) do |line, h |
        old_id, new_id = line.chomp.split(/\t/)
        h[new_id] ||= Array.new
        h[new_id] << old_id
      end
    end
  end
end
