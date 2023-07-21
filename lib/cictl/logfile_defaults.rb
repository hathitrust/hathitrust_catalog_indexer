# frozen_string_literal: true

require_relative "../services"
require "pathname"
require "date"
require "date_named_file"

module CICTL
  module LogfileDefaults
    extend self

    def logdir
      HathiTrust::Services[:logfile_directory]
    end

    def logdir=(path)
      Pathname.new(path).mkpath
      HathiTrust::Services.register(:logfile_directory) { path }
    end

    def filepath_of(str)
      (Pathname.new(logdir) + str).to_s
    end

    def today_yyyymmdd
      Date.today.strftime("%Y%m%d")
    end

    alias_method :daily_yyyymmdd, :today_yyyymmdd

    def daily_template
      DateNamedFile.new("daily_%Y%m%d.log").in_dir(logdir)
    end

    def full_template
      DateNamedFile.new("full_%Y%m%d.log").in_dir(logdir)
    end

    def daily(yyyymmdd = today_yyyymmdd)
      daily_template.at(yyyymmdd)
    end

    alias_method :today, :daily

    def full(yyyymmdd = today_yyyymmdd)
      full_template.at(yyyymmdd)
    end
  end
end
