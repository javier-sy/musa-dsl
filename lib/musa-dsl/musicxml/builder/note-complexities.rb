require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Tuplet time modification (ratio).
        #
        # TimeModification defines the rhythmic ratio for tuplets, indicating how
        # many notes of one type fit in the time normally occupied by notes of
        # another type. This modifies the playback duration without changing the
        # visual note type.
        #
        # ## Tuplet Ratios
        #
        # Tuplets are expressed as **actual_notes : normal_notes**:
        #
        # ### Common Tuplets
        # - **Triplet** (3:2): 3 notes in the time of 2
        #   - Quarter note triplet: 3 quarters in time of 2 quarters (half note)
        #   - Eighth note triplet: 3 eighths in time of 2 eighths (quarter note)
        #
        # - **Quintuplet** (5:4): 5 notes in the time of 4
        #
        # - **Sextuplet** (6:4): 6 notes in the time of 4
        #
        # - **Septuplet** (7:4 or 7:8): 7 notes in time of 4 or 8
        #
        # - **Duplet** (2:3): 2 notes in the time of 3 (in compound meter)
        #
        # ## Components
        #
        # - **actual_notes**: Number of notes actually played
        # - **normal_notes**: Number of notes normally played in that duration
        # - **normal_type**: Note type for normal notes (optional)
        # - **normal_dots**: Augmentation dots on normal notes (optional)
        #
        # ## Relationship with Tuplet
        #
        # TimeModification affects playback timing, while {Tuplet} controls
        # visual display (bracket, number). Both are typically used together.
        #
        # @example Triplet (3:2)
        #   TimeModification.new(actual_notes: 3, normal_notes: 2)
        #
        # @example Quintuplet (5:4)
        #   TimeModification.new(actual_notes: 5, normal_notes: 4)
        #
        # @example Triplet with explicit normal type
        #   TimeModification.new(actual_notes: 3, normal_notes: 2,
        #                        normal_type: 'eighth')
        #
        # @example Duplet in compound meter (2:3)
        #   TimeModification.new(actual_notes: 2, normal_notes: 3)
        #
        # @see Tuplet Visual tuplet bracket notation
        # @see Note Note class using time modifications
        class TimeModification
          include Helper
          include ToXML

          # Creates a time modification.
          #
          # @param actual_notes [Integer] number of notes in the tuplet group
          # @param normal_notes [Integer] number of normal notes in same duration
          # @param normal_type [String, nil] note type of normal notes ('quarter', 'eighth', etc.)
          # @param normal_dots [Integer, nil] augmentation dots on normal notes
          #
          # @example Quarter note triplet (3 in time of 2)
          #   TimeModification.new(actual_notes: 3, normal_notes: 2)
          #
          # @example Quintuplet with explicit normal type
          #   TimeModification.new(actual_notes: 5, normal_notes: 4,
          #                        normal_type: 'quarter')
          def initialize(actual_notes:, # number
                         normal_notes:, # number
                         normal_type: nil, # quarter / ...
                         normal_dots: nil) # number

            @actual_notes = actual_notes
            @normal_notes = normal_notes
            @normal_type = normal_type
            @normal_dots = normal_dots
          end

          # Number of actual notes in the tuplet.
          # @return [Integer]
          attr_accessor :actual_notes

          # Number of normal notes in the same duration.
          # @return [Integer]
          attr_accessor :normal_notes

          # Note type of normal notes.
          # @return [String, nil]
          attr_accessor :normal_type

          # Augmentation dots on normal notes.
          # @return [Integer, nil]
          attr_accessor :normal_dots

          # Generates the time-modification XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<time-modification>"

            io.puts "#{tabs}\t<actual-notes>#{@actual_notes.to_i}</actual-notes>"
            io.puts "#{tabs}\t<normal-notes>#{@normal_notes.to_i}</normal-notes>"
            io.puts "#{tabs}\t<normal-type>#{@normal_type}</normal-type>" if @normal_type
            @normal_dots&.times do
              io.puts "#{tabs}\t<normal-dot />"
            end

            io.puts "#{tabs}</time-modification>"
          end
        end

        # Visual tuplet bracket and number notation.
        #
        # Tuplet controls the visual appearance of tuplet markings: brackets,
        # numbers, and note type indications. Unlike {TimeModification}, which
        # affects playback timing, Tuplet is purely visual.
        #
        # ## Components
        #
        # ### Type
        # - **start**: Begin tuplet bracket/number
        # - **stop**: End tuplet bracket/number
        #
        # Multiple tuplets can overlap using different `number` attributes.
        #
        # ### Bracket
        # - **true**: Show bracket
        # - **false/nil**: Hide bracket (use number only)
        #
        # Common practice: show brackets for beam-breaking tuplets, hide for beamed.
        #
        # ### Number Display
        # - **show_number**:
        #   - 'actual': Show only actual number (e.g., "3")
        #   - 'both': Show ratio (e.g., "3:2")
        #   - 'none': Hide number
        #
        # - **show_type**:
        #   - 'actual': Show note type for actual notes
        #   - 'both': Show note types for both
        #   - 'none': Hide note types
        #
        # ### Actual/Normal Specification
        #
        # Optional detailed specification of tuplet appearance:
        # - **actual_number/actual_type/actual_dots**: Actual notes representation
        # - **normal_number/normal_type/normal_dots**: Normal notes representation
        #
        # Typically inferred from {TimeModification} and note properties.
        #
        # ## Typical Usage
        #
        # Most tuplets only need `type` (start/stop) and optionally `bracket`:
        #
        #     Tuplet.new(type: 'start', bracket: true)   # First note of triplet
        #     Tuplet.new(type: 'stop')                   # Last note of triplet
        #
        # @example Simple triplet bracket (start)
        #   Tuplet.new(type: 'start', bracket: true)
        #
        # @example Triplet end
        #   Tuplet.new(type: 'stop')
        #
        # @example Tuplet without bracket
        #   Tuplet.new(type: 'start', bracket: false)
        #
        # @example Nested tuplets with numbers
        #   Tuplet.new(type: 'start', number: 1, bracket: true)  # Outer
        #   Tuplet.new(type: 'start', number: 2, bracket: true)  # Inner
        #   Tuplet.new(type: 'stop', number: 2)                  # End inner
        #   Tuplet.new(type: 'stop', number: 1)                  # End outer
        #
        # @example Custom display (show ratio)
        #   Tuplet.new(type: 'start', show_number: 'both')  # Shows "3:2"
        #
        # @see TimeModification Tuplet timing ratio
        # @see Note Note class with tuplet support
        class Tuplet
          include Helper
          include ToXML

          # Creates a tuplet notation.
          #
          # @param type [String] 'start' or 'stop'
          # @param number [Integer, nil] tuplet number for nesting (default 1)
          # @param bracket [Boolean, nil] show bracket
          # @param show_number [String, nil] number display: 'actual', 'both', 'none'
          # @param show_type [String, nil] note type display: 'actual', 'both', 'none'
          # @param actual_number [Integer, nil] actual number for display
          # @param actual_type [String, nil] actual note type for display
          # @param actual_dots [Integer, nil] actual dots for display
          # @param normal_number [Integer, nil] normal number for display
          # @param normal_type [String, nil] normal note type for display
          # @param normal_dots [Integer, nil] normal dots for display
          #
          # @example Start a triplet bracket
          #   Tuplet.new(type: 'start', bracket: true)
          #
          # @example End a tuplet
          #   Tuplet.new(type: 'stop')
          #
          # @example Quintuplet with ratio display
          #   Tuplet.new(type: 'start', bracket: true, show_number: 'both')
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

          # Tuplet type ('start' or 'stop').
          # @return [String]
          attr_accessor :type

          # Tuplet number for nesting.
          # @return [Integer, nil]
          attr_accessor :number

          # Show bracket.
          # @return [Boolean, nil]
          attr_accessor :bracket

          # Number display mode.
          # @return [String, nil]
          attr_accessor :show_number

          # Note type display mode.
          # @return [String, nil]
          attr_accessor :show_type

          # Actual number for display.
          # @return [Integer, nil]
          attr_accessor :actual_number

          # Actual note type for display.
          # @return [String, nil]
          attr_accessor :actual_type

          # Actual augmentation dots for display.
          # @return [Integer, nil]
          attr_accessor :actual_dots

          # Normal number for display.
          # @return [Integer, nil]
          attr_accessor :normal_number

          # Normal note type for display.
          # @return [String, nil]
          attr_accessor :normal_type

          # Normal augmentation dots for display.
          # @return [Integer, nil]
          attr_accessor :normal_dots

          # Generates the tuplet XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<tuplet type=\"#{@type}\"" \
          "#{decode_bool_or_string_attribute(@number&.to_i, 'number')}" \
          "#{decode_bool_or_string_attribute(@bracket, 'bracket', 'yes', 'no')}" \
          "#{decode_bool_or_string_attribute(@show_number, 'show-number')}" \
          "#{decode_bool_or_string_attribute(@show_type, 'show-type')}" \
          ">"

            if @actual_number || @actual_type || @actual_dots
              io.puts "#{tabs}\t<tuplet-actual>"

              io.puts "#{tabs}\t\t<tuplet-number>#{@actual_number.to_i}</tuplet-number>" if @actual_number
              io.puts "#{tabs}\t\t<tuplet-type>#{@actual_type}</tuplet-type>" if @actual_type

              @actual_dots&.times do
                io.puts "#{tabs}\t\t<tuplet-dot />"
              end

              io.puts "#{tabs}\t</tuplet-actual>"
            end

            if @normal_number || @normal_type || @normal_dots
              io.puts "#{tabs}\t<tuplet-normal>"

              io.puts "#{tabs}\t\t<tuplet-number>#{@normal_number.to_i}</tuplet-number>" if @normal_number
              io.puts "#{tabs}\t\t<tuplet-type>#{@normal_type}</tuplet-type>" if @normal_type

              @normal_dots&.times do
                io.puts "#{tabs}\t\t<tuplet-dot />"
              end

              io.puts "#{tabs}\t</tuplet-normal>"
            end

            io.puts "#{tabs}</tuplet>"
          end
        end

        # String harmonic technique.
        #
        # Harmonic represents natural and artificial harmonics for string instruments
        # (violin, cello, guitar, etc.). Harmonics produce ethereal, whistle-like tones
        # by lightly touching the string at specific node points.
        #
        # ## Harmonic Types
        #
        # ### Natural Harmonics
        # Produced by lightly touching the string at natural node points (1/2, 1/3, 1/4, etc.):
        # - **kind**: 'natural'
        # - Common on open strings
        # - Easier to execute
        #
        # ### Artificial Harmonics
        # Produced by stopping the string at one point and lightly touching at another:
        # - **kind**: 'artificial'
        # - Requires two fingers
        # - More versatile for chromaticism
        #
        # ## Pitch Specification
        #
        # Harmonics notation can indicate different pitches:
        #
        # - **base-pitch**: The stopped pitch (where finger presses firmly)
        # - **touching-pitch**: Where finger lightly touches
        # - **sounding-pitch**: The actual pitch that sounds (octave or more higher)
        #
        # Different notation conventions exist; MusicXML allows specifying which
        # pitch the written note represents.
        #
        # @example Natural harmonic
        #   Harmonic.new(kind: 'natural')
        #
        # @example Artificial harmonic
        #   Harmonic.new(kind: 'artificial')
        #
        # @example Harmonic with sounding pitch notation
        #   Harmonic.new(kind: 'natural', pitch: 'sounding-pitch')
        #
        # @example Harmonic with touching pitch notation
        #   Harmonic.new(kind: 'artificial', pitch: 'touching-pitch')
        #
        # @see Note Note class with harmonic support
        class Harmonic
          include Helper::ToXML

          # Creates a harmonic.
          #
          # @param kind [String, nil] 'natural' or 'artificial'
          # @param pitch [String, nil] which pitch the note represents:
          #   'base-pitch', 'sounding-pitch', or 'touching-pitch'
          #
          # @example Natural harmonic
          #   Harmonic.new(kind: 'natural')
          #
          # @example Artificial harmonic with sounding pitch
          #   Harmonic.new(kind: 'artificial', pitch: 'sounding-pitch')
          def initialize(kind: nil, # natural / artificial
                         pitch: nil) # base-pitch / sounding-pitch / touching-pitch

            @kind = kind
            @pitch = pitch
          end

          # Harmonic type ('natural' or 'artificial').
          # @return [String, nil]
          attr_accessor :kind

          # Which pitch the written note represents.
          # @return [String, nil]
          attr_accessor :pitch

          # Generates the harmonic XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<harmonic>"
            io.puts "#{tabs}\t<#{@kind} />" if @kind
            io.puts "#{tabs}\t<#{@pitch} />" if @pitch
            io.puts "#{tabs}</harmonic>"
          end
        end

        # Notehead style and properties (not yet implemented).
        #
        # Placeholder for notehead customization (shape, color, filled/hollow, etc.).
        #
        # @api private
        class Notehead
          include Helper::NotImplemented
        end

        # Directional arrow notation (not yet implemented).
        #
        # Placeholder for arrow technical markings.
        #
        # @api private
        class Arrow
          include Helper::NotImplemented
        end

        # String bend notation (not yet implemented).
        #
        # Placeholder for guitar/bass string bending.
        #
        # @api private
        class Bend
          include Helper::NotImplemented
        end

        # Fingering indication (not yet implemented).
        #
        # Placeholder for finger numbers and substitution.
        #
        # @api private
        class Fingering
          include Helper::NotImplemented
        end

        # Woodwind fingering hole (not yet implemented).
        #
        # Placeholder for woodwind fingering charts.
        #
        # @api private
        class Hole
          include Helper::NotImplemented
        end

      end
    end
  end
end