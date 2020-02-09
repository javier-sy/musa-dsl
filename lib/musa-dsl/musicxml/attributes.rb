require_relative '../core-ext/with'

require_relative 'helper'

module Musa
  module MusicXML

    class Key
      include Helper::ToXML

      def initialize(number = nil, cancel: nil, fifths:, mode: nil)
        @number = number

        @cancel = cancel
        @fifths = fifths
        @mode = mode
      end

      attr_reader :number
      attr_accessor :cancel, :fifths, :mode

      def _to_xml(io, indent:, tabs:)
        io ||= StringIO.new
        indent ||= 0

        tabs = "\t" * indent

        io.puts "#{tabs}<key#{" number=\"#{@number}\"" if @number}>"

        io.puts "#{tabs}\t<cancel>#{@cancel}</cancel>" if @cancel
        io.puts "#{tabs}\t<fifths>#{@fifths}</fifths>"
        io.puts "#{tabs}\t<mode>#{@mode}</mode>"

        io.puts "#{tabs}</key>"

        io
      end
    end

    class Time
      include Helper::ToXML

      def initialize(number = nil, senza_misura: nil, beats: nil, beat_type: nil)
        @number = number

        @senza_misura = senza_misura unless beats && beat_type
        @beats = []

        add_beats beats: beats, beat_type: beat_type if beats && beat_type
      end

      attr_reader :number
      attr_accessor :senza_misura
      attr_reader :beats

      def add_beats(beats:, beat_type:)
        @beats << { beats: beats, beat_type: beat_type }
      end

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<time#{" number=\"#{@number}\"" if @number}>"

        io.puts "#{tabs}\t<senza-misura>#{@senza_misura}</senza-misura>" if @senza_misura
        @beats.each do |beats|
          io.puts "#{tabs}\t<beats>#{beats[:beats]}</beats>"
          io.puts "#{tabs}\t<beat-type>#{beats[:beat_type]}</beat-type>"
        end

        io.puts "#{tabs}</time>"
      end
    end

    class Clef
      include Helper::ToXML

      def initialize(number = nil, sign:, line:, octave_change: nil)
        @number = number
        @sign = sign
        @line = line
        @octave_change = octave_change
      end

      attr_reader :number
      attr_accessor :sign, :line, :octave_change

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<clef#{" number=\"#{@number}\"" if @number}>"

        io.puts "#{tabs}\t<sign>#{@sign}</sign>"
        io.puts "#{tabs}\t<line>#{@line}</line>" if @line
        io.puts "#{tabs}\t<clef-octave-change>#{@octave_change}</clef-octave-change>" if @octave_change

        io.puts "#{tabs}</clef>"
      end
    end

    class Attributes
      extend AttributeBuilder
      include With

      include Helper::ToXML

      def initialize(divisions: nil,
                     key_cancel: nil, key_fifths: nil, key_mode: nil,
                     time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
                     clef_sign: nil, clef_line: nil, clef_octave_change: nil,
                     &block)

        @divisions = divisions

        @keys = []
        @times = []
        @clefs = []

        add_key cancel: key_cancel, fifths: key_fifths, mode: key_mode if key_fifths
        add_time senza_misura: time_senza_misura, beats: time_beats, beat_type: time_beat_type if time_senza_misura || (time_beats && time_beat_type)
        add_clef sign: clef_sign, line: clef_line, octave_change: clef_octave_change if clef_sign

        with &block if block_given?
      end

      attr_simple_builder :divisions

      attr_complex_adder_to_array :key, Key
      attr_complex_adder_to_array :time, Time
      attr_complex_adder_to_array :clef, Clef

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<attributes>"

        io.puts "#{tabs}\t<divisions>#{@divisions}</divisions>" if @divisions

        @keys.each do |key|
          key.to_xml(io, indent: indent + 1)
        end

        @times.each do |time|
          time.to_xml(io, indent: indent + 1)
        end

        staves = [@keys.size, @times.size, @clefs.size].max
        io.puts "#{tabs}\t<staves>#{staves}</staves>" if staves > 1

        @clefs.each do |clef|
          clef.to_xml(io, indent: indent + 1)
        end

        io.puts "#{tabs}</attributes>"
      end
    end
  end
end