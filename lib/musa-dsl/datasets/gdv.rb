require_relative 'e'
require_relative 'gdvd'
require_relative 'pdv'

require_relative 'helper'

module Musa::Datasets
  # Score-style musical events with scale degrees.
  #
  # GDV (Grade/Duration/Velocity) represents musical events using score notation
  # with scale degrees, octaves, and dynamics. Extends {AbsD} for duration support.
  #
  # ## Purpose
  #
  # GDV is the score representation layer of the dataset framework:
  #
  # - Uses scale degrees (grade) instead of absolute pitches
  # - Uses dynamics markings (velocity -5 to +4) instead of MIDI velocity
  # - Human-readable and musically meaningful
  # - Independent of specific tuning or scale
  #
  # Contrast with {PDV} which uses MIDI absolute pitches and velocities.
  #
  # ## Natural Keys
  #
  # - **:grade**: Scale degree (integer, 0-based)
  # - **:sharps**: Chromatic alteration (integer, positive = sharp, negative = flat)
  # - **:octave**: Octave offset (integer, 0 = base octave)
  # - **:velocity**: Dynamics (-3 to +4, where 0 = mp, 1 = mf)
  # - **:silence**: Indicates rest (boolean or symbol)
  # - **:duration**: Event duration (from {AbsD})
  # - **:note_duration**, **:forward_duration**: Additional duration keys (from {AbsD})
  #
  # ## Pitch Representation
  #
  # Pitches are specified as:
  #
  # - **grade**: Position in scale (0 = first note, 1 = second note, etc.)
  # - **octave**: Octave offset (0 = base, 1 = up one octave, -1 = down one octave)
  # - **sharps**: Chromatic alteration (1 = sharp, -1 = flat, 2 = double sharp, etc.)
  #
  # Example in C major scale:
  #
  # - C4 = { grade: 0, octave: 0 }
  # - D4 = { grade: 1, octave: 0 }
  # - C5 = { grade: 0, octave: 1 }
  # - C#4 = { grade: 0, octave: 0, sharps: 1 }
  #
  # ## Velocity (Dynamics)
  #
  # Velocity represents musical dynamics in range -3 to +4:
  #
  #     -3: ppp (pianississimo)
  #     -2: pp  (pianissimo)
  #     -1: p   (piano)
  #      0: mp  (mezzo-piano)
  #     +1: mf  (mezzo-forte)
  #     +2: f   (forte)
  #     +3: ff  (fortissimo)
  #     +4: fff (fortississimo)
  #
  # ## Conversions
  #
  # ### To PDV (MIDI)
  #
  # Converts score notation to MIDI using a scale:
  #
  #     gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
  #     scale = Musa::Scales::Scales.et12[440.0].major[60]
  #     pdv = gdv.to_pdv(scale)
  #     # => { pitch: 60, duration: 1r, velocity: 64 }
  #
  # ### To GDVd (Delta Encoding)
  #
  # Converts to delta encoding for efficient storage:
  #
  #     gdv1 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
  #     gdv2 = { grade: 2, octave: 0, duration: 1r, velocity: 1 }.extend(GDV)
  #     [gdv1, gdv2].each { |g| g.base_duration = 1/4r }
  #     gdvd = gdv2.to_gdvd(scale, previous: gdv1)
  #     # => { delta_grade: 2, delta_sharps: 0, delta_velocity: 1 }
  #
  # ### To Neuma Notation
  #
  # Converts to Neuma string format for serialization:
  #
  #     gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)
  #     gdv.base_duration = 1/4r
  #     gdv.to_neuma  # => "(0 4 mp)"
  #
  # ## MIDI Velocity Mapping
  #
  # Dynamics are mapped to MIDI velocities using interpolation:
  #
  #     -3 (ppp) →  16
  #     -2 (pp)  →  33
  #     -1 (p)   →  49
  #      0 (mp)  →  64
  #     +1 (mf)  →  80
  #     +2 (f)   →  96
  #     +3 (ff)  → 112
  #     +4 (fff) → 127
  #
  # @example Basic score event
  #   gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(Musa::Datasets::GDV)
  #   gdv.base_duration = 1/4r
  #   # First scale degree, base octave, 1 beat, mp dynamics
  #
  # @example Chromatic alteration
  #   gdv = { grade: 0, octave: 0, sharps: 1, duration: 1r }.extend(GDV)
  #   # First scale degree sharp (C# in C major)
  #
  # @example Silence (rest)
  #   gdv = { silence: true, duration: 1r }.extend(GDV)
  #   # Rest for 1 beat. The :silence KEY is what says so -- a grade named
  #   # :silence is not a rest, it is a grade nothing can look up.
  #
  # @example Convert to MIDI
  #   gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
  #   scale = Musa::Scales::Scales.et12[440.0].major[60]
  #   pdv = gdv.to_pdv(scale)
  #   # => { pitch: 60, duration: 1r, velocity: 64 }
  #
  # @example Convert to delta encoding
  #   gdv1 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
  #   gdv2 = { grade: 2, octave: 0, duration: 1r, velocity: 1 }.extend(GDV)
  #   [gdv1, gdv2].each { |g| g.base_duration = 1/4r }
  #   scale = Musa::Scales::Scales.et12[440.0].major[60]
  #   gdv2.to_gdvd(scale, previous: gdv1)
  #   # => { delta_grade: 2, delta_sharps: 0, delta_velocity: 1 }
  #
  # @example Convert to Neuma notation
  #   gdv = { grade: 0, octave: 1, duration: 1r, velocity: 2 }.extend(GDV)
  #   gdv.base_duration = 1/4r
  #   gdv.to_neuma  # => "(0 o1 4 f)"
  #
  # @see PDV MIDI-style representation
  # @see GDVd Delta encoding
  # @see AbsD Absolute duration events
  # @see Helper String formatting utilities
  module GDV
    using Musa::Extension::InspectNice

    include AbsD

    include Helper

    # Natural keys for score events.
    # @return [Array<Symbol>]
    NaturalKeys = (NaturalKeys + [:grade, :sharps, :octave, :velocity, :silence]).freeze

    # Base duration for time calculations.
    # @return [Rational]
    attr_accessor :base_duration

    # MIDI velocity mapping for dynamics.
    #
    # Maps dynamics values (-5 to +4) to MIDI velocities (0-127).
    # Used for interpolation in {#to_pdv}.
    #
    # @return [Array<Integer>] MIDI velocity breakpoints
    # @api private
    # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
    # ppp = 16 ... fff = 127 (-5 ... 4) the standard used by Musescore 3 and others starts at ppp = 16
    VELOCITY_MAP = [1, 8, 16, 33, 49, 64, 80, 96, 112, 127].freeze

    # The same mapping read the other way: which dynamic a MIDI velocity belongs
    # to. Each band runs from just above the previous dynamic's velocity up to
    # its own, so every value in VELOCITY_MAP falls in its own band.
    #
    # DERIVED, NOT WRITTEN AGAIN. {PDV#to_gdv} used to carry its own copy of
    # these ten ranges, and the copy disagreed with VELOCITY_MAP at exactly one
    # edge: it closed p's band at 48 and started mp's at 49, so p's own velocity
    # read back as mp and the dynamic did not survive a round trip (issue #86).
    # One rule written twice is one rule that will be corrected once.
    #
    # @return [Array<Range>] MIDI velocity bands, from -5 to +4
    # @api private
    VELOCITY_BANDS = VELOCITY_MAP.each_with_index.collect do |top, i|
      (i.zero? ? top : VELOCITY_MAP[i - 1] + 1)..top
    end.freeze

    # Converts to PDV (MIDI representation).
    #
    # Translates score notation to MIDI using a scale:
    # - Scale degree → MIDI pitch (via scale lookup)
    # - Dynamics → MIDI velocity (via interpolation)
    # - Duration values copied
    # - Additional keys preserved
    #
    # @param scale [Musa::Scales::Scale] reference scale for pitch conversion
    #
    # @return [PDV] MIDI representation dataset
    #
    # @example Basic conversion
    #   gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #   gdv.to_pdv(scale)  # => { pitch: 60, duration: 1r, velocity: 64 }
    #
    # @example Chromatic note
    #   gdv = { grade: 0, octave: 0, sharps: 1, duration: 1r }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_pdv(scale)  # => { pitch: 61, duration: 1r }
    #
    # @example Silence
    #   # A rest is the :silence KEY, not a grade of that name, and the key is
    #   # enough on its own: the grade the decoder also puts there is the note
    #   # that would have sounded, and nothing needs it.
    #   gdv = { silence: true, duration: 1r }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_pdv(scale)  # => { pitch: :silence, duration: 1r }
    #
    # @example A silence as the decoder writes it, with the grade it silences
    #   gdv = { grade: 0, octave: 0, duration: 1r, silence: true }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_pdv(scale)  # => { pitch: :silence, duration: 1r }
    #
    # @example Dynamics interpolation
    #   gdv = { grade: 0, octave: 0, velocity: 0.5 }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_pdv(scale)  # => { pitch: 60, velocity: 72.0 }
    #   # velocity 0.5 interpolates between mp (64) and mf (80)
    def to_pdv(scale)
      pdv = {}.extend PDV
      pdv.base_duration = @base_duration

      # A rest is a rest whether or not it also carries the grade of the note
      # that would have sounded. Asking for the grade first left a silence with
      # no grade -- which is what a PDV rest converts into, since a PDV rest
      # carries no grade to recover -- with no :pitch at all, so it stopped
      # raising and started disappearing instead.
      if self[:silence]
        pdv[:pitch] = :silence
      elsif self[:grade]
        pdv[:pitch] = scale[self[:grade]].sharp(self[:sharps] || 0).at_octave(self[:octave] || 0).pitch
      end

      if self[:duration]
        pdv[:duration] = self[:duration]
      end

      if self[:note_duration]
        pdv[:note_duration] = self[:note_duration]
      end

      if self[:forward_duration]
        pdv[:forward_duration] = self[:forward_duration]
      end

      if self[:velocity]
        index = if (-5..4).cover?(self[:velocity])
                  self[:velocity]
                else
                  self[:velocity] < -5 ? -5 : 4
                end

        index_min = index.floor
        index_max = index.ceil

        velocity = VELOCITY_MAP[index_min + 5] +
          (VELOCITY_MAP[index_max + 5] - VELOCITY_MAP[index_min + 5]) * (self[:velocity] - index_min)

        pdv[:velocity] = velocity
      end

      (keys - NaturalKeys).each { |k| pdv[k] = self[k] }

      pdv
    end

    # Converts to Neuma notation string.
    #
    # Neuma is a compact text format for score notation. Format:
    #
    #     (grade[sharps] [octave] [duration] [velocity] [modifiers...])
    #
    # - **grade**: Scale degree number (0, 1, 2...) or 'silence' for rests
    # - **sharps**: '#' for sharp, '_' for flat (e.g., "0#" = first degree sharp)
    # - **octave**: 'o' + number (e.g., "o1" = up one octave, "o-1" = down one)
    # - **duration**: Number of base_duration units
    # - **velocity**: Dynamics string (ppp, pp, p, mp, mf, f, ff, fff -- and any
    #   number of p's or f's beyond those, see {Helper#velocity_of})
    # - **modifiers**: Additional key-value pairs (e.g., "staccato")
    #
    # @return [String] Neuma notation
    #
    # @example Basic note
    #   gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(0 4 mp)"
    #   # grade 0, four base_durations long, mp
    #
    # @note The dynamics run ppp pp p mp mf f ff for velocities -3..3, so
    #   velocity 0 is mp and not the middle of the range. And the duration must
    #   be Rational: a Float duration reaches the notation as one, and
    #   `{ duration: 1r }` renders "(0 4.0 mp)".
    #
    # @example Softer than ppp, which VELOCITY_MAP reaches and the notation names
    #   gdv = { grade: 0, duration: 1r, velocity: -4 }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(0 4 pppp)"
    #
    # @example With octave
    #   gdv = { grade: 2, octave: 1, duration: 1/2r, velocity: 2 }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(2 o1 2 f)"
    #
    # @example Sharp note
    #   gdv = { grade: 0, sharps: 1, duration: 1r }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(0# 4)"
    #
    # @example Flat note
    #   gdv = { grade: 1, sharps: -1, duration: 1r }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(1_ 4)"
    #
    # @example Silence
    #   gdv = { grade: :silence, duration: 1r }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(silence 4)"
    #
    # @example With modifiers
    #   gdv = { grade: 0, duration: 1r, staccato: true }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_neuma  # => "(0 4 staccato)"
    def to_neuma
      @base_duration ||= Rational(1, 4)

      attributes = []

      c = 0

      if include?(:silence)
        attributes[c] = :silence
      elsif include?(:grade)
        attributes[c] = self[:grade].to_s
        if include?(:sharps)
          if self[:sharps] > 0
            attributes[c] += '#' * self[:sharps]
          elsif self[:sharps] < 0
            attributes[c] += '_' * self[:sharps].abs
          end
        end
      end

      attributes[c] = '.' if attributes[c].nil? || attributes[c].empty?

      attributes[c += 1] = 'o' + self[:octave].to_s if self[:octave]
      attributes[c += 1] = (self[:duration] / @base_duration).to_s if self[:duration]
      attributes[c += 1] = velocity_of(self[:velocity]) if self[:velocity]

      (keys - NaturalKeys).each do |k|
        attributes[c += 1] = modificator_string(k, self[k])
      end

      '(' + attributes.join(' ') + ')'
    end

    # Converts to GDVd (delta encoding).
    #
    # Creates delta-encoded representation relative to a previous event.
    # Only changed values are included, making the representation compact.
    #
    # Without previous event (first in sequence):
    # - Uses abs_ keys for all values
    #
    # With previous event:
    # - Uses delta_ keys for changed values
    # - Omits unchanged values
    # - Uses abs_ keys when changing from nil to value
    #
    # @param scale [Musa::Scales::Scale] reference scale for grade calculation
    # @param previous [GDV, nil] previous event for delta calculation
    #
    # @return [GDVd] delta-encoded dataset
    #
    # @example First event (no previous)
    #   # base_duration must have been set: without it the conversion divides by nil.
    #   gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(GDV)
    #   gdv.base_duration = 1/4r
    #   gdv.to_gdvd(scale)  # => { abs_grade: 0, abs_duration: 1r, abs_velocity: 0 }
    #
    # @example Changed values
    #   # Both events need an :octave for a delta to be computable.
    #   gdv1 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
    #   gdv2 = { grade: 2, octave: 0, duration: 1r, velocity: 1 }.extend(GDV)
    #   [gdv1, gdv2].each { |g| g.base_duration = 1/4r }
    #   gdv2.to_gdvd(scale, previous: gdv1)
    #   # => { delta_grade: 2, delta_sharps: 0, delta_velocity: 1 }
    #   # duration unchanged, so omitted
    #
    # @example Unchanged values
    #   same1 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
    #   same2 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(GDV)
    #   [same1, same2].each { |g| g.base_duration = 1/4r }
    #   same2.to_gdvd(scale, previous: same1)  # => {}
    #   # Everything unchanged
    #
    # @example Chromatic alteration
    #   plain = { grade: 0, octave: 0 }.extend(GDV)
    #   sharp = { grade: 0, octave: 0, sharps: 1 }.extend(GDV)
    #   [plain, sharp].each { |g| g.base_duration = 1/4r }
    #   sharp.to_gdvd(scale, previous: plain)  # => { delta_grade: 0, delta_sharps: 1 }
    def to_gdvd(scale, previous: nil)
      gdvd = {}.extend GDVd
      gdvd.base_duration = @base_duration

      if previous

        if include?(:silence)
          gdvd[:abs_grade] = :silence

        elsif include?(:grade) && !previous.include?(:grade)
          gdvd[:abs_grade] = self[:grade]
          gdvd[:abs_sharps] = self[:sharps]

        elsif include?(:grade) && previous.include?(:grade)
          if self[:grade] != previous[:grade] ||
            (self[:sharps] || 0) != (previous[:sharps] || 0)

            gdvd[:delta_grade] =
                scale[self[:grade]].at_octave(self[:octave]).wide_grade -
                scale[previous[:grade]].at_octave(previous[:octave]).wide_grade

            gdvd[:delta_sharps] = (self[:sharps] || 0) - (previous[:sharps] || 0)
          end
        elsif include?(:sharps)
          gdvd[:delta_sharps] = self[:sharps] - (previous[:sharps] || 0)
        end

        if self[:duration] && previous[:duration] && (self[:duration] != previous[:duration])
          gdvd[:delta_duration] = (self[:duration] - previous[:duration])
        end

        if self[:velocity] && previous[:velocity] && (self[:velocity] != previous[:velocity])
          gdvd[:delta_velocity] = self[:velocity] - previous[:velocity]
        end
      else
        # The same order as the branch above, and for the same reason: a rest
        # asked about its grade answers with the grade it silences. Asking that
        # first turned a rest opening a delta-encoded sequence into an audible
        # note -- `(silence 4)` came out as `(0 4 mf)` (issue #80).
        if self[:silence]
          gdvd[:abs_grade] = :silence
        elsif self[:grade]
          gdvd[:abs_grade] = self[:grade]
        end

        gdvd[:abs_duration] = self[:duration] if self[:duration]
        gdvd[:abs_velocity] = self[:velocity] if self[:velocity]
      end

      (keys - NaturalKeys).each { |k| gdvd[k] = self[k] }

      gdvd
    end
  end
end
