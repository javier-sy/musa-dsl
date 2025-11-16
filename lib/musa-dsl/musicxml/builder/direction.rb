require_relative '../../core-ext/with'
require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        using Musa::Extension::Arrayfy

        # Musical direction container.
        #
        # Direction represents performance instructions and expressive markings that
        # affect interpretation but aren't part of the note structure. Directions
        # include tempo, dynamics, pedaling, text instructions, and other musical
        # indications.
        #
        # ## Direction Types
        #
        # Directions can contain multiple direction-type elements:
        #
        # ### Tempo and Metronome
        # - **Metronome**: Tempo markings (♩ = 120, etc.)
        # - **Words**: Textual tempo indications ("Allegro", "Adagio")
        #
        # ### Dynamics
        # - **Dynamics**: Dynamic levels (pp, p, mp, mf, f, ff, etc.)
        # - **Wedge**: Crescendo/diminuendo hairpins
        #
        # ### Pedaling
        # - **Pedal**: Piano pedal markings (start, stop, change)
        #
        # ### Text and Symbols
        # - **Words**: General text directions
        # - **Bracket**: Analytical brackets
        # - **Dashes**: Dashed extension lines
        #
        # ### Transposition
        # - **OctaveShift**: 8va/8vb markings
        #
        # ## Placement
        #
        # Directions can be placed above or below the staff:
        # - **above**: Above staff (typical for tempo, dynamics)
        # - **below**: Below staff (typical for pedal markings)
        #
        # ## Voice and Staff
        #
        # For multi-voice or multi-staff contexts, directions can be associated with
        # specific voices or staves.
        #
        # ## Offset
        #
        # Directions can have timing offsets for precise positioning relative to notes.
        #
        # @example Tempo marking
        #   Direction.new(placement: 'above') do
        #     metronome beat_unit: 'quarter', per_minute: '120'
        #     words 'Allegro'
        #   end
        #
        # @example Dynamic marking
        #   Direction.new(placement: 'below', dynamics: 'f')
        #
        # @example Crescendo hairpin
        #   Direction.new(placement: 'below') do
        #     wedge 'crescendo'
        #   end
        #
        # @example Pedal down
        #   Direction.new(placement: 'below', pedal: 'start')
        #
        # @see Measure Container for directions
        class Direction
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper
          include ToXML

          # Creates a direction.
          #
          # @param placement [String, nil] 'above' or 'below' staff
          # @param voice [Integer, nil] voice number
          # @param staff [Integer, nil] staff number
          # @param offset [Numeric, nil] timing offset in divisions
          # @param directions [Hash] direction types as keyword arguments
          # @yield Optional DSL block for adding direction types
          #
          # @example Tempo with metronome
          #   Direction.new(placement: 'above') do
          #     metronome beat_unit: 'quarter', per_minute: '120'
          #   end
          #
          # @example Forte dynamic
          #   Direction.new(placement: 'below', dynamics: 'f')
          #
          # @example Multiple directions
          #   Direction.new(placement: 'above') do
          #     words 'Allegro con brio'
          #     metronome beat_unit: 'quarter', per_minute: '132'
          #   end
          def initialize(placement: nil, # above / below
                         voice: nil, # number
                         staff: nil,  # number
                         offset: nil, # number
                         **directions,
                         &block)

            @placement = placement

            @types = []
            @voice = voice
            @staff = staff
            @offset = offset

            directions.each_pair do |direction, value|
              send direction, value
            end

            with &block if block_given?
          end

          # Voice builder/setter.
          # @return [Integer, nil]
          attr_simple_builder :voice

          # Staff builder/setter.
          # @return [Integer, nil]
          attr_simple_builder :staff

          # Offset builder/setter.
          # @return [Numeric, nil]
          attr_simple_builder :offset

          # Placement builder/setter ('above' or 'below').
          # @return [String, nil]
          attr_simple_builder :placement

          # Adds a metronome marking.
          # @see Metronome
          attr_complex_adder_to_custom(:metronome) { |*p, **kp, &b| Metronome.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds a wedge (crescendo/diminuendo hairpin).
          # @see Wedge
          attr_complex_adder_to_custom(:wedge) { |*p, **kp, &b| Wedge.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds dynamics marking.
          # @see Dynamics
          attr_complex_adder_to_custom(:dynamics) { |*p, **kp, &b| Dynamics.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds pedal marking.
          # @see Pedal
          attr_complex_adder_to_custom(:pedal) { |*p, **kp, &b| Pedal.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds bracket.
          # @see Bracket
          attr_complex_adder_to_custom(:bracket) { |*p, **kp, &b| Bracket.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds dashes.
          # @see Dashes
          attr_complex_adder_to_custom(:dashes) { |*p, **kp, &b| Dashes.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds text words.
          # @see Words
          attr_complex_adder_to_custom(:words) { |*p, **kp, &b| Words.new(*p, **kp, &b).tap { |t| @types << t } }

          # Adds octave shift (8va/8vb).
          # @see OctaveShift
          attr_complex_adder_to_custom(:octave_shift) { |*p, **kp, &b| OctaveShift.new(*p, **kp, &b).tap { |t| @types << t } }

          # Generates the direction XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<direction#{ decode_bool_or_string_attribute(@placement, 'placement') }>"

            @types.each do |type|
              type.to_xml(io, indent: indent + 1)
            end

            io.puts "#{tabs}\t<offset sound=\"no\">#{@offset.to_f.round(2)}</offset>" if @offset
            io.puts "#{tabs}\t<voice>#{@voice.to_i}</voice>" if @voice
            io.puts "#{tabs}\t<staff>#{@staff.to_i}</staff>" if @staff

            io.puts "#{tabs}</direction>"
          end

          private

          def direction_type_to_xml(io, indent:); end
        end

        class DirectionType
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper::ToXML

          def initialize(*_rest, **_krest, &block)
            with &block if block_given?
          end

          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<direction-type>"
            _direction_type_to_xml(io, indent: indent + 1, tabs: tabs + "\t")
            io.puts "#{tabs}</direction-type>"
          end
        end

        private_constant :DirectionType

        # Metronome tempo marking direction type.
        #
        # Represents tempo markings with beat unit and metronome value (e.g., ♩ = 120).
        # Supports dotted beat units.
        #
        # @example Quarter note = 120 BPM
        #   metronome beat_unit: 'quarter', per_minute: '120'
        #
        # @example Dotted eighth = 90
        #   metronome beat_unit: 'eighth', beat_unit_dots: 1, per_minute: '90'
        class Metronome < DirectionType
          include Helper

          # TODO complete Metronome complexity!

          def initialize(beat_unit:, # quarter / eighth / ...
                         beat_unit_dots: nil, # number
                         per_minute:, #string
                         &block)

            @beat_unit = beat_unit
            @beat_unit_dots = beat_unit_dots
            @per_minute = per_minute

            super
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

        # Wedge hairpin direction type for crescendo/diminuendo.
        #
        # Represents dynamic hairpins (crescendo <, diminuendo >).
        # Supports niente (to/from nothing) hairpins.
        #
        # @example Crescendo
        #   wedge 'crescendo'
        #
        # @example Diminuendo to nothing
        #   wedge 'diminuendo', niente: true
        #
        # @example Stop wedge
        #   wedge 'stop'
        class Wedge < DirectionType
          include Helper

          def initialize(type, #  crescendo / diminuendo / stop / continue
                         niente: nil, # true
                         &block)
            @type = type
            @niente = niente

            super
          end

          attr_simple_builder :type
          attr_simple_builder :niente

          def _direction_type_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<wedge type=\"#{@type}\"#{ decode_bool_or_string_attribute(@niente, 'niente', 'yes') }/>"
          end
        end

        # Dynamic marking direction type.
        #
        # Represents dynamic levels (pp, p, mp, mf, f, ff, fff, etc.).
        # Can specify multiple dynamics for compound markings.
        #
        # @example Single dynamic
        #   dynamics 'f'
        #
        # @example Multiple dynamics (sforzando-forte)
        #   dynamics ['sf', 'f']
        class Dynamics < DirectionType
          def initialize(value, # pp / ppp / ... or array of
                         &block)
            @dynamics = value.arrayfy
            super
          end

          attr_simple_builder :dynamics

          def _direction_type_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<dynamics>"

            @dynamics.each do |dynamics|
              io.puts "#{tabs}\t<#{dynamics} />"
            end

            io.puts "#{tabs}</dynamics>"
          end
        end

        # Piano sustain pedal marking direction type.
        #
        # Represents pedal down/up markings. Supports start, stop, change,
        # and continue types with optional line display.
        #
        # @example Pedal down
        #   pedal 'start', line: true
        #
        # @example Pedal up
        #   pedal 'stop'
        #
        # @example Pedal change
        #   pedal 'change'
        class Pedal < DirectionType
          include Helper

          def initialize(type, # start / stop / change / continue
                         line: nil, # true
                         &block)

            @type = type
            @line = line

            super
          end

          attr_simple_builder :type
          attr_simple_builder :line

          def _direction_type_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<pedal type=\"#{@type}\"#{ decode_bool_or_string_attribute(@line, 'line', 'yes', 'no') }/>"
          end
        end

        # Bracket direction type for analytical markings.
        #
        # Represents brackets used for grouping or analytical notation.
        # Supports different line types and end styles.
        #
        # @example Start bracket
        #   bracket 'start', line_end: 'down', line_type: 'solid'
        #
        # @example Stop bracket
        #   bracket 'stop', line_end: 'up'
        class Bracket < DirectionType
          include Helper

          def initialize(type, # start / stop / continue
                         line_end:, # up / down / both / arrow / none
                         line_type: nil, # solid / dashed / dotted / wavy
                         &block)

            @type = type
            @line_end = line_end
            @line_type = line_type

            super
          end

          attr_simple_builder :type
          attr_simple_builder :line_type
          attr_simple_builder :line_end

          def _direction_type_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<bracket type=\"#{@type}\" line_end=\"#{@line_end}\"#{ decode_bool_or_string_attribute(@line_type, 'line_type') }/>"
          end
        end

        # Dashed line direction type.
        #
        # Represents dashed extension lines for text or other markings.
        #
        # @example Start dashed line
        #   dashes 'start'
        #
        # @example Stop dashed line
        #   dashes 'stop'
        class Dashes < DirectionType
          def initialize(type, # start / stop / continue
                         &block)

            @type = type

            super
          end

          attr_simple_builder :type

          def _direction_type_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<dashes type=\"#{@type}\" />"
          end
        end

        # Text words direction type.
        #
        # Represents textual performance instructions or expressions.
        # Can contain multiple text strings.
        #
        # @example Single text
        #   words 'Allegro'
        #
        # @example Multiple texts
        #   words ['con', 'brio']
        class Words < DirectionType
          def initialize(value, # string | Array of string
                         &block)

            @words = value.arrayfy

            super
          end

          attr_simple_builder :words

          def _direction_type_to_xml(io, indent:, tabs:)
            @words.each do |words|
              io.puts "#{tabs}<words>#{words}</words>"
            end
          end
        end

        # Octave shift direction type for 8va/8vb markings.
        #
        # Represents octave transposition markings (8va, 8vb, 15ma, 15mb).
        # Type indicates up/down/stop/continue, size indicates octaves (8 or 15).
        #
        # @example Start 8va
        #   octave_shift 'up', size: 8
        #
        # @example Start 8vb
        #   octave_shift 'down', size: 8
        #
        # @example Stop octave shift
        #   octave_shift 'stop'
        class OctaveShift < DirectionType
          include Helper

          def initialize(type, # up / down / stop / continue
                         size: nil, # number
                         &block)

            @type = type
            @size = size

            super
          end

          attr_simple_builder :type
          attr_simple_builder :size

          def _direction_type_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<octave-shift type=\"#{@type}\"#{ decode_bool_or_string_attribute(@size&.to_i, 'size') }/>"
          end
        end

        # Accordion registration direction type (not implemented).
        # @api private
        class AccordionRegistration < DirectionType
          include Helper::NotImplemented
        end

        # Coda symbol direction type (not implemented).
        # @api private
        class Coda < DirectionType
          include Helper::NotImplemented
        end

        # Damp (mute) marking direction type (not implemented).
        # @api private
        class Damp < DirectionType
          include Helper::NotImplemented
        end

        # Damp all strings marking direction type (not implemented).
        # @api private
        class DampAll < DirectionType
          include Helper::NotImplemented
        end

        # Eye glasses symbol direction type (not implemented).
        # @api private
        class EyeGlasses < DirectionType
          include Helper::NotImplemented
        end

        # Harp pedals diagram direction type (not implemented).
        # @api private
        class HarpPedals < DirectionType
          include Helper::NotImplemented
        end

        # Embedded image direction type (not implemented).
        # @api private
        class Image < DirectionType
          include Helper::NotImplemented
        end

        # Custom/other direction type (not implemented).
        # @api private
        class OtherDirection < DirectionType
          include Helper::NotImplemented
        end

        # Percussion notation direction type (not implemented).
        # @api private
        class Percussion < DirectionType
          include Helper::NotImplemented
        end

        # Principal voice marking direction type (not implemented).
        # @api private
        class PrincipalVoice < DirectionType
          include Helper::NotImplemented
        end

        # Rehearsal mark direction type (not implemented).
        # @api private
        class Rehearsal < DirectionType
          include Helper::NotImplemented
        end

        # Scordatura (altered tuning) direction type (not implemented).
        # @api private
        class Scordatura < DirectionType
          include Helper::NotImplemented
        end

        # Segno symbol direction type (not implemented).
        # @api private
        class Segno < DirectionType
          include Helper::NotImplemented
        end

        # String mute marking direction type (not implemented).
        # @api private
        class StringMute < DirectionType
          include Helper::NotImplemented
        end
      end
    end
  end
end