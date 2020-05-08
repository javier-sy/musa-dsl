require_relative '../core-ext/with'

require_relative 'attributes'
require_relative 'pitched-note'
require_relative 'rest'
require_relative 'unpitched-note'
require_relative 'backup-forward'
require_relative 'direction'

require_relative 'helper'

module Musa
  module MusicXML
    class Measure
      extend Musa::Extension::AttributeBuilder
      include Musa::Extension::With

      include Helper::ToXML

      def initialize(number, divisions: nil,
                     key_cancel: nil, key_fifths: nil, key_mode: nil,
                     time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
                     clef_sign: nil, clef_line: nil, clef_octave_change: nil,
                     &block)

        @number = number
        @elements = []

        @attributes = []

        if divisions ||
            key_cancel || key_fifths || key_mode ||
            time_senza_misura || time_beats || time_beat_type ||
            clef_sign || clef_line || clef_octave_change

          add_attributes divisions: divisions,
                         key_cancel: key_cancel, key_fifths: key_fifths, key_mode: key_mode,
                         time_senza_misura: time_senza_misura, time_beats: time_beats, time_beat_type: time_beat_type,
                         clef_sign: clef_sign, clef_line: clef_line, clef_octave_change: clef_octave_change
        end

        with &block if block_given?
      end

      attr_accessor :number
      attr_reader :elements

      attr_complex_adder_to_custom :attributes, plural: :attributes, variable: :@attributes do
        | divisions: nil,
          key_cancel: nil, key_fifths: nil, key_mode: nil,
          time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
          clef_sign: nil, clef_line: nil, clef_octave_change: nil,
          &block |

        Attributes.new(divisions: divisions,
                       key_cancel: key_cancel, key_fifths: key_fifths, key_mode: key_mode,
                       time_senza_misura: time_senza_misura, time_beats: time_beats, time_beat_type: time_beat_type,
                       clef_sign: clef_sign, clef_line: clef_line, clef_octave_change: clef_octave_change, &block) \
                  .tap do |attributes|

          @attributes << attributes
          @elements << attributes
        end
      end

      attr_complex_adder_to_custom :pitch do | *parameters, **key_parameters |
        PitchedNote.new(*parameters, **key_parameters).tap { |note| @elements << note }
      end

      attr_complex_adder_to_custom :rest do | *parameters, **key_parameters |
        Rest.new(*parameters, **key_parameters).tap { |rest| @elements << rest }
      end

      attr_complex_adder_to_custom :unpitched do | *parameters, **key_parameters |
        UnpitchedNote.new(*parameters, **key_parameters).tap { |unpitched| @elements << unpitched }
      end

      attr_complex_adder_to_custom :backup do |duration|
        Backup.new(duration).tap { |backup| @elements << backup }
      end

      attr_complex_adder_to_custom :forward do |duration, voice: nil, staff: nil|
        Forward.new(duration, voice: voice, staff: staff).tap { |forward| @elements << forward }
      end

      attr_complex_adder_to_custom :direction do |*parameters, **key_parameters, &block|
        Direction.new(*parameters, **key_parameters, &block).tap { |direction| @elements << direction }
      end

      attr_complex_adder_to_custom(:metronome) { |*p, **kp, &b| direction { metronome *p, **kp, &b } }
      attr_complex_adder_to_custom(:wedge) { |*p, **kp, &b| direction { wedge *p, **kp, &b } }
      attr_complex_adder_to_custom(:dynamics) { |*p, **kp, &b| direction { dynamics *p, **kp, &b } }
      attr_complex_adder_to_custom(:pedal) { |*p, **kp, &b| direction { pedal *p, **kp, &b } }
      attr_complex_adder_to_custom(:bracket) { |*p, **kp, &b| direction { bracket *p, **kp, &b } }
      attr_complex_adder_to_custom(:dashes) { |*p, **kp, &b| direction { dashes *p, **kp, &b } }
      attr_complex_adder_to_custom(:words) { |*p, **kp, &b| direction { words *p, **kp, &b } }
      attr_complex_adder_to_custom(:octave_shift) { |*p, **kp, &b| direction { octave_shift *p, **kp, &b } }

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<measure number=\"#{@number}\">"

        @elements.each do |element|
          element.to_xml(io, indent: indent + 1)
        end

        io.puts "#{tabs}</measure>"
      end
    end
  end
end