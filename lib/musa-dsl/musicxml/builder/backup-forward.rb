require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Timeline rewind for polyphonic music.
        #
        # Backup moves the musical timeline backwards by a specified duration,
        # allowing overlapping musical content to be written sequentially.
        # This is essential for polyphonic music where multiple voices or staves
        # play simultaneously.
        #
        # ## Use Cases
        #
        # **Multiple Voices**: Write voice 1, backup, then write voice 2 starting
        # at the same timepoint.
        #
        # **Multi-Staff Instruments**: Write treble staff notes, backup, then write
        # bass staff notes for the same measure.
        #
        # **Polyphonic Textures**: Layer independent melodic lines that share
        # temporal alignment.
        #
        # ## Duration Units
        #
        # Duration is specified in the measure's division units (not note values).
        # If divisions=4, then duration=8 means 8 divisions = 2 quarter notes = 1 half note.
        #
        # Common pattern: backup by the full measure duration to restart from the
        # beginning of the measure.
        #
        # ## Workflow Example
        #
        # 1. Write notes for voice 1
        # 2. Backup to measure start
        # 3. Write notes for voice 2 (with voice: 2 parameter)
        # 4. Optionally backup again for additional voices
        #
        # @example Piano with simultaneous treble and bass
        #   measure.pitch 'D', octave: 4, duration: 4, type: 'half'
        #   measure.pitch 'E', octave: 4, duration: 4, type: 'half'
        #
        #   measure.backup 8  # Rewind full measure (8 divisions)
        #
        #   measure.pitch 'C', octave: 3, duration: 8, type: 'whole', staff: 2
        #
        # @example Two voices on the same staff
        #   measure.pitch 'C', octave: 5, duration: 2, type: 'quarter', voice: 1
        #   measure.pitch 'D', octave: 5, duration: 2, type: 'quarter', voice: 1
        #   measure.pitch 'E', octave: 5, duration: 2, type: 'quarter', voice: 1
        #   measure.pitch 'F', octave: 5, duration: 2, type: 'quarter', voice: 1
        #
        #   measure.backup 8  # Back to measure start
        #
        #   measure.pitch 'E', octave: 4, duration: 4, type: 'half', voice: 2
        #   measure.pitch 'F', octave: 4, duration: 4, type: 'half', voice: 2
        #
        # @example Three-voice polyphony
        #   # Voice 1
        #   measure.pitch 'G', octave: 5, duration: 8, type: 'whole', voice: 1
        #
        #   measure.backup 8
        #
        #   # Voice 2
        #   measure.pitch 'C', octave: 5, duration: 8, type: 'whole', voice: 2
        #
        #   measure.backup 8
        #
        #   # Voice 3
        #   measure.pitch 'E', octave: 4, duration: 8, type: 'whole', voice: 3
        #
        # @see Forward Forward navigation for skipping time
        class Backup
          include Helper::ToXML

          # Creates a backup (timeline rewind).
          #
          # @param duration [Integer] rewind amount in division units
          #
          # @example Rewind full measure (divisions=4, 4/4 time)
          #   Backup.new(8)  # 8 divisions = 2 quarter notes
          #
          # @example Rewind half measure
          #   Backup.new(4)  # 4 divisions = 1 quarter note
          def initialize(duration)
            @duration = duration
          end

          # Duration to rewind in division units.
          # @return [Integer]
          attr_accessor :duration

          # Generates the backup XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<backup><duration>#{@duration.to_i}</duration></backup>"
          end
        end

        # Timeline advance without producing sound.
        #
        # Forward moves the musical timeline forward by a specified duration
        # without generating notes or rests. It's used for positioning within
        # multi-voice contexts and creating invisible space.
        #
        # ## Use Cases
        #
        # **Voice Positioning**: Advance to a specific point in time before
        # adding notes in a particular voice.
        #
        # **Invisible Rests**: Skip time without displaying rest symbols
        # (useful in multi-voice scenarios where another voice fills the space).
        #
        # **Rhythmic Offset**: Start a voice partway through a measure without
        # explicit rest notation.
        #
        # ## Duration Units
        #
        # Duration is specified in the measure's division units (not note values).
        # If divisions=4, then duration=2 means 2 divisions = 1 eighth note.
        #
        # ## Voice and Staff
        #
        # Optional voice and staff parameters indicate which voice/staff the
        # forward applies to. This helps notation software correctly position
        # subsequent notes.
        #
        # @example Skip a quarter note in voice 2
        #   measure.forward 2, voice: 2  # Skip 2 divisions in voice 2
        #   measure.pitch 'C', octave: 5, duration: 2, type: 'quarter', voice: 2
        #
        # @example Offset entry on bass staff
        #   measure.forward 4, staff: 2  # Skip half measure on bass staff
        #   measure.pitch 'C', octave: 3, duration: 4, type: 'half', staff: 2
        #
        # @example Multi-voice with staggered entries
        #   # Voice 1 starts immediately
        #   measure.pitch 'G', octave: 5, duration: 4, type: 'half', voice: 1
        #
        #   measure.backup 4  # Return to measure start
        #
        #   # Voice 2 starts after quarter note delay
        #   measure.forward 2, voice: 2  # Skip quarter note
        #   measure.pitch 'E', octave: 5, duration: 2, type: 'quarter', voice: 2
        #
        # @see Backup Backup for timeline rewind
        class Forward
          include Helper::ToXML

          # Creates a forward (timeline advance).
          #
          # @param duration [Integer] advance amount in division units
          # @param voice [Integer, nil] voice number this forward applies to
          # @param staff [Integer, nil] staff number this forward applies to
          #
          # @example Skip quarter note
          #   Forward.new(2)  # 2 divisions
          #
          # @example Skip with voice specification
          #   Forward.new(4, voice: 2)
          #
          # @example Skip on specific staff
          #   Forward.new(4, staff: 2)
          def initialize(duration, voice: nil, staff: nil)
            @duration = duration
            @voice = voice
            @staff = staff
          end

          # Duration to advance in division units.
          # @return [Integer]
          attr_accessor :duration

          # Voice number (for multi-voice contexts).
          # @return [Integer, nil]
          attr_accessor :voice

          # Staff number (for multi-staff instruments).
          # @return [Integer, nil]
          attr_accessor :staff

          # Generates the forward XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<forward>"

            io.puts "#{tabs}\t<duration>#{@duration.to_i}</duration>"
            io.puts "#{tabs}\t<voice>#{@voice.to_i}</voice>" if @voice
            io.puts "#{tabs}\t<staff>#{@staff.to_i}</staff>" if @staff

            io.puts "#{tabs}</forward>"
          end
        end
      end
    end
  end
end