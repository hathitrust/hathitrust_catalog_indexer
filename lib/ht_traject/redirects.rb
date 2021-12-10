# frozen_string_literal: true

require 'zinzout'

module HathiTrust
  class Redirects

    FILENAME = ENV['redirect_file'] || 'data/redirects.txt'

    # Now we have old->new
    # Need new -> [old1, old2]

    REDIRS = Zinzout.zin(FILENAME).each_with_object({}) do |line, h  |
      old_id, new_id = line.chomp.split(/\t/)
      h[new_id] ||= Array.new
      h[new_id] << old_id
    end

    def self.old_ids_for(id)
      REDIRS[id] || []
    end

  end
end