
# Monkeypatch MARC::Record for speed
module MARC
  class FieldMap
    def each_by_tag(tags)
      reindex unless @clean
      indices = []
      # Get all the indices associated with the tags
      Array(tags).each do |t|
        indices.concat @tags[t] if @tags[t]
      end

      # Remove any nils
      indices.compact!
      return [] if indices.empty?

      # Sort it, so we get the fields back in the order they appear in the record
      indices.sort!

      indices.each do |tag|
        yield self[tag]
      end
    end
  end
end