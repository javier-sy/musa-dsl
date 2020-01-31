require_relative 'helper'

module Musa
  module MusicXML
    class Direction
      extend AttributeBuilder
      include AsContextRun

      include Helper
      include ToXML

      def initialize(voice: nil, # number
                     staff: nil,  # number
                     **directions,
                     &block)

        @types = []
        @voice = voice
        @staff = staff

        directions.each_pair do |direction, value|
          send direction, value
        end

        as_context_run block if block_given?
      end

      attr_simple_builder :voice
      attr_simple_builder :staff
      attr_simple_builder :offset

      attr_complex_adder_to_custom(:metronome) { |*p, **kp, &b| Metronome.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:wedge) { |*p, **kp, &b| Wedge.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:dynamics) { |*p, **kp, &b| Dynamics.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:pedal) { |*p, **kp, &b| Pedal.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:bracket) { |*p, **kp, &b| Bracket.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:dashes) { |*p, **kp, &b| Dashes.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:words) { |*p, **kp, &b| Words.new(*p, **kp, &b).tap { |t| @types << t } }
      attr_complex_adder_to_custom(:octave_shift) { |*p, **kp, &b| OctaveShift.new(*p, **kp, &b).tap { |t| @types << t } }

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<direction>"

        @types.each do |type|
          type.to_xml(io, indent: indent + 1)
        end

        io.puts "#{tabs}<voice>#{@voice}</voice>" if @voice
        io.puts "#{tabs}<staff>#{@staff}</staff>" if @staff

        io.puts "#{tabs}</direction>"
      end

      private

      def direction_type_to_xml(io, indent:); end
    end

    class DirectionType
      include Helper::ToXML

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<direction-type>"
        _direction_type_to_xml(io, indent: indent + 1, tabs: tabs + "\t")
        io.puts "#{tabs}</direction-type>"
      end
    end

    private_constant :DirectionType

    class Metronome < DirectionType
      extend AttributeBuilder
      include AsContextRun

      include Helper

      # TODO complete Metronome complexity!

      def initialize(beat_unit:, # quarter / eighth / ...
                     beat_unit_dots: nil, # number
                     per_minute:, #string
                     &block)

        @beat_unit = beat_unit
        @beat_unit_dots = beat_unit_dots
        @per_minute = per_minute

        as_context_run block if block_given?
      end

      attr_simple_builder :beat_unit
      attr_simple_builder :beat_unit_dots
      attr_simple_builder :per_minute

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<metronome>"

        io.puts "#{tabs}\t<beat-unit>#{@beat_unit}</beat-unit>"
        @beat_unit_dots&.times do
          io.puts "#{tabs}\t<beat-unit-dot />"
        end
        io.puts "#{tabs}\t<per-minute>#{@per_minute}</per-minute>"

        io.puts "#{tabs}</metronome>"
      end
    end

    class Wedge < DirectionType
      include Helper

      def initialize(type, #  crescendo / diminuendo / stop / continue
                     niente: nil) # true
        @type = type
        @niente = niente
      end

      attr_accessor :type, :niente

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<wedge type=\"#{@type}\" #{decode_bool_or_string_attribute(@niente, 'niente', 'yes', 'no')} />"
      end
    end

    class Dynamics < DirectionType
      def initialize(value) # pp / ppp / ... or array of
        @dynamics = value.arrayfy
      end

      attr_accessor :dynamics

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<dynamics>"

        @dynamics.each do |dynamics|
          io.puts "#{tabs}\t<#{dynamics} />"
        end

        io.puts "#{tabs}</dynamics>"
      end
    end

    class Pedal < DirectionType
      include Helper

      def initialize(type, # start / stop / change / continue
                     line: nil) # true

        @type = type
        @line = line
      end

      attr_accessor :type, :line

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<pedal type=\"#{@type}\" #{decode_bool_or_string_attribute(@line, 'line', 'yes', 'no')} />"
      end
    end

    class Bracket < DirectionType
      include Helper

      def initialize(type, # start / stop / continue
                     line_end:, # up / down / both / arrow / none
                     line_type: nil) # solid / dashed / dotted / wavy

        @type = type
        @line_end = line_end
        @line_type = line_type
      end

      attr_accessor :type, :line_type, :line_end

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<bracket type=\"#{@type}\" line_end=\"#{@line_end}\" #{decode_bool_or_string_attribute(@line_type, 'line_type')} />"
      end
    end

    class Dashes < DirectionType
      def initialize(type) # start / stop / continue
        @type = type
      end

      attr_accessor :type

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<dashes type=\"#{@type}\" />"
      end
    end

    class Words < DirectionType
      def initialize(value) # string | Array of string
        @words = value.arrayfy
      end

      attr_accessor :words

      def _direction_type_to_xml(io, indent:, tabs:)
        @words.each do |words|
          io.puts "#{tabs}<words>#{words}</words>"
        end
      end
    end

    class OctaveShift < DirectionType
      include Helper

      def initialize(type, # up / down / stop / continue
                     size: nil) # number
        @type = type
        @size = size
      end

      attr_accessor :type, :size

      def _direction_type_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<octave-shift type=\"#{@type}\" #{decode_bool_or_string_attribute(@size, 'size')} />"
      end
    end

    class AccordionRegistration < DirectionType
      include Helper::NotImplemented
    end

    class Coda < DirectionType
      include Helper::NotImplemented
    end

    class Damp < DirectionType
      include Helper::NotImplemented
    end

    class DampAll < DirectionType
      include Helper::NotImplemented
    end

    class EyeGlasses < DirectionType
      include Helper::NotImplemented
    end

    class HarpPedals < DirectionType
      include Helper::NotImplemented
    end

    class Image < DirectionType
      include Helper::NotImplemented
    end

    class OtherDirection < DirectionType
      include Helper::NotImplemented
    end

    class Percussion < DirectionType
      include Helper::NotImplemented
    end

    class PrincipalVoice < DirectionType
      include Helper::NotImplemented
    end

    class Rehearsal < DirectionType
      include Helper::NotImplemented
    end

    class Scordatura < DirectionType
      include Helper::NotImplemented
    end

    class Segno < DirectionType
      include Helper::NotImplemented
    end

    class StringMute < DirectionType
      include Helper::NotImplemented
    end
  end
end