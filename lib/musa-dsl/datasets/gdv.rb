require 'musa-dsl/neuma'

module Musa::Datasets
  module GDVd # abs_grade abs_octave delta_grade abs_duration delta_duration factor_duration abs_velocity delta_velocity
    include Musa::Neuma::Dataset

    def to_gdv(scale, previous:)
      r = previous.clone.extend GDV

      if self[:abs_grade]
        r[:grade] = if self[:abs_grade] == :silence
                      self[:abs_grade]
                    else
                      scale[self[:abs_grade]].wide_grade
                    end
      elsif self[:delta_grade]
        if r[:grade] == :silence
          # doesn't change silence
        else
          r[:grade] = scale[r[:grade]].wide_grade + self[:delta_grade]
        end
      end

      if self[:abs_octave]
        r[:octave] = self[:abs_octave]
      elsif self[:delta_octave]
        r[:octave] += self[:delta_octave]
      end

      if self[:abs_duration]
        r[:duration] = self[:abs_duration]
      elsif self[:delta_duration]
        r[:duration] += self[:delta_duration]
      elsif self[:factor_duration]
        r[:duration] *= self[:factor_duration]
      end

      if self[:abs_velocity]
        r[:velocity] = self[:abs_velocity]
      elsif self[:delta_velocity]
        r[:velocity] += self[:delta_velocity]
      end

      r
    end

    def to_neuma(mode = nil)
      mode ||= :dotted # :parenthesis

      attributes = []

      c = 0

      if self[:abs_grade]
        attributes[c] = self[:abs_grade].to_s
      elsif self[:delta_grade] && self[:delta_grade] != 0
        attributes[c] = positive_sign_of(self[:delta_grade]) + self[:delta_grade].to_s
      end

      if self[:abs_octave]
        attributes[c += 1] = 'o' + self[:abs_octave].to_s
      elsif self[:delta_octave] && self[:delta_octave] != 0
        attributes[c += 1] = sign_of(self[:delta_octave]) + 'o' + self[:delta_octave].abs.to_s
      end

      if self[:abs_duration]
        attributes[c += 1] = self[:abs_duration].to_s
      elsif self[:delta_duration]
        attributes[c += 1] = positive_sign_of(self[:delta_duration]) + self[:delta_duration].to_s
      elsif self[:factor_duration]
        attributes[c += 1] = '*' + self[:factor_duration].to_s
      end

      if self[:abs_velocity]
        attributes[c += 1] = velocity_of(self[:abs_velocity])
      elsif self[:delta_velocity]
        attributes[c += 1] = sign_of(self[:delta_velocity]) + 'f' * self[:delta_velocity].abs
      end

      if mode == :dotted
        if !attributes.empty?
          attributes.join '.'
        else
          '.'
        end

      elsif mode == :parenthesis
        '<' + attributes.join(', ') + '>'
      else
        attributes
      end
    end

    private

    def positive_sign_of(x)
      x > 0 ? '+' : ''
    end

    def sign_of(x)
      '++-'[x <=> 0]
    end

    def velocity_of(x)
      %w[ppp pp p mp mf f ff fff][x + 3]
    end
  end

  module GDV # grade duration velocity event command
    include Musa::Neuma::Dataset

    def to_pdv(scale)
      r = {}

      if self[:grade]
        r[:pitch] = if self[:grade] == :silence
                      self[:grade]
                    else
                      scale[self[:grade]].octave(self[:octave] || 0).pitch
                    end
      end

      r[:duration] = self[:duration] if self[:duration]

      if self[:velocity]
        # ppp = 16 ... fff = 127
        r[:velocity] = [16, 32, 48, 64, 80, 96, 112, 127][self[:velocity] + 3]
      end

      r.extend Musa::Datasets::PDV
    end

    def to_neuma(mode = nil)
      mode ||= :dotted # :parenthesis

      attributes = []

      c = 0

      attributes[c] = self[:grade].to_s if self[:grade]
      attributes[c += 1] = 'o' + self[:octave].to_s if self[:octave]
      attributes[c += 1] = self[:duration].to_s if self[:duration]
      attributes[c += 1] = velocity_of(self[:velocity]) if self[:velocity]

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
      r = {}.extend Musa::Datasets::GDVd

      if previous

        if self[:grade] == :silence || previous[:grade] == :silence
          r[:abs_grade] = self[:grade]

        elsif self[:grade] && previous[:grade] && (self[:grade] != previous[:grade])
          r[:delta_grade] = scale[self[:grade]].wide_grade - scale[previous[:grade]].wide_grade
        end

        if self[:duration] && previous[:duration] && (self[:duration] != previous[:duration])
          r[:delta_duration] = self[:duration] - previous[:duration]
        end

        if self[:velocity] && previous[:velocity] && (self[:velocity] != previous[:velocity])
          r[:delta_velocity] = self[:velocity] - previous[:velocity]
        end
      else
        r[:abs_grade] = self[:grade] if self[:grade]
        r[:abs_duration] = self[:duration] if self[:duration]
        r[:abs_velocity] = self[:velocity] if self[:velocity]
      end

      r
    end

    module Parser
      def parse(expression)
        neuma = expression.clone

        command = {}.extend GDVd

        grade = neuma.shift

        if grade && !grade.empty?
          if grade[0] == '+' || grade[0] == '-'
            command[:delta_grade] = grade.to_i
          else
            command[:abs_grade] = if grade =~ /^[+-]?[0-9]+$/
                                    grade.to_i
                                  else
                                    grade.to_sym
                                  end
          end
        end

        octave = neuma.find { |a| /\A [+-]?o[-]?[0-9]+ \Z/x.match a }

        if octave
          if (octave[0] == '+' || octave[0] == '-') && octave[1] == 'o'
            command[:delta_octave] = (octave[0] + octave[2..-1]).to_i
          elsif octave[0] == 'o'
            command[:abs_octave] = octave[1..-1].to_i
          end

          neuma.delete octave
        end

        velocity = neuma.find { |a| /\A (mp | mf | (\+|\-)?(p+|f+)) \Z/x.match a }

        if velocity
          if velocity[0] == '+' || velocity[0] == '-'
            command[:delta_velocity] = (velocity[1] == 'f' ? 1 : -1) * (velocity.length - 1) * (velocity[0] + '1').to_i
          elsif velocity[0] == 'm'
            command[:abs_velocity] = velocity[1] == 'f' ? 1 : 0
          else
            command[:abs_velocity] = velocity.length * (velocity[0] == 'f' ? 1 : -1) + (velocity[0] == 'f' ? 1 : 0)
          end

          neuma.delete velocity
        end

        duration = neuma.shift

        if duration && !duration.empty?
          if duration[0] == '+' || duration[0] == '-'
            command[:delta_duration] = duration.to_r

          elsif duration[0] == '*'
            command[:factor_duration] = duration[1..-1].to_r

          else
            command[:abs_duration] = duration.to_r
          end
        end

        command
      end
    end

    private_constant :Parser

    class NeumaDifferentialDecoder < Musa::Neuma::DifferentialDecoder
      include Parser
    end

    class NeumaDecoder < Musa::Neuma::Decoder
      include Parser

      def initialize(scale, base = nil)
        base ||= { grade: 0, octave: 0, duration: Rational(1, 4), velocity: 1 }

        @scale = scale

        super base
      end

      def subcontext
        NeumaDecoder.new @scale, @last
      end

      def apply(action, on:)
        action.to_gdv @scale, previous: on
      end

      def inspect
        "GDV NeumaDecoder: @last = #{@last}"
      end

      alias to_s inspect
    end
  end
end
