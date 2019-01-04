require 'musa-dsl/neuma'

module Musa::Datasets
  module GDVd # abs_grade abs_octave delta_grade abs_duration delta_duration factor_duration abs_velocity delta_velocity
    include Musa::Neuma::Dataset

    NaturalKeys = [:abs_grade, :delta_grade,
                   :abs_octave, :delta_octave,
                   :abs_duration, :delta_duration, :factor_duration,
                   :abs_velocity, :delta_velocity].freeze

    attr_accessor :base_duration

    def to_gdv(scale, previous:)
      r = previous.clone.delete_if {|k,_| !GDV::NaturalKeys.include?(k)}.extend GDV

      r.base_duration = @base_duration

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

      (keys - NaturalKeys).each { |k| r[k] = self[k] }

      r
    end

    def to_neuma(mode = nil)
      mode ||= :dotted # :parenthesis

      @base_duration ||= Rational(1,4)

      attributes = []

      c = 0

      if self[:abs_grade]
        attributes[c] = self[:abs_grade].to_s
      elsif self[:delta_grade]
        attributes[c] = positive_sign_of(self[:delta_grade]) + self[:delta_grade].to_s if self[:delta_grade] != 0
      end

      if self[:abs_octave]
        attributes[c += 1] = 'o' + positive_sign_of(self[:abs_octave]) + self[:abs_octave].to_s
      elsif self[:delta_octave]
        attributes[c += 1] = sign_of(self[:delta_octave]) + 'o' + self[:delta_octave].abs.to_s if  self[:delta_octave] != 0
      end

      if self[:abs_duration]
        attributes[c += 1] = (self[:abs_duration] / @base_duration).to_s
      elsif self[:delta_duration]
        attributes[c += 1] = positive_sign_of(self[:delta_duration]) + (self[:delta_duration] / @base_duration).to_s
      elsif self[:factor_duration]
        attributes[c += 1] = '*' + self[:factor_duration].to_s
      end

      if self[:abs_velocity]
        attributes[c += 1] = velocity_of(self[:abs_velocity])
      elsif self[:delta_velocity]
        attributes[c += 1] = sign_of(self[:delta_velocity]) + 'f' * self[:delta_velocity].abs
      end

      (keys - NaturalKeys).each do |k|
        attributes[c += 1] = case self[k]
                             when String
                               "\"#{self[k]}\""
                             when Numeric
                               "#{self[k]}"
                             when Symbol
                               ":#{self[k]}"
                             end
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
      x >= 0 ? '+' : ''
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

    NaturalKeys = [:grade, :octave, :duration, :velocity].freeze

    attr_accessor :base_duration

    def to_pdv(scale)
      r = {}.extend Musa::Datasets::PDV
      r.base_duration = @base_duration

      if self[:grade]
        r[:pitch] = if self[:grade] == :silence
                      self[:grade]
                    else
                      scale[self[:grade]].octave(self[:octave] || 0).pitch
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

      attributes[c] = self[:grade].to_s if self[:grade]
      attributes[c += 1] = 'o' +  positive_sign_of(self[:octave]) + self[:octave].to_s if self[:octave]
      attributes[c += 1] = (self[:duration] / @base_duration).to_s if self[:duration]
      attributes[c += 1] = velocity_of(self[:velocity]) if self[:velocity]

      (keys - NaturalKeys).each do |k|
        attributes[c += 1] = case self[k]
                             when String
                               "\"#{self[k]}\""
                             when Numeric
                               "#{self[k]}"
                             when Symbol
                               ":#{self[k]}"
                             end
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
      r = {}.extend Musa::Datasets::GDVd
      r.base_duration = @base_duration

      if previous
        if self[:grade] == :silence || previous[:grade] == :silence
          r[:abs_grade] = self[:grade]

        elsif self[:grade] && previous[:grade] && (self[:grade] != previous[:grade])
          r[:delta_grade] = scale[self[:grade]].wide_grade - scale[previous[:grade]].wide_grade
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

    private

    def positive_sign_of(x)
      x >= 0 ? '+' : ''
    end

    module Parser
      def _parse(expression, base_duration: nil)
        base_duration ||= Rational(1,4)

        neuma = expression.clone

        command = {}.extend GDVd
        command.base_duration = base_duration

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

        octave = neuma.reject {|a| a.is_a?(Hash)}.find { |a| /\A[+-]?o[+-]?[0-9]+\Z/x.match a }

        if octave
          if (octave[0] == '+' || octave[0] == '-') && octave[1] == 'o'
            command[:delta_octave] = (octave[0] + octave[2..-1]).to_i
          elsif octave[0] == 'o'
            command[:abs_octave] = octave[1..-1].to_i
          end

          neuma.delete octave
        end

        to_delete = velocity = neuma.select {|a| a.is_a?(Hash)}.find { |a| /\A(mp | mf | (\+|\-)?(p+|f+))\Z/x.match a[:modifier] }
        velocity = velocity[:modifier].to_s if velocity

        velocity ||= to_delete = neuma.reject {|a| a.is_a?(Hash)}.find { |a| /\A(mp | mf | (\+|\-)?(p+|f+))\Z/x.match a }

        if velocity
          if velocity[0] == '+' || velocity[0] == '-'
            command[:delta_velocity] = (velocity[1] == 'f' ? 1 : -1) * (velocity.length - 1) * (velocity[0] + '1').to_i
          elsif velocity[0] == 'm'
            command[:abs_velocity] = velocity[1] == 'f' ? 1 : 0
          else
            command[:abs_velocity] = velocity.length * (velocity[0] == 'f' ? 1 : -1) + (velocity[0] == 'f' ? 1 : 0)
          end

          neuma.delete to_delete
        end

        duration = neuma.reject {|a| a.is_a?(Hash)}.first

        if duration && !duration.empty?
          if duration[0] == '+' || duration[0] == '-'
            command[:delta_duration] = (duration[0] == '-' ? -1 : 1) * eval_duration(duration[1..-1]) * base_duration

          elsif /\A[\/]+[\·]*\Z/x.match(duration)
            command[:abs_duration] = eval_duration(duration) * base_duration

          elsif duration[0] == '*'
            command[:factor_duration] = eval_duration(duration[1..-1])

          elsif duration[0] == '/'
            command[:factor_duration] = Rational(1, eval_duration(duration[1..-1]))

          else
            command[:abs_duration] = eval_duration(duration) * base_duration
          end
        end

        neuma.delete duration if duration

        neuma.select {|a| a.is_a?(Hash)}.each do |a|
          command[a[:modifier]] = a[:parameters] || true
        end

        raise EncodingError, "Neuma #{neuma} cannot be decoded" unless neuma.reject {|a| a.is_a?(Hash)}.size.zero?

        command
      end

      private

      def eval_duration(string)
        # format: ///···
        #
        if match = /\A(?<slashes>\/+)(?<dots>\·*)\Z/x.match(string)
          base = Rational(1, 2**match[:slashes].length.to_r)
          dots_extension = 0
          match[:dots].length.times do |i|
            dots_extension += Rational(base, 2**(i+1))
          end

          base + dots_extension

        # format: 1··
        #
        elsif match = /\A(?<number>\d*\/?\d+?)(?<dots>\·*)\Z/x.match(string)
          base = match[:number].to_r
          dots_extension = 0
          match[:dots].length.times do |i|
            dots_extension += Rational(base, 2**(i+1))
          end

          base + dots_extension

        else
          string.to_r
        end
      end
    end

    private_constant :Parser

    class NeumaDifferentialDecoder < Musa::Neuma::DifferentialDecoder
      include Parser

      def initialize(base_duration: nil)
        @base_duration = base_duration || Rational(1,4)
      end

      def parse(expression)
        _parse(expression, base_duration: @base_duration)
      end
    end

    class NeumaDecoder < Musa::Neuma::Decoder
      include Parser

      def initialize(scale, base_duration: nil, **base)
        @base_duration = base_duration || Rational(1,4)

        base = { grade: 0, octave: 0, duration: @base_duration, velocity: 1 } if base.empty?

        @scale = scale

        super base
      end

      def parse(expression)
        _parse(expression, base_duration: @base_duration)
      end

      def subcontext
        NeumaDecoder.new @scale, base_duration: @base_duration, **@last
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
