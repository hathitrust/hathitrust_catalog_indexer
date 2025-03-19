# frozen_string_literal: true

module CICTL
  # A class that controls the STOPCATALOGRELEASE file
  # which is written at the beginning of `cictl index` commands
  # and removed if all goes well.

  # File location is controlled by the FLAGS_DIRECTORY environment variable
  # and defaults to DDIR + "flags", mainly for running under Docker.
  # For ease of testing this class will create FLAGS_DIRECTORY if necessary; however,
  # it is recommended that the directory be created beforehand with the desired permissions.
  class StopRelease
    FILE_NAME = "STOPCATALOGRELEASE"

    def path
      @path ||= File.join(flags_directory, FILE_NAME)
    end

    def write
      if !File.directory?(flags_directory)
        FileUtils.mkdir_p flags_directory
      end
      FileUtils.touch path
    end

    def remove
      FileUtils.rm path, force: true
    end

    private

    def flags_directory
      ENV["FLAGS_DIRECTORY"] || File.join(HathiTrust::Services[:data_directory], "flags")
    end
  end
end
