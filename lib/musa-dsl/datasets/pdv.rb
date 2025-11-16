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
  # - **Velocity**: Maps MIDI 0-127 to dynamics -5 to +4 (ppp to fff)
  #
  # ### Velocity Mapping
  #
  # MIDI velocities are mapped to musical dynamics:
  #
  #     MIDI 1-1    → velocity -5 (ppp)
  #     MIDI 2-8    → velocity -4 (pp)
  #     MIDI 9-16   → velocity -3 (p)
  #     MIDI 17-33  → velocity -2 (mp)
  #     MIDI 34-48  → velocity -1 (mf-)
  #     MIDI 49-64  → velocity  0 (mf)
  #     MIDI 65-80  → velocity +1 (f)
  #     MIDI 81-96  → velocity +2 (ff)
  #     MIDI 97-112 → velocity +3 (fff-)
  #     MIDI 113-127 → velocity +4 (fff)
  #
  # ## Base Duration
  #
  # The `base_duration` attribute defines the unit for duration values,
  # typically 1/4r (quarter note).
  #
  # @example Basic MIDI event
  #   pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
  #   pdv.base_duration = 1/4r
  #   # C4 (middle C) for 1 beat at mf dynamics
  #
  # @example Silence (rest)
  #   pdv = { pitch: :silence, duration: 1.0 }.extend(PDV)
  #   # Rest for 1 beat
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
    #   # => { grade: :silence, duration: 1.0 }
    def to_gdv(scale)
      gdv = {}.extend GDV
      gdv.base_duration = @base_duration

      if self[:pitch]
        if self[:pitch] == :silence
          gdv[:grade] = :silence
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
        # ppp = 16 ... fff = 127
        # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
        gdv[:velocity] = [1..1, 2..8, 9..16, 17..33, 34..48, 49..64, 65..80, 81..96, 97..112, 113..127].index { |r| r.cover? self[:velocity] } - 5
      end

      (keys - NaturalKeys).each { |k| gdv[k] = self[k] }

      gdv
    end
  end
end
