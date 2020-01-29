require_relative 'helper'

module Musa
  module MusicXML
    class TimeModification
      include Helper
      include ToXML

      def initialize(actual_notes:, # number
                     normal_notes:, # number
                     normal_type: nil, # quarter / ...
                     normal_dots: nil) # number

        @actual_notes = actual_notes
        @normal_notes = normal_notes
        @normal_type = normal_type
        @normal_dots = normal_dots
      end

      attr_accessor :actual_notes, :normal_notes, :normal_type, :normal_dots

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<time-modification>"

        io.puts "#{tabs}\t<actual-notes>#{@actual_notes}</actual-notes>"
        io.puts "#{tabs}\t<normal-notes>#{@normal_notes}</normal-notes>"
        io.puts "#{tabs}\t<normal-type>#{@normal_type}</normal-type>" if @normal_type
        @normal_dots.times do
          io.puts "#{tabs}\t<normal-dot />"
        end

        io.puts "#{tabs}</time-modification>"
      end
    end

    class Tuplet
      include Helper
      include ToXML

      def initialize(type:, # start / stop
                     number: nil, # number
                     bracket: nil, # true
                     show_number: nil, # actual / both / none
                     show_type: nil, # actual / both / none
                     tuplet_actual_number: nil, # number
                     tuplet_actual_type: nil, # quarter / eigth / ...
                     tuplet_actual_dots: nil, # number,
                     tuplet_normal_number: nil, # number
                     tuplet_normal_type: nil, # quarter / eigth / ...
                     tuplet_normal_dots: nil) # number

        @type = type
        @number = number
        @bracket = bracket
        @show_number = show_number
        @show_type = show_type
        @tuplet_actual_number = tuplet_actual_number
        @tuplet_actual_type = tuplet_actual_type
        @tuplet_actual_dots = tuplet_actual_dots
        @tuplet_normal_number = tuplet_normal_number
        @tuplet_normal_type = tuplet_normal_type
        @tuplet_normal_dots = tuplet_normal_dots
      end

      attr_accessor :type, :number, :bracket, :show_number, :show_type
      attr_accessor :tuplet_actual_number, :tuplet_actual_type, :tuplet_actual_dots
      attr_accessor :tuplet_normal_number, :tuplet_normal_type, :tuplet_normal_dots

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<tuplet type=\"#{@type}\" " \
          "#{decode_bool_or_string_attribute(@number, 'number')} " \
          "#{decode_bool_or_string_attribute(@bracket, 'bracket', 'yes', 'no')} " \
          "#{decode_bool_or_string_attribute(@show_number, 'show-number')} " \
          "#{decode_bool_or_string_attribute(@show_type, 'show-type')} " \
          ">"

        if @tuplet_actual_number || @tuplet_actual_type || @tuplet_actual_dots
          io.puts "#{tabs}\t<tuplet-actual>"

          io.puts "#{tabs}\t\t<tuplet-number>#{@tuplet_actual_number}</tuplet-number>" if @tuplet_actual_number
          io.puts "#{tabs}\t\t<tuplet-type>#{@tuplet_actual_type}</tuplet-type>" if @tuplet_actual_type

          @tuplet_actual_dots.times do
            io.puts "#{tabs}\t\t<tuplet-dot />"
          end

          io.puts "#{tabs}\t</tuplet-actual>"
        end

        if @tuplet_normal_number || @tuplet_normal_type || @tuplet_normal_dots
          io.puts "#{tabs}\t<tuplet-normal>"

          io.puts "#{tabs}\t\t<tuplet-number>#{@tuplet_normal_number}</tuplet-number>" if @tuplet_normal_number
          io.puts "#{tabs}\t\t<tuplet-type>#{@tuplet_normal_type}</tuplet-type>" if @tuplet_normal_type

          @tuplet_normal_dots.times do
            io.puts "#{tabs}\t\t<tuplet-dot />"
          end

          io.puts "#{tabs}\t</tuplet-normal>"
        end

        io.puts "#{tabs}</tuplet>"
     end
    end

    class Harmonic
      include Helper::ToXML

      def initialize(kind: nil, # natural / artificial
                     pitch: nil) # base-pitch / sounding-pitch / touching-pitch

        @kind = kind
        @pitch = pitch
      end

      attr_accessor :kind, :pitch

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<harmonic>"
        io.puts "#{tabs}\t<#{@kind} />" if @kind
        io.puts "#{tabs}\t<#{@pitch} />" if @pitch
        io.puts "#{tabs}</harmonic>"
      end
    end

    class Notehead
      include Helper::NotImplemented
    end

    class Arrow
      include Helper::NotImplemented
    end

    class Bend
      include Helper::NotImplemented
    end

    class Fingering
      include Helper::NotImplemented
    end

    class Hole
      include Helper::NotImplemented
    end
  end
end