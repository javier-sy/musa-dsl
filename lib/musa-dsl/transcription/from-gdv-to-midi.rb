# MIDI-specific GDV transcriptors for playback output.
#
# Transcribes GDV events to MIDI playback format by expanding ornaments and
# articulations into explicit note sequences. Unlike MusicXML transcription,
# MIDI transcription generates the actual notes to be played.
#
# ## MIDI vs MusicXML Approach
#
# MIDI transcription expands ornaments for playback:
#
# - **MIDI**: Ornaments become explicit note sequences with calculated durations
# - **MusicXML**: Ornaments preserved as notation symbols
#
# ## Supported Ornaments & Articulations
#
# - **Appogiatura** (`:appogiatura`): Grace note before main note
# - **Mordent** (`.mor`): Quick alternation with adjacent note
# - **Turn** (`.turn`): Four-note figure circling main note
# - **Trill** (`.tr`): Rapid alternation with upper note
# - **Staccato** (`.st`): Shortened note duration
#
# ## Duration Factor
#
# Many ornaments use a configurable `duration_factor` (default 1/4) to determine
# ornament note durations relative to `base_duration`:
# ```ruby
# ornament_duration = base_duration * duration_factor
# ```
#
# ## Usage
#
# ```ruby
# transcriptor = Musa::Transcription::Transcriptor.new(
#   Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/8r),
#   base_duration: 1/4r,
#   tick_duration: 1/96r
# )
# result = transcriptor.transcript(gdv_event)
# ```
#
# ## Transcription Set
#
# The `transcription_set` returns transcriptors applied in order:
#
# 1. `Appogiatura` - Expand appogiatura grace notes
# 2. `Mordent` - Expand mordent ornaments
# 3. `Turn` - Expand turn ornaments
# 4. `Trill` - Expand trill ornaments
# 5. `Staccato` - Apply staccato articulation
# 6. `Base` - Process base/rest markers
#
# @example MIDI trill expansion
#   gdv = { grade: 0, duration: 1r, tr: true }
#   transcriptor = Musa::Transcriptors::FromGDV::ToMIDI::Trill.new
#   result = transcriptor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
#   # => [
#   #   { grade: 1, duration: 1/16r },  # Upper neighbor
#   #   { grade: 0, duration: 1/16r },  # Main note
#   #   { grade: 1, duration: 1/16r },  # Upper neighbor
#   #   ...
#   # ]
#
# @see Musa::Transcriptors::FromGDV::ToMusicXML
# @see Musa::MIDI
#
# @api public
require_relative 'from-gdv'

