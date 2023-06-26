# frozen_string_literal: true

# These are the examples used as fixtures in the cictl specs.
# There is a single monthly file with 16 items.
# There is an update file with the same date as the monthly, having 32 items.
# There are three subsequent daily items with 2, 4, and 8 records in chronological order.
# Each of these dailies has a delete file that deletes one record (the first) from the previous day.
module CICTL
  module Examples
    EXAMPLES = [
      {file: "sample_full_20221231_vufind.json.gz",
       ids: %w[000130709 000130743 000133681 000134961 000135338
         000140576 000142300 000144850 000148196 000148482
         000149639 000153714 000156363 000157598 000157860
         000165447],
       type: :full,
       date: "20221231"},
      {file: "sample_upd_20221231.json.gz",
       ids: %w[000009336 000014526],
       type: :upd,
       date: "20221231"},
      {file: "sample_upd_20230101.json.gz",
       ids: %w[000007392 000020235 000030447 000006709 000019736
         000045827 000045652 000047519 000050019 000050384
         000049738 000050857 000048474 000046126 000050023
         000049721 000051290 000051910 000047070 000051354
         000051907 000051550 000053471 000046651 000052581
         000046914 000052525 000052613 000051947 000053000
         000049292 000045245],
       type: :upd,
       date: "20230101"},
      {file: "sample_upd_20230101_delete.txt.gz",
       ids: %w[000130709],
       type: :delete,
       date: "20230101"},
      {file: "sample_upd_20230102.json.gz",
       ids: %w[000048849 000050199 000051247 000051671],
       type: :upd,
       date: "20230102"},
      {file: "sample_upd_20230102_delete.txt.gz",
       ids: %w[000009336],
       type: :delete,
       date: "20230102"},
      {file: "sample_upd_20230103.json.gz",
       ids: %w[000055197 000055313 000055797 000056190 000057209
         000058181 000058183 000058228],
       type: :upd,
       date: "20230103"},
      {file: "sample_upd_20230103_delete.txt.gz",
       ids: %w[000048849],
       type: :delete,
       date: "20230103"}
    ].freeze

    def all_ids
      EXAMPLES.map { |ex| ex[:ids] }.flatten.uniq
    end

    def for_date(date, type: nil)
      if type
        EXAMPLES.select { |ex| ex[:date] == date && ex[:type] == type }
      else
        EXAMPLES.select { |ex| ex[:date] == date }
      end
    end

    # delete file with single newline
    def empty_delete_file
      "sample_empty_delete.txt.gz"
    end

    # Delete file with blank lines
    def blank_line_delete_file
      "sample_blank_line_delete_file.txt.gz"
    end

    # delete file with spaces and non-numeric text
    def noisy_delete_file
      "sample_noisy_delete.txt.gz"
    end

    module_function :all_ids, :for_date, :empty_delete_file, :noisy_delete_file, :blank_line_delete_file
  end
end
