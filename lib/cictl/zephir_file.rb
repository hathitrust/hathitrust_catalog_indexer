# frozen_string_literal: true

module CICTL
  # Standard name templates for the three types of files processed by the indexer.
  module ZephirFile
    extend self

    def full_template
      template_prefix + "_full_%Y%m%d_vufind.json.gz"
    end

    def update_template
      template_prefix + "_upd_%Y%m%d.json.gz"
    end

    def delete_template
      template_prefix + "_upd_%Y%m%d_delete.txt.gz"
    end

    def template_prefix
      ENV["CICTL_ZEPHIR_FILE_TEMPLATE_PREFIX"] || "zephir"
    end

    # @return [DateNamedFile::Directory]
    def full_files
      DateNamedFile.new(full_template).in_dir(HathiTrust::Services["data_directory"])
    end

    # @return [DateNamedFile::Directory]
    def update_files
      DateNamedFile.new(update_template).in_dir(HathiTrust::Services["data_directory"])
    end

    # @return [DateNamedFile::Directory]
    def delete_files
      DateNamedFile.new(delete_template).in_dir(HathiTrust::Services["data_directory"])
    end
  end
end
