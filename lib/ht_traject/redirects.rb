# frozen_string_literal: true

require 'zinzout'
require 'date'

module HathiTrust
  class Redirects

    yyyymm = DateTime.now.strftime '%Y%m'
    default_file  = "/htapps/babel/hathifiles/catalog_redirects/redirects/redirects_#{yyyymm}.txt.gz"
    FILENAME = ENV['redirect_file'] || default_file

    unless File.exist? FILENAME
      $stderr.puts "Can't find redirets file `#{FILENAME}`. Set manually with ENV['redirect_file']."
      exit 1
    end
    
    
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
