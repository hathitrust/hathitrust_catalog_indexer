# frozen_string_literal: true

# These are the examples used as fixtures in the cictl specs.
# There is a single monthly file with 16 items.
# There are four daily items with 2, 4, and 8 records in chronological order.
# Each daily has a delete file that deletes one record (the first) from the previous day.
module CICTL
  EXAMPLES = [
    {file: "sample_full_20221231_vufind.json.gz",
     ids: %w[000130709 000130743 000133681 000134961 000135338
       000140576 000142300 000144850 000148196 000148482
       000149639 000153714 000156363 000157598 000157860
       000165447],
     type: :monthly},
    {file: "sample_upd_20230101.json.gz",
     ids: %w[000009336 000014526],
     type: :daily},
    {file: "sample_upd_20230101_delete.txt",
     ids: %w[000130709],
     type: :delete},
    {file: "sample_upd_20230102.json.gz",
     ids: %w[000048849 000014526 000051247 000051671],
     type: :daily},
    {file: "sample_upd_20230102_delete.txt",
     ids: %w[000009336],
     type: :delete},
    {file: "sample_upd_20230103.json.gz",
     ids: %w[000055197 000055313 000055797 000056190 000057209
       000058181 000058183 000058228],
     type: :daily},
    {file: "sample_upd_20230103_delete.txt",
     ids: %w[000048849],
     type: :delete}
  ].freeze
end