module Musa::Transcriptors
  module FromGDV
    # MIDI-specific GDV transcriptors for playback output.
    #
    # Transcribes GDV events to MIDI playback format by expanding ornaments
    # and articulations into explicit note sequences. This differs from MusicXML
    # transcription which preserves ornaments as notation symbols.
    #
    # ## Supported Features
    #
    # - **Appogiatura**: Grace notes expanded to explicit notes
    # - **Mordent** (`.mor`): Quick alternation expanded
    # - **Turn** (`.turn`): Four-note figure expanded
    # - **Trill** (`.tr`): Rapid alternation expanded
    # - **Staccato** (`.st`): Shortened note duration
    #
    # ## Usage
    #
    # Use {transcription_set} to get pre-configured transcriptor chain:
    # ```ruby
    # transcriptor = Musa::Transcription::Transcriptor.new(
    #   Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/4r),
    #   base_duration: 1/4r,
    #   tick_duration: 1/96r
    # )
    # ```
    #
    # @see ToMusicXML Notation-preserving transcription
    # @see Musa::MIDI MIDI output system
    module ToMIDI
      # Returns standard transcription set for MIDI output.
      #
      # Creates array of transcriptors for processing GDV to MIDI playback format,
      # expanding all ornaments to explicit note sequences.
      #
      # @param duration_factor [Rational] factor for ornament note durations
      #   relative to base_duration (default: 1/4)
      #
      # @return [Array<FeatureTranscriptor>] transcriptor chain
      #
      # @example Create MIDI transcription chain with default factor
      #   transcriptors = Musa::Transcriptors::FromGDV::ToMIDI.transcription_set
      #   transcriptor = Musa::Transcription::Transcriptor.new(
      #     transcriptors,
      #     base_duration: 1/4r
      #   )
      #
      # @example Custom duration factor for faster ornaments
      #   transcriptors = Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(
      #     duration_factor: 1/8r
      #   )
      #
      # @api public
      def self.transcription_set(duration_factor: nil)
        [ Appogiatura.new,
          Mordent.new(duration_factor: duration_factor),
          Turn.new,
          Trill.new(duration_factor: duration_factor),
          Staccato.new,
          Base.new ]
      end

      # Appogiatura transcriptor for MIDI playback.
      #
      # Expands appogiatura ornaments into two sequential notes for MIDI playback.
      # The grace note (appogiatura) is played first, followed by the main note
      # with reduced duration.
      #
      # ## Processing
      #
      # Given an appogiatura marking:
      # ```ruby
      # {
      #   grade: 0,
      #   duration: 1r,
      #   appogiatura: { grade: -1, duration: 1/8r }
      # }
      # ```
      #
      # Expands to two notes:
      # ```ruby
      # [
      #   { grade: -1, duration: 1/8r },      # Grace note
      #   { grade: 0, duration: 7/8r }        # Main note (reduced)
      # ]
      # ```
      #
      # The main note's duration is reduced by the appogiatura duration to maintain
      # total duration.
      #
      # @example Appogiatura expansion
      #   app = Appogiatura.new
      #   gdv = {
      #     grade: 0,
      #     duration: 1r,
      #     appogiatura: { grade: -1, duration: 1/8r }
      #   }
      #   result = app.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
      #   # => [
      #   #   { grade: -1, duration: 1/8r },
      #   #   { grade: 0, duration: 7/8r }
      #   # ]
      #
      # @api public
      # Process: appogiatura (neuma)neuma
      class Appogiatura < Musa::Transcription::FeatureTranscriptor
        # Transcribes appogiatura to two-note sequence.
        #
        # @param gdv [Hash] GDV event possibly containing `:appogiatura`
        # @param base_duration [Rational] base duration unit
        # @param tick_duration [Rational] minimum tick duration
        #
        # @return [Array<Hash>, Hash] array with grace note and main note, or
        #   unchanged event if no appogiatura
        #
        # @api public
        def transcript(gdv, base_duration:, tick_duration:)
          gdv_appogiatura = gdv.delete :appogiatura

          if gdv_appogiatura
            # TODO process with Decorators the gdv_appogiatura
            # TODO implement also posterior appogiatura neuma(neuma)
            # TODO implement also multiple appogiatura with several notes (neuma ... neuma)neuma or neuma(neuma ... neuma)

            gdv[:duration] = gdv[:duration] - gdv_appogiatura[:duration]

            super [ gdv_appogiatura, gdv ], base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Mordent transcriptor for MIDI playback.
      #
      # Expands mordent ornaments into a three-note sequence: main note, adjacent
      # note (upper or lower), then main note. The mordent is a quick ornament
      # typically used to emphasize a note.
      #
      # ## Mordent Types
      #
      # - `.mor` or `.mor(:up)` - Upper mordent (main, upper neighbor, main)
      # - `.mor(:down)` or `.mor(:low)` - Lower mordent (main, lower neighbor, main)
      #
      # ## Processing
      #
      # Given `.mor` on a note:
      # ```ruby
      # { grade: 0, duration: 1r, mor: true }
      # ```
      #
      # Expands to three notes:
      # ```ruby
      # [
      #   { grade: 0, duration: 1/16r },    # Main note (short)
      #   { grade: 1, duration: 1/16r },    # Upper neighbor (short)
      #   { grade: 0, duration: 7/8r }      # Main note (remaining duration)
      # ]
      # ```
      #
      # ## Duration Calculation
      #
      # Short notes duration: `base_duration * duration_factor` (default 1/4)
      # Final note gets remaining duration: `original - 2 * short_duration`
      #
      # @example Upper mordent
      #   mor = Mordent.new(duration_factor: 1/4r)
      #   gdv = { grade: 0, duration: 1r, mor: true }
      #   result = mor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
      #   # => [
      #   #   { grade: 0, duration: 1/16r },
      #   #   { grade: 1, duration: 1/16r },
      #   #   { grade: 0, duration: 7/8r }
      #   # ]
      #
      # @example Lower mordent
      #   gdv = { grade: 0, duration: 1r, mor: :down }
      #   # Uses lower neighbor (grade: -1)
      #
      # @api public
      # Process: .mor
      class Mordent < Musa::Transcription::FeatureTranscriptor
        # Creates mordent transcriptor.
        #
        # @param duration_factor [Rational] factor for ornament note duration
        #   relative to base_duration (default: 1/4)
        #
        # @api public
        def initialize(duration_factor: nil)
          @duration_factor = duration_factor || 1/4r
        end

        # Transcribes mordent to three-note sequence.
        #
        # @param gdv [Hash] GDV event possibly containing `:mor`
        # @param base_duration [Rational] base duration unit
        # @param tick_duration [Rational] minimum tick duration
        #
        # @return [Array<Hash>, Hash] array with mordent notes, or unchanged event
        #
        # @api public
        def transcript(gdv, base_duration:, tick_duration:)
          mor = gdv.delete :mor

          if mor
            direction = :up

            check(mor) do |mor|
              case mor
              when true, :up
                direction = :up
              when :down, :low
                direction = :down
              end
            end

            short_duration = [base_duration * @duration_factor, tick_duration].max

            gdvs = []

            gdvs << gdv.clone.tap { |gdv| gdv[:duration] = short_duration }

            case direction
            when :up
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = short_duration }
            when :down
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] -= 1; gdv[:duration] = short_duration }
            end

            gdvs << gdv.clone.tap { |gdv| gdv[:duration] -= 2 * short_duration }

            super gdvs, base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Turn transcriptor for MIDI playback.
      #
      # Expands turn ornaments into a four-note figure that circles around the
      # main note. A turn is a melodic embellishment consisting of the note above,
      # the principal note, the note below, and the principal note again.
      #
      # ## Turn Types
      #
      # - `.turn` or `.turn(:up)` - Start with upper neighbor (upper, main, lower, main)
      # - `.turn(:down)` or `.turn(:low)` - Start with lower neighbor (lower, main, upper, main)
      #
      # ## Processing
      #
      # Given `.turn` on a note:
      # ```ruby
      # { grade: 0, duration: 1r, turn: true }
      # ```
      #
      # Expands to four equal notes:
      # ```ruby
      # [
      #   { grade: 1, duration: 1/4r },    # Upper neighbor
      #   { grade: 0, duration: 1/4r },    # Main note
      #   { grade: -1, duration: 1/4r },   # Lower neighbor
      #   { grade: 0, duration: 1/4r }     # Main note
      # ]
      # ```
      #
      # Each note gets 1/4 of the original duration.
      #
      # @example Upper turn
      #   turn = Turn.new
      #   gdv = { grade: 0, duration: 1r, turn: true }
      #   result = turn.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
      #   # => [
      #   #   { grade: 1, duration: 1/4r },   # +1
      #   #   { grade: 0, duration: 1/4r },   # 0
      #   #   { grade: -1, duration: 1/4r },  # -1
      #   #   { grade: 0, duration: 1/4r }    # 0
      #   # ]
      #
      # @example Lower turn
      #   gdv = { grade: 0, duration: 1r, turn: :down }
      #   # => [
      #   #   { grade: -1, duration: 1/4r },  # -1
      #   #   { grade: 0, duration: 1/4r },   # 0
      #   #   { grade: 1, duration: 1/4r },   # +1
      #   #   { grade: 0, duration: 1/4r }    # 0
      #   # ]
      #
      # @api public
      # Process: .turn
      class Turn < Musa::Transcription::FeatureTranscriptor
        # Transcribes turn to four-note sequence.
        #
        # @param gdv [Hash] GDV event possibly containing `:turn`
        # @param base_duration [Rational] base duration unit
        # @param tick_duration [Rational] minimum tick duration
        #
        # @return [Array<Hash>, Hash] array with turn notes, or unchanged event
        #
        # @api public
        def transcript(gdv, base_duration:, tick_duration:)
          turn = gdv.delete :turn

          if turn
            start = :up

            check(turn) do |turn|
              case turn
              when true, :up
                start = :up
              when :down, :low
                start = :down
              end
            end

            duration = gdv[:duration] / 4r

            gdvs = []

            case start
            when :up
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += -1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
            when :down
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += -1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 1; gdv[:duration] = duration }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += 0; gdv[:duration] = duration }
            end

            super gdvs, base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Trill transcriptor for MIDI playback.
      #
      # Expands trill ornaments into a rapid alternation between the main note and
      # its upper neighbor. The trill fills the entire note duration with alternating
      # notes, with sophisticated duration management including acceleration.
      #
      # ## Trill Options
      #
      # - `.tr` or `.tr(true)` - Standard trill starting with upper neighbor
      # - `.tr(:low)` - Start with lower neighbor first (2 notes)
      # - `.tr(:low2)` - Start with upper but include lower neighbor (4 notes)
      # - `.tr(:same)` - Start with main note
      # - `.tr(factor)` - Custom duration factor (e.g., `.tr(1/8r)`)
      #
      # ## Duration Algorithm
      #
      # The trill uses a sophisticated multi-phase duration algorithm:
      #
      # 1. **Initial pattern**: Based on trill options (:low, :low2, :same)
      # 2. **Regular pattern**: Two cycles at full `note_duration`
      # 3. **Accelerando**: Cycles at 2/3 `note_duration` (faster)
      # 4. **Final notes**: Distribute remaining duration
      #
      # ## Processing
      #
      # Given `.tr` on a note:
      # ```ruby
      # { grade: 0, duration: 1r, tr: true }
      # ```
      #
      # Expands to alternating sequence:
      # ```ruby
      # [
      #   { grade: 1, duration: 1/16r },    # Upper (initial)
      #   { grade: 0, duration: 1/16r },    # Main
      #   { grade: 1, duration: 1/16r },    # Upper (regular)
      #   { grade: 0, duration: 1/16r },    # Main
      #   { grade: 1, duration: ~1/24r },   # Upper (accelerando)
      #   { grade: 0, duration: ~1/24r },   # Main
      #   ...
      # ]
      # ```
      #
      # @example Standard trill
      #   trill = Trill.new(duration_factor: 1/4r)
      #   gdv = { grade: 0, duration: 1r, tr: true }
      #   result = trill.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
      #   # Generates alternating upper/main notes filling duration
      #
      # @example Trill starting low
      #   gdv = { grade: 0, duration: 1r, tr: :low }
      #   # Starts with lower neighbor, then alternates upper/main
      #
      # @example Custom duration factor
      #   gdv = { grade: 0, duration: 1r, tr: 1/8r }
      #   # Faster trill with shorter note durations
      #
      # @api public
      # Process: .tr
      class Trill < Musa::Transcription::FeatureTranscriptor
        # Creates trill transcriptor.
        #
        # @param duration_factor [Rational] factor for trill note duration
        #   relative to base_duration (default: 1/4)
        #
        # @api public
        def initialize(duration_factor: nil)
          @duration_factor = duration_factor || 1/4r
        end

        # Transcribes trill to alternating note sequence.
        #
        # @param gdv [Hash] GDV event possibly containing `:tr`
        # @param base_duration [Rational] base duration unit
        # @param tick_duration [Rational] minimum tick duration
        #
        # @return [Array<Hash>, Hash] array with trill notes, or unchanged event
        #
        # @api public
        def transcript(gdv, base_duration:, tick_duration:)
          tr = gdv.delete :tr

          if tr
            note_duration = base_duration * @duration_factor

            check(tr) do |tr|
              case tr
              when Numeric # duration factor
                note_duration *= base_duration * tr.to_r
              end
            end

            used_duration = 0r
            last = nil

            gdvs = []

            check(tr) do |tr|
              case tr
              when :low # start with lower note
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = -1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                used_duration += 2 * note_duration

              when :low2 # start with upper note but go to lower note once
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = -1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                used_duration += 4 * note_duration

              when :same # start with the same note
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }
                used_duration += note_duration
              end
            end

            2.times do
              if used_duration + 2 * note_duration <= gdv[:duration]
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration }
                gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration }

                used_duration += 2 * note_duration
              end
            end

            while used_duration + 2 * note_duration * 2/3r <= gdv[:duration]
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = note_duration * 2/3r }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = note_duration * 2/3r }

              used_duration += 2 * note_duration * 2/3r
            end

            duration_diff = gdv[:duration] - used_duration
            if duration_diff >= note_duration
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 1); gdv[:duration] = duration_diff / 2 }
              gdvs << gdv.clone.tap { |gdv| gdv[:grade] += (last = 0); gdv[:duration] = duration_diff / 2 }

            elsif duration_diff > 0
              gdvs[-1][:duration] += duration_diff / 2
              gdvs[-2][:duration] += duration_diff / 2
            end

            super gdvs, base_duration: base_duration, tick_duration: tick_duration
          else
            super
          end
        end
      end

      # Staccato transcriptor for MIDI playback.
      #
      # Applies staccato articulation by shortening note duration. Instead of
      # creating multiple notes, staccato modifies the `:note_duration` attribute
      # to create a gap between note-off and the next note-on.
      #
      # ## Staccato Levels
      #
      # - `.st` or `.st(true)` - Half duration (1/2)
      # - `.st(1)` - Half duration (1/2)
      # - `.st(2)` - Quarter duration (1/4)
      # - `.st(3)` - Eighth duration (1/8)
      # - `.st(n)` - Duration divided by 2^n
      #
      # ## Processing
      #
      # Staccato sets `:note_duration` attribute (actual sounding duration)
      # while preserving `:duration` (rhythmic position duration). The gap
      # between these creates the staccato articulation.
      #
      # Given `.st` on a note:
      # ```ruby
      # { grade: 0, duration: 1r, st: true }
      # ```
      #
      # Results in:
      # ```ruby
      # { grade: 0, duration: 1r, note_duration: 1/2r }
      # ```
      # - `duration: 1r` - Next note starts after 1 beat
      # - `note_duration: 1/2r` - Note sounds for 1/2 beat (staccato gap)
      #
      # ## Minimum Duration
      #
      # A minimum duration (`base_duration * min_duration_factor`, default 1/8)
      # prevents extremely short notes that might sound like clicks.
      #
      # @example Basic staccato
      #   staccato = Staccato.new
      #   gdv = { grade: 0, duration: 1r, st: true }
      #   result = staccato.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
      #   # => { grade: 0, duration: 1r, note_duration: 1/2r }
      #
      # @example Staccato level 2
      #   gdv = { grade: 0, duration: 1r, st: 2 }
      #   # => { grade: 0, duration: 1r, note_duration: 1/4r }
      #
      # @example Very short note (minimum enforced)
      #   gdv = { grade: 0, duration: 1/16r, st: true }
      #   # note_duration clamped to base_duration * 1/8 (minimum)
      #
      # @api public
      # Process: .st .st(1) .st(2) .st(3): staccato level 1 2 3
      class Staccato < Musa::Transcription::FeatureTranscriptor
        # Creates staccato transcriptor.
        #
        # @param min_duration_factor [Rational] minimum duration factor relative
        #   to base_duration to prevent click-like short notes (default: 1/8)
        #
        # @api public
        def initialize(min_duration_factor: nil)
          @min_duration_factor = min_duration_factor || 1/8r
        end

        # Transcribes staccato by setting note_duration.
        #
        # @param gdv [Hash] GDV event possibly containing `:st`
        # @param base_duration [Rational] base duration unit
        # @param tick_duration [Rational] minimum tick duration
        #
        # @return [Hash] event with `:note_duration` set if staccato, or unchanged
        #
        # @api public
        def transcript(gdv, base_duration:, tick_duration:)
          st = gdv.delete :st

          if st
            calculated = 0

            check(st) do |st|
              case st
              when true
                calculated = gdv[:duration] / 2r
              when Numeric
                calculated = gdv[:duration] / 2**st if st >= 1
              end
            end

            gdv[:note_duration] = [calculated, base_duration * @min_duration_factor].max
          end

          super
        end
      end

    end
  end
end
