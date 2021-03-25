# frozen_string_literal: true

require_relative '../naconormalizer.rb' if defined? JRUBY_VERSION

module HathiTrust::BasicMacros
  SPACES = /\s+/.freeze

  class FakoNormalizer # see what I did there? :-)
    def normalize(str)
      str.upcase.gsub(/\p{Punct}/, ' ').gsub(SPACES, ' ')
    end
  end

  def downcase
    lambda do |_rec, acc|
      acc.map! { |x| x.downcase }
    end
  end

  def compress_spaces
    spaces = /\s+/
    lambda do |_rec, acc|
      acc.map! { |x| x.gsub(spaces, ' ') }
    end
  end

  def strip_punctuation
    lead_or_trail_punct = /\A[\s\p{Punct}]*(.+?)[\s\p{Punct}]*\Z/
    lambda do |_rec, acc|
      acc.map! { |x| lead_or_trail_punct.match(x)[1] }
    end
  end

  def depunctuate
    punctuation = /\p{P}/
    lambda do |_rec, acc|
      acc.map! { |x| x.gsub(punctuation, ' ').gsub(SPACES, ' ') }
    end
  end

  def naconormalize
    normalizer = if defined? NacoNormalizer
                   NacoNormalizer.new
                 else
                   FakoNormalizer.new
                 end

    lambda do |_rec, acc|
      acc.map! { |x| normalizer.normalize(x).strip }
    end
  end
end
