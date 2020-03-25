require_relative 'd'
require_relative 'gdvd'
require_relative 'pdv'

require_relative 'helper'

module Musa::Datasets
  module GDV
    include D

    include Helper

    NaturalKeys = (NaturalKeys + [:grade, :sharps, :octave, :velocity, :silence, :effective_duration]).freeze

    attr_accessor :base_duration

    def to_pdv(scale)
      r = {}.extend PDV
      r.base_duration = @base_duration

      if self[:grade]
        r[:pitch] = if self[:silence]
                      :silence
                    else
                      scale[self[:grade]].sharp(self[:sharps] || 0).octave(self[:octave] || 0).pitch
                    end
      end

      if self[:duration]
        r[:duration] = self[:duration]
      end

      if self[:velocity]
        # ppp = 16 ... fff = 127
        r[:velocity] = [16, 32, 48, 64, 80, 96, 112, 127][self[:velocity] + 3]
      end

      (keys - NaturalKeys).each { |k| r[k] = self[k] }

      r
    end

    def to_neuma(mode = nil)
      mode ||= :dotted # :parenthesis

      @base_duration ||= Rational(1,4)

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
            attributes[c] += '_' * self[:sharps]
          end
        end
      end

      attributes[c += 1] = 'o' + self[:octave].to_s if self[:octave]
      attributes[c += 1] = (self[:duration] / @base_duration).to_s if self[:duration]
      attributes[c += 1] = velocity_of(self[:velocity]) if self[:velocity]

      (keys - NaturalKeys).each do |k|
        attributes[c += 1] = modificator_string(k, self[k])
      end

      if mode == :dotted
        attributes.join '.'

      elsif mode == :parenthesis
        '(' + attributes.join(', ') + ')'
      else
        attributes
      end
    end

    def velocity_of(x)
      %w[ppp pp p mp mf f ff fff][x + 3]
    end

    private :velocity_of

    def to_gdvd(scale, previous: nil)
      r = {}.extend GDVd
      r.base_duration = @base_duration

      if previous

        if include?(:silence)
          r[:abs_grade] = :silence

        elsif include?(:grade) && !previous.include?(:grade)
          r[:abs_grade] = self[:grade]
          r[:abs_sharps] = self[:sharps]

        elsif include?(:grade) && previous.include?(:grade)
          if self[:grade] != previous[:grade] ||
            (self[:sharps] || 0) != (previous[:sharps] || 0)

            r[:delta_grade] = scale[self[:grade]].octave(self[:octave]).wide_grade - scale[previous[:grade]].octave(previous[:octave]).wide_grade
            r[:delta_sharps] = (self[:sharps] || 0) - (previous[:sharps] || 0)
          end
        elsif include?(:sharps)
          r[:delta_sharps] = self[:sharps] - (previous[:sharps] || 0)
        end

        if self[:duration] && previous[:duration] && (self[:duration] != previous[:duration])
          r[:delta_duration] = (self[:duration] - previous[:duration])
        end

        if self[:velocity] && previous[:velocity] && (self[:velocity] != previous[:velocity])
          r[:delta_velocity] = self[:velocity] - previous[:velocity]
        end
      else
        r[:abs_grade] = self[:grade] if self[:grade]
        r[:abs_duration] = self[:duration] if self[:duration]
        r[:abs_velocity] = self[:velocity] if self[:velocity]
      end

      (keys - NaturalKeys).each { |k| r[k] = self[k] }

      r
    end
  end
end
