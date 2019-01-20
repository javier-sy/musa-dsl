require 'musa-dsl/series'
require 'citrus'

module Musa::Neumalang
  module Sentences
    include Musa::Series

    def value
      S(*captures(:sentence).collect(&:value))
    end
  end

  module Bracketed_2bar_sentences
    include Musa::Series

    def value
      { kind: :parallel, parallel: [{ kind: :serie, serie: S(*capture(:aa).value) }] + captures(:bb).collect { |c| { kind: :serie, serie: S(*c.value) } } }
    end
  end

  module Bracketed_sentences
    include Musa::Series

    def value
      { kind: :serie, serie: S(*capture(:sentences).value) }
    end
  end

  def self.register(grammar_path)
    Citrus.load grammar_path
  end

  def self.parse(string_or_file, language: nil, decode_with: nil, debug: nil)
    language ||= Neumalang

    match = nil

    if string_or_file.is_a? String
      match = language.parse string_or_file

    elsif string_or_file.is_a? File
      match = language.parse string_or_file.read

    else
      raise ArgumentError, 'Only String or File allowed to be parsed'
    end

    match.dump if debug

    serie = match.value

    puts
    pp serie

    serie = serie.prototype

    puts
    pp serie



    if decode_with
      serie.eval do |e|
        if e[:kind] == :neuma
          decode_with.decode(e[:neuma])
        else
          raise ArgumentError, "Don't know how to convert #{e} to neuma"
        end
      end
    else
      serie
    end
  end

  def self.parse_file(filename, decode_with: nil, debug: nil)
    File.open filename do |file|
      parse file, decode_with: decode_with, debug: debug
    end
  end

  register File.join(File.dirname(__FILE__), 'neumalang')
end
