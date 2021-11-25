require_relative 'e'
require_relative 'gdvd'
require_relative 'pdv'

require_relative 'helper'

module Musa::Datasets
  module GDV
    using Musa::Extension::InspectNice

    include AbsD

    include Helper

    NaturalKeys = (NaturalKeys + [:grade, :sharps, :octave, :velocity, :silence]).freeze

    attr_accessor :base_duration

    # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
    # ppp = 16 ... fff = 127 (-5 ... 4) the standard used by Musescore 3 and others starts at ppp = 16
    VELOCITY_MAP = [1, 8, 16, 33, 49, 64, 80, 96, 112, 127].freeze

    def to_pdv(scale)
      pdv = {}.extend PDV
      pdv.base_duration = @base_duration

      if self[:grade]
        pdv[:pitch] = if self[:silence]
                        :silence
                      else
                        scale[self[:grade]].sharp(self[:sharps] || 0).octave(self[:octave] || 0).pitch
                      end
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
            attributes[c] += '_' * self[:sharps]
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

    def velocity_of(x)
      %w[ppp pp p mp mf f ff fff][x + 3]
    end

    private :velocity_of

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
                scale[self[:grade]].octave(self[:octave]).wide_grade -
                scale[previous[:grade]].octave(previous[:octave]).wide_grade

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
        gdvd[:abs_grade] = self[:grade] if self[:grade]
        gdvd[:abs_duration] = self[:duration] if self[:duration]
        gdvd[:abs_velocity] = self[:velocity] if self[:velocity]
      end

      (keys - NaturalKeys).each { |k| gdvd[k] = self[k] }

      gdvd
    end
  end
end
