require_relative '../../core-ext/with'

require_relative 'measure'

require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Individual part (instrument/voice) in a score.
        #
        # Part represents a single instrument or voice in the score, containing
        # a sequence of measures with musical content. Each part has a unique
        # identifier, full name, and optional abbreviation.
        #
        # ## Structure
        #
        # A part contains:
        # - **Header**: Declared in `<part-list>` with `<score-part>`
        # - **Content**: Sequence of `<measure>` elements with notes, dynamics, etc.
        #
        # ## Usage
        #
        # Parts are typically created via {Musa::MusicXML::Builder::ScorePartwise#part} or {Musa::MusicXML::Builder::ScorePartwise#add_part}.
        # Measures are added sequentially, automatically numbered starting from 1.
        #
        # @example Creating a part with measures
        #   part = Part.new(:p1, name: "Violin I", abbreviation: "Vln. I") do
        #     measure do
        #       attributes do
        #         divisions 4
        #         key fifths: 1  # G major
        #         time beats: 4, beat_type: 4
        #         clef sign: 'G', line: 2
        #       end
        #       pitch 'D', octave: 5, duration: 4, type: 'quarter'
        #     end
        #
        #     measure do
        #       pitch 'E', octave: 5, duration: 4, type: 'quarter'
        #       pitch 'F', octave: 5, duration: 4, type: 'quarter', alter: 1
        #     end
        #   end
        #
        # @see Measure Measure implementation
        # @see ScorePartwise#part Main way to create parts
        class Part
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper::HeaderToXML
          include Helper::ToXML

          # Creates a new part.
          #
          # @param id [Symbol, String] unique part identifier (referenced in `<part>` elements)
          # @param name [String] full part name (e.g., "Violin I", "Piano")
          # @param abbreviation [String, nil] abbreviated name for subsequent systems
          # @param first_measure_attributes [Hash] optional attributes for auto-created first measure
          # @yield Optional DSL block for adding measures
          #
          # @example With abbreviation
          #   Part.new(:p1, name: "Violoncello", abbreviation: "Vc.")
          #
          # @example With first measure attributes
          #   Part.new(:p1,
          #     name: "Flute",
          #     divisions: 4,
          #     key_fifths: 0,
          #     time_beats: 3, time_beat_type: 4
          #   )
          #
          # @example With DSL block
          #   Part.new(:p1, name: "Clarinet") do
          #     measure do
          #       # measure content
          #     end
          #   end
          def initialize(id, name:, abbreviation: nil, **first_measure_attributes, &block)
            @id = id
            @name = name
            @abbreviation = abbreviation

            @measures = []

            unless first_measure_attributes.empty?
              add_measure **first_measure_attributes
            end

            with &block if block_given?
          end

          # Part ID builder/setter.
          #
          # @overload id(value)
          #   Sets part ID via DSL
          #   @param value [Symbol, String] part identifier
          # @overload id=(value)
          #   Sets part ID via assignment
          #   @param value [Symbol, String] part identifier
          attr_simple_builder :id

          # Part name builder/setter.
          #
          # @overload name(value)
          #   Sets part name via DSL
          #   @param value [String] part name
          # @overload name=(value)
          #   Sets part name via assignment
          #   @param value [String] part name
          attr_simple_builder :name

          # Part abbreviation builder/setter.
          #
          # @overload abbreviation(value)
          #   Sets abbreviation via DSL
          #   @param value [String] abbreviated name
          # @overload abbreviation=(value)
          #   Sets abbreviation via assignment
          #   @param value [String] abbreviated name
          attr_simple_builder :abbreviation

          # Adds a measure to the part.
          #
          # Measures are automatically numbered sequentially starting from 1.
          # The first measure typically contains attributes (key, time, clef, divisions).
          #
          # @option divisions [Integer, nil] divisions per quarter note (timing resolution)
          # @option key_cancel [Integer, nil] key cancellation
          # @option key_fifths [Integer, nil] key signature (circle of fifths: -7 to +7)
          # @option key_mode [String, nil] mode (major/minor)
          # @option time_senza_misura [Boolean, nil] unmeasured time
          # @option time_beats [Integer, nil] time signature numerator
          # @option time_beat_type [Integer, nil] time signature denominator
          # @option clef_sign [String, nil] clef sign (G/F/C)
          # @option clef_line [Integer, nil] clef line number
          # @option clef_octave_change [Integer, nil] octave transposition
          # @yield Optional DSL block for measure content
          # @return [Measure] the created measure
          #
          # @example First measure with attributes
          #   part.add_measure(
          #     divisions: 4,
          #     key_fifths: 2,  # D major
          #     time_beats: 4, time_beat_type: 4,
          #     clef_sign: 'G', clef_line: 2
          #   )
          #
          # @example Measure with DSL block
          #   part.measure do
          #     pitch 'C', octave: 4, duration: 4, type: 'quarter'
          #     rest duration: 4, type: 'quarter'
          #   end
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

          # Generates the part declaration for the part-list section.
          #
          # Creates a `<score-part>` element with part name and optional abbreviation.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _header_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<score-part id=\"#{@id}\">"
            io.puts "#{tabs}\t<part-name>#{@name}</part-name>"
            io.puts "#{tabs}\t<part-abbreviation>#{@abbreviation}</part-abbreviation>" if @abbreviation
            io.puts "#{tabs}</score-part>"
          end

          # Generates the part content with all measures.
          #
          # Creates a `<part>` element containing all measures in sequence.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
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
  end
end