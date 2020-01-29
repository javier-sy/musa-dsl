require_relative 'helper'

module Musa
  module MusicXML
    class Attributes
      include Helper::ToXML

      def initialize(divisions: nil,
                     key_cancel: nil, key_fifths: nil, key_mode: nil,
                     time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
                     clef_sign: nil, clef_line: nil, clef_octave_change: nil)

        @divisions = divisions

        @keys = []
        @times = []
        @clefs = []

        add_key cancel: key_cancel, fifths: key_fifths, mode: key_mode if key_fifths
        add_time senza_misura: time_senza_misura, beats: time_beats, beat_type: time_beat_type if time_senza_misura || (time_beats && time_beat_type)
        add_clef sign: clef_sign, line: clef_line, octave_change: clef_octave_change if clef_sign
      end

      attr_accessor :divisions, :staves
      attr_reader :keys, :times, :clefs

      def add_key(cancel: nil, fifths:, mode: nil)
        Key.new(@keys.size + 1, cancel: cancel, fifths: fifths, mode: mode).tap { |key| @keys << key }
      end

      def add_time(senza_misura: nil, beats: nil, beat_type: nil)
        Time.new(@times.size + 1, senza_misura: senza_misura,
                 beats: beats, beat_type: beat_type).tap { |time| @times << time }
      end

      def add_clef(sign:, line: nil, octave_change: nil)
        Clef.new(@clefs.size + 1, sign: sign, line: line, octave_change: octave_change).tap { |clef| @clefs << clef }
      end

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
    end
  end
end