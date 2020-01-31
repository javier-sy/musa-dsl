require_relative 'measure'

require_relative 'helper'

module Musa
  module MusicXML
    class Part
      extend AttributeBuilder

      include Helper::HeaderToXML
      include Helper::ToXML

      def initialize(id, name:, abbreviation: nil, **first_measure_attributes, &block)
        @id = id
        @name = name
        @abbreviation = abbreviation

        @measures = []

        unless first_measure_attributes.empty?
          add_measure **first_measure_attributes
        end

        instance_eval &block if block_given?
      end

      attr_simple_builder :id
      attr_simple_builder :name
      attr_simple_builder :abbreviation

      attr_complex_adder_to_custom :measure, variable: :@measures do
        | divisions: nil,
          key_cancel: nil, key_fifths: nil, key_mode: nil,
          time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
          clef_sign: nil, clef_line: nil, clef_octave_change: nil |

        Measure.new(@measures.size + 1,
                    divisions: divisions,
                    key_cancel: key_cancel, key_fifths: key_fifths, key_mode: key_mode,
                    time_senza_misura: time_senza_misura, time_beats: time_beats, time_beat_type: time_beat_type,
                    clef_sign: clef_sign, clef_line: clef_line, clef_octave_change: clef_octave_change).tap { |measure| @measures << measure }
      end

      def _header_to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<score-part id=\"#{@id}\">"
        io.puts "#{tabs}\t<part-name>#{@name}</part-name>"
        io.puts "#{tabs}\t<part-abbreviation>#{@abbreviation}</part-abbreviation>" if @abbreviation
        io.puts "#{tabs}</score-part>"
      end

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<part id=\"#{@id}\">"
        @measures.each do |measure|
          measure.to_xml(io, indent: indent + 1)
        end
        io.puts "#{tabs}</part>"
      end
    end
  end
end