# frozen_string_literal: true

module CICTL
  # Standard name templates for the three types of files processed by the indexer.
  module ZephirFile
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

    module_function :full_template, :update_template, :delete_template, :template_prefix
  end
end
