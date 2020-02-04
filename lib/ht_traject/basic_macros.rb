# frozen_string_literal: true

if defined? JRUBY_VERSION
  require 'naconormalizer'
end


module HathiTrust::BasicMacros

  SPACES = /\s+/

  class FakoNormalizer # see what I did there? :-)
    def normalize(str)
      str.upcase.gsub(/\p{Punct}/, ' ').gsub(SPACES, ' ')
    end
  end

  def downcase
    ->(rec, acc) do
      acc.map! {|x| x.downcase}
    end
  end

  def compress_spaces
    spaces = /\s+/
    ->(rec, acc) do
      acc.map! {|x| x.gsub(spaces, ' ')}
    end
  end

  def strip_punctuation
    lead_or_trail_punct = /\A[\s\p{Punct}]*(.+?)[\s\p{Punct}]*\Z/
    ->(rec, acc) do
      acc.map! {|x| lead_or_trail_punct.match(x)[1]}
    end
  end

  def depunctuate
    punctuation = /\p{P}/
    ->(rec, acc) do
      acc.map! {|x| x.gsub(punctuation, ' ').gsub(SPACES, ' ')}
    end
  end


  def naconormalize
    if defined? NacoNormalizer
      normalizer = NacoNormalizer.new
    else
      normalizer = FakoNormalizer.new
    end

    ->(rec, acc) do
      acc.map! {|x| normalizer.normalize(x).strip }
    end
  end

end
