require_relative 'delta-d'
require_relative 'gdv'

require_relative 'helper'

module Musa::Datasets
  module GDVd
    include DeltaD
    include DeltaI

    include Helper

    NaturalKeys = (NaturalKeys +
                    [:abs_grade, :abs_sharps, :abs_octave,
                     :delta_grade, :delta_sharps, :delta_interval_sign, :delta_interval, :delta_octave,
                     :abs_velocity, :delta_velocity,
                     :modifiers]).freeze

    attr_reader :base_duration

    def base_duration=(value)
      factor = value / (@base_duration || 1)
      @base_duration = value

      self[:abs_duration] *= factor if has_key?(:abs_duration)
      self[:delta_duration] *= factor if has_key?(:delta_duration)
    end

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

    def normalize_to_scale(scale, grade, sharps)
      note = scale[grade].sharp(sharps)
      background = note.background_note

      if background
        return background.wide_grade, note.background_sharps
      else
        return note.wide_grade, 0
      end
    end

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
        attributes[c += 1] = sign_of(self[:delta_octave]) + 'o' + self[:delta_octave].abs.to_s if  self[:delta_octave] != 0
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
