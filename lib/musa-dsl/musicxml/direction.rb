require_relative 'helper'

module Musa
  module MusicXML
    class Direction
      include Helper
      include ToXML

      def initialize(type, # [ DirectionType | Hash ] | Array of (DirectionType | Hash)
                     voice: nil, # number
                     staff: nil) # number

        @voice = voice
        @staff = staff

        @types = type.arrayfy.collect do |t|
          case t
          when DirectionType
            t
          when Hash
            klass = nil
            case t[:kind]
            when Class
              klass = t[:kind]
            when Symbol, String
              name = t[:kind].to_s.split('_').collect(&:capitalize).join
              klass = DirectionType.descendants.find { |c| name == c.name.split('::').last }
            end
            raise ArgumentError, "Direction kind #{t[:kind]} not found" unless klass

            make_instance_if_needed(klass, t.clone.tap { |t| t.delete :kind })
          else
            # impossible
          end
        end
      end

      attr_accessor :voice, :staff, :offset

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<direction>"

        @types.each do |type|
          io.puts "#{tabs}\t<direction-type>"
          type.to_xml(io, indent: indent + 2)
          io.puts "#{tabs}\t</direction-type>"
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

      def self.descendants
        descendants = []
        ObjectSpace.each_object(singleton_class) do |k|
          next if k.singleton_class?
          descendants.unshift k unless k == self
        end
        descendants
      end
    end

    private_constant :DirectionType

    class Wedge < DirectionType
      include Helper

      def initialize(type:, #  crescendo / diminuendo / stop / continue
                     niente: nil) # true
        @type = type
        @niente = niente
      end

      attr_accessor :type, :niente

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<wedge type=\"#{@type}\" #{decode_bool_or_string_attribute(@niente, 'niente', 'yes', 'no')} />"
      end
    end

    class Dynamics < DirectionType
      def initialize(value:) # pp / ppp / ... or array of
        @dynamics = value.arrayfy
      end

      attr_accessor :dynamics

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<dynamics>"

        @dynamics.each do |dynamics|
          io.puts "#{tabs}\t<#{dynamics} />"
        end

        io.puts "#{tabs}</dynamics>"
      end
    end

    class Pedal < DirectionType
      include Helper

      def initialize(type:, # start / stop / change / continue
                     line: nil) # true

        @type = type
        @line = line
      end

      attr_accessor :type, :line

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<pedal type=\"#{@type}\" #{decode_bool_or_string_attribute(@line, 'line', 'yes', 'no')} />"
      end
    end

    class Bracket < DirectionType
      include Helper

      def initialize(type:, # start / stop / continue
                     line_end:, # up / down / both / arrow / none
                     line_type: nil) # solid / dashed / dotted / wavy

        @type = type
        @line_end = line_end
        @line_type = line_type
      end

      attr_accessor :type, :line_type, :line_end

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<bracket type=\"#{@type}\" line_end=\"#{@line_end}\" #{decode_bool_or_string_attribute(@line_type, 'line_type')} />"
      end
    end

    class Dashes < DirectionType
      def initialize(type:) # start / stop / continue
        @type = type
      end

      attr_accessor :type

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<dashes type=\"#{@type}\" />"
      end
    end

    class Words < DirectionType
      def initialize(value:) # string | Array of string
        @words = value.arrayfy
      end

      attr_accessor :words

      def _to_xml(io, indent:, tabs:)
        @words.each do |words|
          io.puts "#{tabs}<words>#{words}</words>"
        end
      end
    end

    class OctaveShift < DirectionType
      include Helper

      def initialize(type:, # up / down / stop / continue
                     size: nil) # number
        @type = type
        @size = size
      end

      attr_accessor :type, :size

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<octave-shift type=\"#{@type}\" #{decode_bool_or_string_attribute(@size, 'size')} />"
      end
    end

    class Metronome < DirectionType
      include Helper

      # TODO complete Metronome complexity!

      def initialize(beat_unit:, # quarter / eighth / ...
                     beat_unit_dots: nil, # number
                     per_minute:) #string
        @beat_unit = beat_unit
        @beat_unit_dots = beat_unit_dots
        @per_minute = per_minute
      end

      attr_accessor :beat_unit, :beat_unit_dots, :per_minute

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<metronome>"

        io.puts "#{tabs}\t<beat-unit>#{@beat_unit}</beat-unit>"
        @beat_unit_dots&.times do
          io.puts "#{tabs}\t<beat-unit-dot />"
        end
        io.puts "#{tabs}\t<per-minute>#{@per_minute}</per-minute>"

        io.puts "#{tabs}</metronome>"
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