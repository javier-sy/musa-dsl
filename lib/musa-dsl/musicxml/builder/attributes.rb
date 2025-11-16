require_relative '../../core-ext/with'

require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Key signature specification.
        #
        # Key represents a key signature in terms of the circle of fifths and mode.
        # For multi-staff parts (like piano), the number attribute specifies which
        # staff the key signature applies to.
        #
        # ## Circle of Fifths
        #
        # The `fifths` attribute uses the circle of fifths representation:
        #
        # - **Negative** values: flats (C♭ major = -7, F major = -1)
        # - **Zero**: C major / A minor
        # - **Positive** values: sharps (G major = +1, C♯ major = +7)
        #
        # Common keys:
        #
        # - -7: C♭, -6: G♭, -5: D♭, -4: A♭, -3: E♭, -2: B♭, -1: F
        # - 0: C (major) / A (minor)
        # - +1: G, +2: D, +3: A, +4: E, +5: B, +6: F♯, +7: C♯
        #
        # @example C major
        #   Key.new(fifths: 0)
        #
        # @example D major (2 sharps)
        #   Key.new(fifths: 2, mode: 'major')
        #
        # @example B♭ minor (5 flats)
        #   Key.new(fifths: -5, mode: 'minor')
        #
        # @example Piano - different keys per staff
        #   Key.new(1, fifths: 0)  # Treble clef: C major
        #   Key.new(2, fifths: 0)  # Bass clef: C major
        class Key
          include Helper::ToXML

          # Creates a key signature.
          #
          # @param number [Integer, nil] staff number (for multi-staff parts)
          # @param cancel [Integer, nil] number of accidentals to cancel from previous key
          # @param fifths [Integer] circle of fifths position (-7 to +7)
          # @param mode [String, nil] 'major' or 'minor'
          #
          # @example G major
          #   Key.new(fifths: 1, mode: 'major')
          #
          # @example E minor
          #   Key.new(fifths: 1, mode: 'minor')
          def initialize(number = nil, cancel: nil, fifths:, mode: nil)
            @number = number

            @cancel = cancel
            @fifths = fifths
            @mode = mode
          end

          # Staff number (for multi-staff instruments).
          # @return [Integer, nil]
          attr_reader :number

          # Number of accidentals to cancel.
          # @return [Integer, nil]
          attr_accessor :cancel

          # Circle of fifths position (-7 to +7).
          # @return [Integer]
          attr_accessor :fifths

          # Mode ('major' or 'minor').
          # @return [String, nil]
          attr_accessor :mode

          # Generates the key signature XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io ||= StringIO.new
            indent ||= 0

            tabs = "\t" * indent

            io.puts "#{tabs}<key#{" number=\"#{@number.to_i}\"" if @number}>"

            io.puts "#{tabs}\t<cancel>#{@cancel}</cancel>" if @cancel
            io.puts "#{tabs}\t<fifths>#{@fifths.to_i}</fifths>"
            io.puts "#{tabs}\t<mode>#{@mode}</mode>" if @mode

            io.puts "#{tabs}</key>"

            io
          end
        end

        # Time signature specification.
        #
        # Time represents time signatures in MusicXML. It supports simple meters
        # (4/4, 3/4), compound meters (6/8), complex meters (5/4), and compound
        # time signatures with multiple beat groups. Also supports unmeasured time
        # (senza misura) for cadenzas and free-form sections.
        #
        # For multi-staff parts (like piano), the number attribute specifies which
        # staff the time signature applies to.
        #
        # ## Simple Time Signatures
        #
        # Most common meters use a single beats/beat_type pair:
        #
        # - 4/4 (common time): beats=4, beat_type=4
        # - 3/4 (waltz): beats=3, beat_type=4
        # - 6/8 (compound): beats=6, beat_type=8
        # - 2/2 (cut time): beats=2, beat_type=2
        #
        # ## Compound Time Signatures
        #
        # Some meters combine multiple beat groups (e.g., 3+2+3/8):
        #
        #     Time.new do |t|
        #       t.add_beats beats: 3, beat_type: 8
        #       t.add_beats beats: 2, beat_type: 8
        #       t.add_beats beats: 3, beat_type: 8
        #     end
        #
        # ## Senza Misura (Unmeasured Time)
        #
        # For cadenzas and free-form sections without strict meter:
        #
        #     Time.new(senza_misura: '')
        #
        # @example Common time (4/4)
        #   Time.new(beats: 4, beat_type: 4)
        #
        # @example Waltz (3/4)
        #   Time.new(beats: 3, beat_type: 4)
        #
        # @example Compound meter (6/8)
        #   Time.new(beats: 6, beat_type: 8)
        #
        # @example Complex meter (5/4)
        #   Time.new(beats: 5, beat_type: 4)
        #
        # @example Compound signature (3+2+3/8)
        #   time = Time.new
        #   time.add_beats(beats: 3, beat_type: 8)
        #   time.add_beats(beats: 2, beat_type: 8)
        #   time.add_beats(beats: 3, beat_type: 8)
        #
        # @example Piano - different time per staff
        #   Time.new(1, beats: 4, beat_type: 4)  # Treble: 4/4
        #   Time.new(2, beats: 3, beat_type: 4)  # Bass: 3/4
        #
        # @example Cadenza (unmeasured)
        #   Time.new(senza_misura: '')
        class Time
          include Helper::ToXML

          # Creates a time signature.
          #
          # @param number [Integer, nil] staff number (for multi-staff parts)
          # @param senza_misura [String, nil] unmeasured time indicator (typically empty string)
          # @param beats [Integer, nil] time signature numerator (beats per measure)
          # @param beat_type [Integer, nil] time signature denominator (note value per beat)
          #
          # @example 4/4 time
          #   Time.new(beats: 4, beat_type: 4)
          #
          # @example 6/8 time
          #   Time.new(beats: 6, beat_type: 8)
          #
          # @example Unmeasured time
          #   Time.new(senza_misura: '')
          def initialize(number = nil, senza_misura: nil, beats: nil, beat_type: nil)
            @number = number

            @senza_misura = senza_misura unless beats && beat_type
            @beats = []

            add_beats beats: beats, beat_type: beat_type if beats && beat_type
          end

          # Staff number (for multi-staff instruments).
          # @return [Integer, nil]
          attr_reader :number

          # Senza misura indicator for unmeasured time.
          # @return [String, nil]
          attr_accessor :senza_misura

          # Array of beat groups for compound time signatures.
          # @return [Array<Hash>]
          attr_reader :beats

          # Adds a beat group to the time signature.
          #
          # Used for compound time signatures that combine multiple beat groups
          # (e.g., 3+2+3/8 or 2+2+3/4).
          #
          # @param beats [Integer] numerator for this beat group
          # @param beat_type [Integer] denominator for this beat group
          # @return [void]
          #
          # @example Complex meter (3+2+3/8)
          #   time = Time.new
          #   time.add_beats(beats: 3, beat_type: 8)
          #   time.add_beats(beats: 2, beat_type: 8)
          #   time.add_beats(beats: 3, beat_type: 8)
          def add_beats(beats:, beat_type:)
            @beats << { beats: beats, beat_type: beat_type }
          end

          # Generates the time signature XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<time#{" number=\"#{@number.to_i}\"" if @number}>"

            io.puts "#{tabs}\t<senza-misura>#{@senza_misura}</senza-misura>" if @senza_misura
            @beats.each do |beats|
              io.puts "#{tabs}\t<beats>#{beats[:beats].to_i}</beats>"
              io.puts "#{tabs}\t<beat-type>#{beats[:beat_type].to_i}</beat-type>"
            end

            io.puts "#{tabs}</time>"
          end
        end

        # Clef specification.
        #
        # Clef represents musical clefs that determine the pitch range displayed
        # on a staff. MusicXML supports standard clefs (treble, bass, alto, tenor),
        # percussion clefs, and tablature clefs.
        #
        # For multi-staff parts (like piano), the number attribute specifies which
        # staff the clef applies to.
        #
        # ## Common Clefs
        #
        # Standard clefs are defined by a sign and staff line number:
        #
        # - **Treble (G clef)**: sign='G', line=2
        # - **Bass (F clef)**: sign='F', line=4
        # - **Alto (C clef)**: sign='C', line=3
        # - **Tenor (C clef)**: sign='C', line=4
        # - **Percussion**: sign='percussion'
        # - **Tablature**: sign='TAB'
        #
        # ## Clef Signs
        #
        # The sign parameter determines the clef type:
        #
        # - **G**: Treble clef family
        # - **F**: Bass clef family
        # - **C**: Alto/tenor clef family (movable C clef)
        # - **percussion**: For unpitched percussion
        # - **TAB**: For guitar/bass tablature
        #
        # ## Staff Lines
        #
        # The line parameter indicates which staff line the clef sign sits on:
        #
        # - Lines are numbered 1-5 from bottom to top
        # - Treble clef (G) typically on line 2
        # - Bass clef (F) typically on line 4
        # - Alto clef (C) on line 3, Tenor clef (C) on line 4
        #
        # ## Octave Transposition
        #
        # The octave_change parameter transposes notation by octaves:
        #
        # - **-2**: 15ma basso (two octaves down)
        # - **-1**: 8va basso (one octave down)
        # - **0**: No transposition (default)
        # - **+1**: 8va alta (one octave up)
        # - **+2**: 15ma alta (two octaves up)
        #
        # Common for tenor voice (treble clef 8va basso) and piccolo (treble 8va alta).
        #
        # @example Treble clef
        #   Clef.new(sign: 'G', line: 2)
        #
        # @example Bass clef
        #   Clef.new(sign: 'F', line: 4)
        #
        # @example Alto clef
        #   Clef.new(sign: 'C', line: 3)
        #
        # @example Tenor clef
        #   Clef.new(sign: 'C', line: 4)
        #
        # @example Tenor voice (treble 8va basso)
        #   Clef.new(sign: 'G', line: 2, octave_change: -1)
        #
        # @example Piccolo (treble 8va alta)
        #   Clef.new(sign: 'G', line: 2, octave_change: 1)
        #
        # @example Piano - different clefs per staff
        #   Clef.new(1, sign: 'G', line: 2)  # Treble clef (right hand)
        #   Clef.new(2, sign: 'F', line: 4)  # Bass clef (left hand)
        #
        # @example Percussion
        #   Clef.new(sign: 'percussion')
        #
        # @example Guitar tablature
        #   Clef.new(sign: 'TAB')
        class Clef
          include Helper::ToXML

          # Creates a clef.
          #
          # @param number [Integer, nil] staff number (for multi-staff parts)
          # @param sign [String] clef sign: 'G', 'F', 'C', 'percussion', 'TAB'
          # @param line [Integer] staff line number (1-5, bottom to top)
          # @param octave_change [Integer, nil] octave transposition (-2, -1, 0, +1, +2)
          #
          # @example Treble clef
          #   Clef.new(sign: 'G', line: 2)
          #
          # @example Bass clef
          #   Clef.new(sign: 'F', line: 4)
          #
          # @example Tenor voice (treble 8va basso)
          #   Clef.new(sign: 'G', line: 2, octave_change: -1)
          def initialize(number = nil, sign:, line:, octave_change: nil)
            @number = number
            @sign = sign
            @line = line
            @octave_change = octave_change
          end

          # Staff number (for multi-staff instruments).
          # @return [Integer, nil]
          attr_reader :number

          # Clef sign (G, F, C, percussion, TAB).
          # @return [String]
          attr_accessor :sign

          # Staff line number (1-5).
          # @return [Integer]
          attr_accessor :line

          # Octave transposition (-2 to +2).
          # @return [Integer, nil]
          attr_accessor :octave_change

          # Generates the clef XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<clef#{" number=\"#{@number.to_i}\"" if @number}>"

            io.puts "#{tabs}\t<sign>#{@sign}</sign>"
            io.puts "#{tabs}\t<line>#{@line.to_i}</line>" if @line
            io.puts "#{tabs}\t<clef-octave-change>#{@octave_change.to_i}</clef-octave-change>" if @octave_change

            io.puts "#{tabs}</clef>"
          end
        end

        # Musical attributes container.
        #
        # Attributes represents the `<attributes>` element in MusicXML, which
        # contains key signatures, time signatures, clefs, and timing divisions.
        # This element typically appears at the beginning of a measure to establish
        # or change the musical context.
        #
        # ## Timing Resolution (Divisions)
        #
        # The divisions parameter sets the timing resolution for note durations
        # in the measure. It represents how many divisions per quarter note:
        #
        # - **divisions=1**: Quarter note = 1 unit (limited precision)
        # - **divisions=2**: Eighth notes possible
        # - **divisions=4**: Sixteenth notes possible
        # - **divisions=8**: Thirty-second notes possible
        # - **divisions=24**: Common choice (supports triplets and quintuplets)
        #
        # Note durations are expressed as multiples of this division unit.
        #
        # ## Single-Staff vs Multi-Staff
        #
        # For single-staff instruments (violin, flute), one key/time/clef suffices.
        # For multi-staff instruments (piano, organ, harp), different attributes
        # can be specified per staff using the staff number parameter.
        #
        # The `<staves>` element is automatically generated based on the maximum
        # number of keys, times, or clefs defined.
        #
        # ## Usage Styles
        #
        # Two equivalent approaches:
        #
        # **Constructor parameters** (convenient for simple cases):
        #
        #     Attributes.new(
        #       divisions: 4,
        #       key_fifths: 0,
        #       time_beats: 4, time_beat_type: 4,
        #       clef_sign: 'G', clef_line: 2
        #     )
        #
        # **DSL with explicit elements** (flexible for multi-staff):
        #
        #     Attributes.new do
        #       divisions 4
        #       key fifths: 0
        #       time beats: 4, beat_type: 4
        #       clef sign: 'G', line: 2
        #     end
        #
        # @example Simple single-staff attributes
        #   Attributes.new(
        #     divisions: 4,
        #     key_fifths: 1,        # G major
        #     time_beats: 4, time_beat_type: 4,
        #     clef_sign: 'G', clef_line: 2
        #   )
        #
        # @example Piano with different keys per staff
        #   Attributes.new do
        #     divisions 4
        #     key 1, fifths: 0      # Treble: C major
        #     key 2, fifths: -1     # Bass: F major
        #     time beats: 3, beat_type: 4
        #     clef 1, sign: 'G', line: 2
        #     clef 2, sign: 'F', line: 4
        #   end
        #
        # @example Change key signature mid-score
        #   Attributes.new do
        #     key cancel: 2, fifths: -1  # From D major (2♯) to F major (1♭)
        #   end
        #
        # @example High timing resolution for complex rhythms
        #   Attributes.new(divisions: 24)  # Supports triplets, quintuplets
        #
        # @see Key Key signature class
        # @see Time Time signature class
        # @see Clef Clef class
        class Attributes
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper::ToXML

          # Creates a musical attributes container.
          #
          # @param divisions [Integer, nil] timing resolution (divisions per quarter note)
          # @param key_cancel [Integer, nil] accidentals to cancel from previous key
          # @param key_fifths [Integer, nil] key signature (circle of fifths: -7 to +7)
          # @param key_mode [String, nil] mode ('major' or 'minor')
          # @param time_senza_misura [Boolean, nil] unmeasured time
          # @param time_beats [Integer, nil] time signature numerator
          # @param time_beat_type [Integer, nil] time signature denominator
          # @param clef_sign [String, nil] clef sign ('G', 'F', 'C', 'percussion', 'TAB')
          # @param clef_line [Integer, nil] clef staff line (1-5)
          # @param clef_octave_change [Integer, nil] clef octave transposition
          # @yield Optional DSL block for adding elements explicitly
          #
          # @example Constructor parameters approach
          #   Attributes.new(
          #     divisions: 4,
          #     key_fifths: 2,  # D major
          #     time_beats: 6, time_beat_type: 8,
          #     clef_sign: 'G', clef_line: 2
          #   )
          #
          # @example DSL block approach
          #   Attributes.new do
          #     divisions 4
          #     key fifths: -3, mode: 'minor'  # C minor
          #     time beats: 4, beat_type: 4
          #     clef sign: 'F', line: 4
          #   end
          #
          # @example Multi-staff piano
          #   Attributes.new do
          #     divisions 8
          #     key 1, fifths: 0
          #     key 2, fifths: 0
          #     time beats: 3, beat_type: 4
          #     clef 1, sign: 'G', line: 2
          #     clef 2, sign: 'F', line: 4
          #   end
          def initialize(divisions: nil,
                         key_cancel: nil, key_fifths: nil, key_mode: nil,
                         time_senza_misura: nil, time_beats: nil, time_beat_type: nil,
                         clef_sign: nil, clef_line: nil, clef_octave_change: nil,
                         &block)

            @divisions = divisions

            @keys = []
            @times = []
            @clefs = []

            add_key cancel: key_cancel, fifths: key_fifths, mode: key_mode if key_fifths
            add_time senza_misura: time_senza_misura, beats: time_beats, beat_type: time_beat_type if time_senza_misura || (time_beats && time_beat_type)
            add_clef sign: clef_sign, line: clef_line, octave_change: clef_octave_change if clef_sign

            with &block if block_given?
          end

          # Timing divisions builder/setter.
          #
          # Sets or updates the divisions per quarter note. Higher values provide
          # finer timing resolution for complex rhythms.
          #
          # @overload divisions(value)
          #   Sets divisions via DSL
          #   @param value [Integer] divisions per quarter note
          # @overload divisions=(value)
          #   Sets divisions via assignment
          #   @param value [Integer] divisions per quarter note
          #
          # @example
          #   attributes.divisions 24  # High resolution for triplets
          attr_simple_builder :divisions

          # Adds a key signature.
          #
          # Multiple keys can be added for multi-staff parts where each staff
          # has a different key signature.
          #
          # @param number [Integer, nil] staff number
          # @param cancel [Integer, nil] accidentals to cancel
          # @param fifths [Integer] circle of fifths position (-7 to +7)
          # @param mode [String, nil] 'major' or 'minor'
          # @yield Optional DSL block for configuring the key
          # @return [Key] the created key signature
          #
          # @example Single key
          #   attributes.add_key(fifths: 2)  # D major
          #
          # @example Multi-staff with different keys
          #   attributes.add_key(1, fifths: 0)   # Treble: C major
          #   attributes.add_key(2, fifths: -1)  # Bass: F major
          attr_complex_adder_to_array :key, Key

          # Adds a time signature.
          #
          # Multiple time signatures can be added for multi-staff parts where
          # each staff has a different meter (polyrhythm).
          #
          # @param number [Integer, nil] staff number
          # @param senza_misura [Boolean, nil] unmeasured time
          # @param beats [Integer, nil] time signature numerator
          # @param beat_type [Integer, nil] time signature denominator
          # @yield Optional DSL block for configuring the time signature
          # @return [Time] the created time signature
          #
          # @example Single time signature
          #   attributes.add_time(beats: 4, beat_type: 4)
          #
          # @example Polyrhythm (different meters per staff)
          #   attributes.add_time(1, beats: 3, beat_type: 4)  # Treble: 3/4
          #   attributes.add_time(2, beats: 6, beat_type: 8)  # Bass: 6/8
          attr_complex_adder_to_array :time, Time

          # Adds a clef.
          #
          # Multiple clefs are needed for multi-staff parts (piano, organ, harp).
          #
          # @param number [Integer, nil] staff number
          # @param sign [String] clef sign ('G', 'F', 'C', 'percussion', 'TAB')
          # @param line [Integer] staff line (1-5)
          # @param octave_change [Integer, nil] octave transposition
          # @yield Optional DSL block for configuring the clef
          # @return [Clef] the created clef
          #
          # @example Single clef
          #   attributes.add_clef(sign: 'G', line: 2)
          #
          # @example Piano (two staves)
          #   attributes.add_clef(1, sign: 'G', line: 2)  # Treble
          #   attributes.add_clef(2, sign: 'F', line: 4)  # Bass
          attr_complex_adder_to_array :clef, Clef

          # Generates the attributes XML element.
          #
          # Automatically determines the number of staves based on the maximum
          # count of keys, times, or clefs. Outputs divisions, keys, times,
          # staves count (if > 1), and clefs.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<attributes>"

            io.puts "#{tabs}\t<divisions>#{@divisions.to_i}</divisions>" if @divisions

            @keys.each do |key|
              key.to_xml(io, indent: indent + 1)
            end

            @times.each do |time|
              time.to_xml(io, indent: indent + 1)
            end

            staves = [@keys.size, @times.size, @clefs.size].max
            io.puts "#{tabs}\t<staves>#{staves}</staves>" if staves > 1

            @clefs.each do |clef|
              clef.to_xml(io, indent: indent + 1)
            end

            io.puts "#{tabs}</attributes>"
          end
        end
      end
    end
  end
end