require_relative '../../core-ext/with'

require_relative 'attributes'
require_relative 'pitched-note'
require_relative 'rest'
require_relative 'unpitched-note'
require_relative 'backup-forward'
require_relative 'direction'

require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Measure container for musical content.
        #
        # Measure represents a single measure (bar) of music, containing musical elements
        # in chronological order: attributes, notes, rests, backup/forward commands, and
        # directions (dynamics, tempo markings, etc.).
        #
        # ## Element Order
        #
        # Elements within a measure follow MusicXML's sequential model:
        # 1. **Attributes** (key, time, clef, divisions) - typically in first measure
        # 2. **Directions** (tempo, dynamics) - before or between notes
        # 3. **Notes/Rests** - musical content
        # 4. **Backup/Forward** - timeline navigation for multiple voices/staves
        #
        # ## Multiple Voices and Staves
        #
        # For piano (grand staff) or polyphonic notation, use backup to rewind the timeline:
        #
        #     measure do
        #       # Right hand (treble clef)
        #       pitch 'C', octave: 5, duration: 4, type: 'quarter', staff: 1
        #       pitch 'D', octave: 5, duration: 4, type: 'quarter', staff: 1
        #
        #       backup 8  # Rewind to start of measure
        #
        #       # Left hand (bass clef)
        #       pitch 'C', octave: 3, duration: 8, type: 'half', staff: 2
        #     end
        #
        # ## Divisions
        #
        # The `divisions` attribute sets timing resolution (divisions per quarter note).
        # Higher values allow finer rhythmic subdivisions:
        # - **divisions: 1** → quarter, half, whole only
        # - **divisions: 2** → adds eighths
        # - **divisions: 4** → adds sixteenths
        # - **divisions: 8** → adds thirty-seconds
        # - **divisions: 16** → allows complex tuplets
        #
        # Duration is calculated as: `duration = (note_type_value * divisions) / beat_type`
        #
        # @example Simple measure with quarter notes
        #   measure = Measure.new(1, divisions: 2) do
        #     attributes do
        #       key fifths: 0  # C major
        #       time beats: 4, beat_type: 4
        #       clef sign: 'G', line: 2
        #     end
        #
        #     pitch 'C', octave: 4, duration: 2, type: 'quarter'
        #     pitch 'D', octave: 4, duration: 2, type: 'quarter'
        #     pitch 'E', octave: 4, duration: 2, type: 'quarter'
        #     pitch 'F', octave: 4, duration: 2, type: 'quarter'
        #   end
        #
        # @example Measure with dynamics and tempo
        #   measure do
        #     metronome beat_unit: 'quarter', per_minute: 120
        #
        #     direction do
        #       dynamics 'p'
        #       wedge 'crescendo'
        #     end
        #
        #     pitch 'C', octave: 4, duration: 4, type: 'quarter'
        #     pitch 'D', octave: 4, duration: 4, type: 'quarter'
        #
        #     direction do
        #       wedge 'stop'
        #       dynamics 'f'
        #     end
        #   end
        #
        # @see Attributes Musical attributes (key, time, clef)
        # @see PitchedNote Pitched note
        # @see Rest Rest
        # @see Direction Tempo, dynamics, expressions
        class Measure
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper::ToXML

          # Creates a new measure.
          #
          # @param number [Integer] measure number (automatically assigned by Part)
          # @param divisions [Integer, nil] divisions per quarter note (timing resolution)
          # @param key_cancel [Integer, nil] key cancellation
          # @param key_fifths [Integer, nil] key signature (-7 to +7, circle of fifths)
          # @param key_mode [String, nil] mode ('major' or 'minor')
          # @param time_senza_misura [Boolean, nil] unmeasured time
          # @param time_beats [Integer, nil] time signature numerator
          # @param time_beat_type [Integer, nil] time signature denominator
          # @param clef_sign [String, nil] clef sign ('G', 'F', 'C')
          # @param clef_line [Integer, nil] clef line number
          # @param clef_octave_change [Integer, nil] octave transposition
          # @yield Optional DSL block for adding measure content
          #
          # @example First measure with all attributes
          #   Measure.new(1,
          #     divisions: 4,
          #     key_fifths: 2,  # D major
          #     time_beats: 3, time_beat_type: 4,
          #     clef_sign: 'G', clef_line: 2
          #   )
          #
          # @example Measure with DSL block
          #   Measure.new(2) do
          #     pitch 'E', octave: 4, duration: 4, type: 'quarter'
          #     rest duration: 4, type: 'quarter'
          #   end
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

          # Measure number.
          # @return [Integer]
          attr_accessor :number

          # Ordered list of elements in this measure.
          # @return [Array<Object>] notes, rests, attributes, directions, etc.
          attr_reader :elements

          # Adds musical attributes to the measure.
          #
          # Attributes define key signature, time signature, clef, and timing divisions.
          # Typically appear at the start of the first measure or when they change.
          #
          # @option divisions [Integer, nil] divisions per quarter note
          # @option key_cancel [Integer, nil] key to cancel
          # @option key_fifths [Integer, nil] key signature (-7 to +7)
          # @option key_mode [String, nil] 'major' or 'minor'
          # @option time_senza_misura [Boolean, nil] unmeasured time
          # @option time_beats [Integer, nil] time signature numerator
          # @option time_beat_type [Integer, nil] time signature denominator
          # @option clef_sign [String, nil] 'G', 'F', or 'C'
          # @option clef_line [Integer, nil] clef line
          # @option clef_octave_change [Integer, nil] octave transposition
          # @yield Optional DSL block for adding keys, times, clefs
          # @return [Attributes] the created attributes object
          #
          # @example Via DSL block
          #   measure.attributes do
          #     divisions 4
          #     key fifths: 1  # G major
          #     time beats: 3, beat_type: 4
          #     clef sign: 'G', line: 2
          #   end
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

          # Adds a pitched note.
          #
          # @return [PitchedNote] the created note
          #
          # @example
          #   measure.pitch 'C', octave: 4, duration: 4, type: 'quarter'
          #   measure.pitch step: 'E', octave: 4, duration: 2, type: 'eighth', dots: 1
          #
          # @see PitchedNote For full parameter list
          attr_complex_adder_to_custom :pitch do | *parameters, **key_parameters |
            PitchedNote.new(*parameters, **key_parameters).tap { |note| @elements << note }
          end

          # Adds a rest.
          #
          # @return [Rest] the created rest
          #
          # @example
          #   measure.rest duration: 4, type: 'quarter'
          #   measure.rest duration: 8, type: 'half', measure: true  # whole measure rest
          #
          # @see Rest For full parameter list
          attr_complex_adder_to_custom :rest do | *parameters, **key_parameters |
            Rest.new(*parameters, **key_parameters).tap { |rest| @elements << rest }
          end

          # Adds an unpitched note (for percussion).
          #
          # @return [UnpitchedNote] the created unpitched note
          #
          # @see UnpitchedNote For details
          attr_complex_adder_to_custom :unpitched do | *parameters, **key_parameters |
            UnpitchedNote.new(*parameters, **key_parameters).tap { |unpitched| @elements << unpitched }
          end

          # Rewinds the musical timeline.
          #
          # Backup moves the current time position backward by the specified duration,
          # allowing multiple voices or staves to be layered in the same time span.
          #
          # @return [Backup] the created backup element
          #
          # @example Piano grand staff
          #   measure do
          #     pitch 'C', octave: 5, duration: 8, type: 'half', staff: 1
          #     backup 8  # Rewind to start
          #     pitch 'C', octave: 3, duration: 8, type: 'half', staff: 2
          #   end
          #
          # @see Forward For moving forward
          attr_complex_adder_to_custom :backup do |duration|
            Backup.new(duration).tap { |backup| @elements << backup }
          end

          # Advances the musical timeline.
          #
          # Forward moves the current time position forward without sounding,
          # creating rests or gaps in the timeline.
          #
          # @return [Forward] the created forward element
          #
          # @example Skip to beat 3
          #   measure do
          #     pitch 'C', octave: 4, duration: 2, type: 'quarter'
          #     forward 4  # Skip 2 beats
          #     pitch 'D', octave: 4, duration: 2, type: 'quarter'
          #   end
          attr_complex_adder_to_custom :forward do |duration, voice: nil, staff: nil|
            Forward.new(duration, voice: voice, staff: staff).tap { |forward| @elements << forward }
          end

          # Adds a direction element (dynamics, tempo, expressions).
          #
          # Directions contain non-note musical instructions like dynamics (p, f),
          # tempo markings, wedges (crescendo/diminuendo), pedal marks, etc.
          #
          # @yield Optional DSL block for direction content
          # @return [Direction] the created direction
          #
          # @example Dynamics with crescendo
          #   measure.direction do
          #     dynamics 'p'
          #     wedge 'crescendo'
          #   end
          #
          # @see Direction For direction types
          attr_complex_adder_to_custom :direction do |*parameters, **key_parameters, &block|
            Direction.new(*parameters, **key_parameters, &block).tap { |direction| @elements << direction }
          end

          # Direction shortcuts - these create a Direction automatically.
          #
          # The following methods are convenience shortcuts that create a Direction
          # element containing the specified direction type. They accept placement and
          # offset parameters that are passed to the Direction wrapper.

          # Adds a metronome (tempo) marking.
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @option beat_unit [String] note value ('quarter', 'half', etc.)
          # @option per_minute [Numeric] tempo in BPM
          # @yield Optional block
          # @return [Direction] direction containing metronome
          #
          # @example
          #   measure.metronome beat_unit: 'quarter', per_minute: 120
          attr_complex_adder_to_custom(:metronome) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { metronome *p, **kp, &b } }

          # Adds a wedge (crescendo/diminuendo).
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @option niente [Boolean, nil] niente attribute
          # @return [Direction] direction containing wedge
          #
          # @example
          #   measure.wedge 'crescendo', niente: true
          attr_complex_adder_to_custom(:wedge) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { wedge *p, **kp, &b } }

          # Adds dynamics (p, pp, f, ff, etc.).
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @return [Direction] direction containing dynamics
          #
          # @example
          #   measure.dynamics 'pp'
          #   measure.dynamics ['mf', 'sf']  # Multiple dynamics
          attr_complex_adder_to_custom(:dynamics) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { dynamics *p, **kp, &b } }

          # Adds pedal marking.
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @option line [Boolean, nil] show pedal line
          # @return [Direction] direction containing pedal
          #
          # @example
          #   measure.pedal 'start', line: true
          attr_complex_adder_to_custom(:pedal) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { pedal *p, **kp, &b } }

          # Adds bracket notation.
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @option line_end [String, nil] line end type
          # @return [Direction] direction containing bracket
          attr_complex_adder_to_custom(:bracket) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { bracket *p, **kp, &b } }

          # Adds dashed line.
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @return [Direction] direction containing dashes
          attr_complex_adder_to_custom(:dashes) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { dashes *p, **kp, &b } }

          # Adds text annotation.
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @return [Direction] direction containing words
          #
          # @example
          #   measure.words "rit.", placement: 'above'
          attr_complex_adder_to_custom(:words) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { words *p, **kp, &b } }

          # Adds octave shift (8va/8vb).
          #
          # @option placement [String, nil] 'above' or 'below'
          # @option offset [Numeric, nil] offset in divisions
          # @option size [Integer, nil] octave shift size (8 or 15)
          # @return [Direction] direction containing octave_shift
          #
          # @example
          #   measure.octave_shift 'up', size: 8
          attr_complex_adder_to_custom(:octave_shift) {
            |*p, placement: nil, offset: nil, **kp, &b|
            direction(placement: placement, offset: offset) { octave_shift *p, **kp, &b } }

          # Generates the measure XML element with all contained elements.
          #
          # Outputs elements in the order they were added, which must follow
          # MusicXML's element ordering rules (attributes, then notes/directions/backup/forward).
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<measure number=\"#{@number.to_i}\">"

            @elements.each do |element|
              element.to_xml(io, indent: indent + 1)
            end

            io.puts "#{tabs}</measure>"
          end
        end
      end
    end
  end
end