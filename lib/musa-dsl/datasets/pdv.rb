require_relative 'e'
require_relative 'gdv'

require_relative 'helper'

module Musa::Datasets
  # MIDI-style musical events with absolute pitches.
  #
  # PDV (Pitch/Duration/Velocity) represents musical events using MIDI-like
  # absolute pitch numbers. Extends {AbsD} for duration support.
  #
  # ## Purpose
  #
  # PDV is the MIDI representation layer of the dataset framework:
  #
  # - Uses absolute MIDI pitch numbers (0-127)
  # - Uses MIDI velocity values (0-127)
  # - Direct mapping to MIDI messages
  # - Machine-oriented (not human-readable)
  #
  # Contrast with {GDV} which uses score notation (scale degrees, dynamics).
  #
  # ## Natural Keys
  #
  # - **:pitch**: MIDI pitch number (0-127) or :silence for rests
  # - **:velocity**: MIDI velocity (0-127)
  # - **:duration**: Event duration (from {AbsD})
  # - **:note_duration**, **:forward_duration**: Additional duration keys (from {AbsD})
  #
  # ## Conversions
  #
  # ### To GDV (Score Notation)
  #
  # Converts MIDI pitches to scale degrees using a scale reference:
  #
  #     pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(PDV)
  #     scale = Musa::Scales::Scales.et12[440.0].major[60]
  #     gdv = pdv.to_gdv(scale)
  #     # => { grade: 0, octave: 0, duration: 1.0, velocity: 0 }
  #
  # - **Pitch → Grade**: Finds closest scale degree
  # - **Chromatic notes**: Represented as grade + sharps
  # - **Velocity**: Maps MIDI 1-127 to dynamics -5 to +4 (ppppp to fff)
  #
  # ### Velocity Mapping
  #
  # MIDI velocities are mapped to musical dynamics:
  #
  #     MIDI 0       → not a dynamic at all: no sound, which becomes a rest
  #     MIDI 1-1     → velocity -5 (ppppp)
  #     MIDI 2-8     → velocity -4 (pppp)
  #     MIDI 9-16    → velocity -3 (ppp)
  #     MIDI 17-33   → velocity -2 (pp)
  #     MIDI 34-49   → velocity -1 (p)
  #     MIDI 50-64   → velocity  0 (mp)
  #     MIDI 65-80   → velocity +1 (mf)
  #     MIDI 81-96   → velocity +2 (f)
  #     MIDI 97-112  → velocity +3 (ff)
  #     MIDI 113-127 → velocity +4 (fff)
  #
  # Zero is left out on purpose. A pianissimo, however faint, is a sound; zero
  # amplitude is not one, so it is not the bottom of this scale but off it, and
  # {#to_gdv} writes it as a rest. Anything above 127 or between 0 and 1 is
  # clamped into the table.
  #
  # The names come from {Helper#velocity_of}, and zero is mp, not mf. The table
  # used to name them two steps towards the soft end, which is where the
  # `velocity 0 == mf` misreading kept coming back from (issue #74).
  #
  # The bands themselves are {GDV::VELOCITY_BANDS}, derived from
  # {GDV::VELOCITY_MAP} so that each dynamic's own MIDI velocity falls inside
  # its own band. They used to be written out here a second time, and disagreed
  # with the map at MIDI 49 (issue #86).
  #
  # ## Base Duration
  #
  # The `base_duration` attribute defines the unit for duration values,
  # typically 1/4r, which is a quarter of a bar -- a quarter note in 4/4 and
  # not in other meters; see {Musa::Datasets::AbsD}.
  #
  # @example Basic MIDI event
  #   pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
  #   pdv.base_duration = 1/4r
  #   # C4 (middle C) for 1 beat at mf dynamics
  #
  # @example Silence (rest)
  #   pdv = { pitch: :silence, duration: 1.0 }.extend(PDV)
  #   # Rest for 1 beat. In GDV a rest is the :silence key, not a grade of that
  #   # name; {#to_gdv} writes that key.
  #
  # @example With articulation
  #   pdv = {
  #     pitch: 64,
  #     duration: 1.0,
  #     note_duration: 0.5,  # Staccato
  #     velocity: 80
  #   }.extend(PDV)
  #
  # @example Convert to score notation
  #   pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(PDV)
  #   pdv.base_duration = 1/4r
  #   scale = Musa::Scales::Scales.et12[440.0].major[60]
  #   gdv = pdv.to_gdv(scale)
  #   # => { grade: 0, octave: 0, duration: 1.0, velocity: 0 }
  #
  # @example Chromatic pitch
  #   pdv = { pitch: 61, duration: 1.0, velocity: 64 }.extend(PDV)
  #   scale = Musa::Scales::Scales.et12[440.0].major[60]
  #   gdv = pdv.to_gdv(scale)
  #   # => { grade: 0, octave: 0, sharps: 1, duration: 1.0, velocity: 0 }
  #   # C# represented as C (grade 0) + 1 sharp
  #
  # @example Preserve additional keys
  #   pdv = {
  #     pitch: 60,
  #     duration: 1.0,
  #     velocity: 64,
  #     custom_key: :value
  #   }.extend(PDV)
  #   scale = Musa::Scales::Scales.et12[440.0].major[60]
  #   gdv = pdv.to_gdv(scale)
  #   # custom_key copied to GDV (not a natural key)
  #
  # @see GDV Score-style representation
  # @see AbsD Absolute duration events
  # @see Helper String formatting utilities
  module PDV
    include AbsD

    include Helper

    # Natural keys for MIDI events.
    # @return [Array<Symbol>]
    NaturalKeys = (NaturalKeys + [:pitch, :velocity]).freeze

    # Base duration for time calculations.
    # @return [Rational]
    attr_accessor :base_duration

    # Converts to GDV (score notation).
    #
    # Translates MIDI representation to score notation using a scale:
    # - MIDI pitch → scale degree (grade + octave + sharps)
    # - MIDI velocity → dynamics (-5 to +4)
    # - Duration values copied
    # - Additional keys preserved
    #
    # @param scale [Musa::Scales::Scale] reference scale for pitch conversion
    #
    # @return [GDV] score notation dataset
    #
    # @example Basic conversion
    #   pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(PDV)
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #   gdv = pdv.to_gdv(scale)
    #
    # @example Chromatic note
    #   pdv = { pitch: 61, duration: 1.0 }.extend(PDV)
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #   gdv = pdv.to_gdv(scale)
    #   # => { grade: 0, octave: 0, sharps: 1, duration: 1.0 }
    #
    # @example Silence
    #   pdv = { pitch: :silence, duration: 1.0 }.extend(PDV)
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #   gdv = pdv.to_gdv(scale)
    #   # => { silence: true, duration: 1.0 }
    #
    #   # A rest carries no grade: there is none to recover, and none is needed.
    #   gdv.to_pdv(scale)  # => { pitch: :silence, duration: 1.0 }
    #
    # @example A note at no velocity is a note that does not sound
    #   pdv = { pitch: 60, duration: 1/4r, velocity: 0 }.extend(PDV)
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #
    #   # The grade survives the crossing: GDV can say "this note, silenced",
    #   # which is the shape the neuma decoder produces for a rest.
    #   pdv.to_gdv(scale)  # => { grade: 0, octave: 0, duration: (1/4), silence: true }
    #
    #   # Coming back normalises it to a plain rest, which is what PDV has.
    #   pdv.to_gdv(scale).to_pdv(scale)  # => { pitch: :silence, duration: (1/4) }
    #
    # @example Any positive velocity is a sound, however faint
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #
    #   { pitch: 60, velocity: 0.4 }.extend(PDV).to_gdv(scale)[:velocity]  # => -5
    #   { pitch: 60, velocity: 200 }.extend(PDV).to_gdv(scale)[:velocity]  # => 4
    def to_gdv(scale)
      gdv = {}.extend GDV
      gdv.base_duration = @base_duration

      if self[:pitch]
        if self[:pitch] == :silence
          # The :silence KEY, which is what everything else reads and a declared
          # natural key of GDV. It used to write `grade: :silence`, which nothing
          # reads: the GDV came back malformed by the framework's own convention
          # and could not be converted again (issue #80). It looked right only
          # because to_neuma falls through to printing the grade, and the
          # symbol's name happens to be the word the notation uses.
          gdv[:silence] = true
        else
          note = scale.note_of_pitch(self[:pitch], allow_chromatic: true)

          if background_note = note.background_note
            gdv[:grade] = background_note.grade
            gdv[:octave] = background_note.octave
            gdv[:sharps] = note.background_sharps
          else
            gdv[:grade] = note.grade
            gdv[:octave] = note.octave
          end
        end
      end

      gdv[:duration] = self[:duration] if self[:duration]

      if self[:velocity]
        # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
        if self[:velocity] <= 0
          # No sound, and that is not the same as the softest sound. A
          # pianissimo, however faint, is something being played; zero amplitude
          # is not. MIDI's own velocity 0 means "note off" at the wire, but PDV
          # is a dataset and not a protocol, so here it can only mean what it
          # says.
          #
          # What the score layer writes for "this does not sound" is a rest, and
          # GDV already has the representation: the grade of the note that would
          # have sounded plus the :silence key, which is exactly the shape the
          # neuma decoder produces for `(silence 4)`. So the pitch survives the
          # crossing; it is `GDV#to_pdv` that normalises it back to a plain
          # `pitch: :silence`.
          #
          # It used to raise: the bands start at 1, so nothing covered 0, `index`
          # returned nil and `nil - 5` blew up with a message naming neither the
          # velocity nor the dataset (issue #85).
          gdv[:silence] = true
        else
          # Any positive velocity is a sound. Clamped because MIDI says nothing
          # outside 1..127, and because a velocity between 0 and 1 -- what a
          # continuous curve gives before it is rounded -- is a sound too, and
          # fell through the same hole.
          gdv[:velocity] = GDV::VELOCITY_BANDS.index { |band| band.cover?(self[:velocity].clamp(1, 127)) } - 5
        end
      end

      (keys - NaturalKeys).each { |k| gdv[k] = self[k] }

      gdv
    end
  end
end
