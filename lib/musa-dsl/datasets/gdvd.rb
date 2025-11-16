require_relative 'delta-d'
require_relative 'gdv'

require_relative 'helper'


module Musa::Datasets
  # Delta-encoded score events for efficient compression.
  #
  # GDVd (Grade/Duration/Velocity delta) represents musical events using
  # delta encoding - storing only changes from previous events.
  # Extends {DeltaD} for flexible duration encoding and {DeltaI} for indexed deltas.
  #
  # ## Purpose
  #
  # GDVd provides efficient delta encoding for musical sequences:
  # - **Compact storage**: Only changed values are stored
  # - **Efficient serialization**: Neuma format uses delta notation
  # - **Lossless compression**: Full reconstruction via {#to_gdv}
  # - **Musical patterns**: Captures relative motion (intervals, velocity changes)
  #
  # ## Encoding Types
  #
  # Each parameter can be encoded as absolute or delta:
  #
  # ### Pitch Encoding
  #
  # **Absolute**:
  # - **abs_grade**: Set grade to specific value
  # - **abs_sharps**: Set chromatic alteration
  # - **abs_octave**: Set octave to specific value
  #
  # **Delta**:
  # - **delta_grade**: Change grade by semitones
  # - **delta_sharps**: Change chromatic alteration
  # - **delta_interval**: Change by scale interval (with delta_interval_sign)
  # - **delta_octave**: Change octave
  #
  # ### Duration Encoding (from {DeltaD})
  #
  # - **abs_duration**: Set duration
  # - **delta_duration**: Add to duration
  # - **factor_duration**: Multiply duration
  #
  # ### Velocity Encoding
  #
  # - **abs_velocity**: Set velocity
  # - **delta_velocity**: Add to velocity
  #
  # ## Natural Keys
  #
  # - **:abs_grade**, **:abs_sharps**, **:abs_octave**: Absolute pitch
  # - **:delta_grade**, **:delta_sharps**, **:delta_interval**, **:delta_interval_sign**, **:delta_octave**: Delta pitch
  # - **:abs_velocity**, **:delta_velocity**: Velocity encoding
  # - **:abs_duration**, **:delta_duration**, **:factor_duration**: Duration encoding
  # - **:modifiers**: Hash of additional modifiers
  #
  # ## Reconstruction
  #
  # Delta events require a previous event for reconstruction:
  #
  #     gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(GDVd)
  #     previous = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(GDV)
  #     gdv = gdvd.to_gdv(scale, previous: previous)
  #     # => { grade: 2, octave: 0, duration: 1.0, velocity: 1 }
  #
  # ## Neuma Delta Notation
  #
  # Delta events use special notation in Neuma format:
  #
  # - **Delta grade**: "+2" or "-2" (semitone change)
  # - **Delta sharps**: "+#" or "-_" (chromatic change)
  # - **Delta octave**: "+o1" or "-o1" (octave change)
  # - **Delta duration**: "+0.5" or "-0.5" (duration change)
  # - **Factor duration**: "*2" or "*0.5" (duration multiply)
  # - **Delta velocity**: "+f" or "-f" (dynamics change)
  #
  # @example First event (absolute encoding)
  #   gdvd = { abs_grade: 0, abs_duration: 1.0, abs_velocity: 0 }.extend(GDVd)
  #   gdvd.base_duration = 1/4r
  #   gdvd.to_neuma  # => "(0 4 mp)"
  #
  # @example Delta encoding (unchanged duration)
  #   gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(GDVd)
  #   gdvd.base_duration = 1/4r
  #   gdvd.to_neuma  # => "(+2 +f)"
  #   # Grade +2 semitones, velocity +1 (one f louder)
  #
  # @example Chromatic change
  #   gdvd = { delta_sharps: 1 }.extend(GDVd)
  #   gdvd.to_neuma  # => "(+#)"
  #   # Add one sharp
  #
  # @example Duration multiplication
  #   gdvd = { factor_duration: 2 }.extend(GDVd)
  #   gdvd.base_duration = 1/4r
  #   gdvd.to_neuma  # => "(. *2)"
  #   # Double duration
  #
  # @example Reconstruction from delta
  #   previous = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(GDV)
  #   gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(GDVd)
  #   scale = Musa::Scales::Scales.et12[440.0].major[60]
  #   gdv = gdvd.to_gdv(scale, previous: previous)
  #   # => { grade: 2, octave: 0, duration: 1.0, velocity: 1 }
  #
  # @example Octave change
  #   gdvd = { delta_grade: -2, delta_octave: 1 }.extend(GDVd)
  #   gdvd.to_neuma  # => "(-2 +o1)"
  #   # Down 2 semitones, up one octave
  #
  # @see GDV Absolute score notation
  # @see DeltaD Delta duration encoding
  # @see DeltaI Delta indexed encoding
  # @see Helper String formatting utilities
  module GDVd
    include DeltaD
    include DeltaI

    include Helper

    using Musa::Extension::InspectNice

    # Natural keys for delta encoding.
    # @return [Array<Symbol>]
    NaturalKeys = (NaturalKeys +
                    [:abs_grade, :abs_sharps, :abs_octave,
                     :delta_grade, :delta_sharps, :delta_interval_sign, :delta_interval, :delta_octave,
                     :abs_velocity, :delta_velocity,
                     :modifiers]).freeze

    # Base duration for time calculations.
    # @return [Rational]
    attr_reader :base_duration

    # Sets base duration, adjusting existing duration values.
    #
    # When base_duration changes, existing abs_duration and delta_duration
    # are scaled proportionally to maintain actual time values.
    #
    # @param value [Rational] new base duration
    #
    # @example
    #   gdvd[:abs_duration] = 1.0
    #   gdvd.base_duration = 1/4r  # abs_duration scaled by factor
    def base_duration=(value)
      factor = value / (@base_duration || 1)
      @base_duration = value

      self[:abs_duration] *= factor if has_key?(:abs_duration)
      self[:delta_duration] *= factor if has_key?(:delta_duration)
    end

    # Reconstructs absolute GDV from delta encoding.
    #
    # Applies delta changes to previous event to create new absolute event.
    # Handles all encoding types (abs_, delta_, factor_) appropriately.
    #
    # @param scale [Musa::Scales::Scale] reference scale for pitch calculations
    # @param previous [GDV] previous absolute event (required for reconstruction)
    #
    # @return [GDV] reconstructed absolute event
    #
    # @example Basic delta reconstruction
    #   previous = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(GDV)
    #   gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(GDVd)
    #   gdv = gdvd.to_gdv(scale, previous: previous)
    #   # => { grade: 2, octave: 0, duration: 1.0, velocity: 1 }
    #
    # @example Absolute override
    #   previous = { grade: 0, duration: 1.0 }.extend(GDV)
    #   gdvd = { abs_grade: 5, abs_duration: 2.0 }.extend(GDVd)
    #   gdv = gdvd.to_gdv(scale, previous: previous)
    #   # => { grade: 5, duration: 2.0 }
    #
    # @example Duration factor
    #   previous = { grade: 0, duration: 1.0 }.extend(GDV)
    #   gdvd = { factor_duration: 2 }.extend(GDVd)
    #   gdv = gdvd.to_gdv(scale, previous: previous)
    #   # => { grade: 0, duration: 2.0 }
    def to_gdv(scale, previous:)
      r = previous.clone.delete_if {|k,_| !GDV::NaturalKeys.include?(k)}.extend GDV

      r.base_duration = @base_duration

      if include?(:abs_grade)
        if self[:abs_grade] == :silence
          r[:silence] = true
        else
          r.delete :silence
          r.delete :sharps

          r[:grade] = scale[self[:abs_grade]].wide_grade
          r[:sharps] = self[:abs_sharps] if include?(:abs_sharps)
        end

      elsif include?(:delta_grade)
        r.delete :silence

        r[:grade], r[:sharps] =
            normalize_to_scale(scale,
                               scale[r[:grade]].wide_grade + self[:delta_grade],
                               (r[:sharps] || 0) + (self[:delta_sharps] || 0))

        r.delete :sharps if r[:sharps].zero?

      elsif include?(:delta_interval)
        r.delete :silence

        sign = self[:delta_interval_sign] || 1

        r[:grade], r[:sharps] =
            normalize_to_scale scale,
                               scale[r[:grade]].wide_grade,
                               sign * scale.kind.tuning.scale_system.intervals[self[:delta_interval]]

        r.delete :sharps if r[:sharps].zero?

      elsif include?(:delta_sharps)
        r.delete :silence

        r[:grade], r[:sharps] =
            normalize_to_scale scale,
                               scale[r[:grade]].wide_grade,
                               (r[:sharps] || 0) + self[:delta_sharps]

        r.delete :sharps if r[:sharps].zero?
      end

      if include?(:abs_octave)
        r[:octave] = self[:abs_octave]
      elsif include?(:delta_octave)
        r[:octave] += self[:delta_octave]
      end

      if include?(:abs_duration)
        r[:duration] = self[:abs_duration]
      elsif include?(:delta_duration)
        r[:duration] += self[:delta_duration]
      elsif include?(:factor_duration)
        r[:duration] *= self[:factor_duration]
      end

      if include?(:abs_velocity)
        r[:velocity] = self[:abs_velocity]
      elsif include?(:delta_velocity)
        r[:velocity] += self[:delta_velocity]
      end

      if include?(:modifiers)
        self[:modifiers].each_pair do |k, v|
          r[k] = v
        end
      end

      (keys - NaturalKeys).each { |k| r[k] = self[k] }

      r
    end

    # Normalizes chromatic pitch to scale note.
    #
    # Converts arbitrary grade + sharps to closest scale note representation.
    # If chromatic, returns background note + chromatic alteration.
    #
    # @param scale [Musa::Scales::Scale] reference scale
    # @param grade [Integer] scale degree (wide grade)
    # @param sharps [Integer] chromatic alteration
    #
    # @return [Array(Integer, Integer)] [normalized_grade, normalized_sharps]
    #
    # @api private
    private def normalize_to_scale(scale, grade, sharps)
      note = scale[grade].sharp(sharps)
      background = note.background_note

      if background
        return background.wide_grade, note.background_sharps
      else
        return note.wide_grade, 0
      end
    end

    # Converts to Neuma delta notation string.
    #
    # Neuma delta format uses special notation for changes:
    #
    #     ([grade_delta] [octave_delta] [duration_delta] [velocity_delta] [modifiers...])
    #
    # - **Grade delta**: "+2" or "-2" (semitone change)
    # - **Sharp delta**: "+#" or "-_" (chromatic change)
    # - **Octave delta**: "+o1" or "-o1" (octave change)
    # - **Duration delta**: "+0.5", "-0.5", or "*2" (duration change)
    # - **Velocity delta**: "+f" or "-f" (dynamics change by f's)
    #
    # @return [String] Neuma delta notation
    #
    # @example Delta grade
    #   gdvd = { delta_grade: 2 }.extend(GDVd)
    #   gdvd.base_duration = 1/4r
    #   gdvd.to_neuma  # => "(+2)"
    #
    # @example Multiple deltas
    #   gdvd = { delta_grade: -2, delta_velocity: 1 }.extend(GDVd)
    #   gdvd.base_duration = 1/4r
    #   gdvd.to_neuma  # => "(-2 +f)"
    #
    # @example Duration factor
    #   gdvd = { factor_duration: 2 }.extend(GDVd)
    #   gdvd.base_duration = 1/4r
    #   gdvd.to_neuma  # => "(. *2)"
    #
    # @example Chromatic change
    #   gdvd = { delta_sharps: 1 }.extend(GDVd)
    #   gdvd.to_neuma  # => "(+#)"
    #
    # @example Absolute values
    #   gdvd = { abs_grade: 0, abs_duration: 1.0 }.extend(GDVd)
    #   gdvd.base_duration = 1/4r
    #   gdvd.to_neuma  # => "(0 4)"
    def to_neuma
      @base_duration ||= Rational(1,4)

      attributes = []

      c = 0

      if include?(:abs_grade)
        attributes[c] = self[:abs_grade].to_s

      elsif include?(:delta_grade)
        attributes[c] = positive_sign_of(self[:delta_grade]) + self[:delta_grade].to_s unless self[:delta_grade].zero?

      elsif include?(:delta_interval)

        attributes[c] = self[:delta_interval_sign] if include?(:delta_interval_sign)
        attributes[c] ||= ''
        attributes[c] += self[:delta_interval].to_s
      end

      if include?(:delta_sharps) && !self[:delta_sharps].zero?
        char = self[:delta_sharps] > 0 ? '#' : '_'
        sign = attributes[c].nil? ? positive_sign_of(self[:delta_sharps]) : ''

        attributes[c] ||= ''
        attributes[c] += sign + char * self[:delta_sharps].abs
      end

      attributes[c] = '.' if attributes[c].nil? || attributes[c].empty?

      if include?(:abs_octave)
        attributes[c += 1] = 'o' + self[:abs_octave].to_s
      elsif include?(:delta_octave)
        attributes[c += 1] = sign_of(self[:delta_octave]) + 'o' + self[:delta_octave].abs.to_s if self[:delta_octave] != 0
      end

      if include?(:abs_duration)
        attributes[c += 1] = (self[:abs_duration] / @base_duration).to_s
      elsif include?(:delta_duration)
        attributes[c += 1] = positive_sign_of(self[:delta_duration]) + (self[:delta_duration] / @base_duration).to_s
      elsif include?(:factor_duration)
        attributes[c += 1] = '*' + self[:factor_duration].to_s
      end

      if include?(:abs_velocity)
        attributes[c += 1] = velocity_of(self[:abs_velocity])
      elsif include?(:delta_velocity)
        attributes[c += 1] = sign_of(self[:delta_velocity]) + 'f' * self[:delta_velocity].abs
      end

      (keys - NaturalKeys).each do |k|
        attributes[c += 1] = modificator_string(k, self[k])
      end

      '(' + attributes.join(' ') + ')'
    end
  end
end
