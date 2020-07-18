require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
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
            @normal_dots&.times do
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
                         actual_number: nil, # number
                         actual_type: nil, # quarter / eigth / ...
                         actual_dots: nil, # number,
                         normal_number: nil, # number
                         normal_type: nil, # quarter / eigth / ...
                         normal_dots: nil) # number

            @type = type
            @number = number
            @bracket = bracket
            @show_number = show_number
            @show_type = show_type
            @actual_number = actual_number
            @actual_type = actual_type
            @actual_dots = actual_dots
            @normal_number = normal_number
            @normal_type = normal_type
            @normal_dots = normal_dots
          end

          attr_accessor :type, :number, :bracket, :show_number, :show_type
          attr_accessor :actual_number, :actual_type, :actual_dots
          attr_accessor :normal_number, :normal_type, :normal_dots

          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<tuplet type=\"#{@type}\" " \
          "#{decode_bool_or_string_attribute(@number, 'number')} " \
          "#{decode_bool_or_string_attribute(@bracket, 'bracket', 'yes', 'no')} " \
          "#{decode_bool_or_string_attribute(@show_number, 'show-number')} " \
          "#{decode_bool_or_string_attribute(@show_type, 'show-type')} " \
          ">"

            if @actual_number || @actual_type || @actual_dots
              io.puts "#{tabs}\t<tuplet-actual>"

              io.puts "#{tabs}\t\t<tuplet-number>#{@actual_number}</tuplet-number>" if @actual_number
              io.puts "#{tabs}\t\t<tuplet-type>#{@actual_type}</tuplet-type>" if @actual_type

              @actual_dots&.times do
                io.puts "#{tabs}\t\t<tuplet-dot />"
              end

              io.puts "#{tabs}\t</tuplet-actual>"
            end

            if @normal_number || @normal_type || @normal_dots
              io.puts "#{tabs}\t<tuplet-normal>"

              io.puts "#{tabs}\t\t<tuplet-number>#{@normal_number}</tuplet-number>" if @normal_number
              io.puts "#{tabs}\t\t<tuplet-type>#{@normal_type}</tuplet-type>" if @normal_type

              @normal_dots&.times do
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
  end
end