require 'musa-dsl/neuma'

module Musa::Datasets
  module GDVd
    include Musa::Neumalang::Dataset

    NaturalKeys = [:abs_grade, :abs_sharps, :abs_octave,
                   :delta_grade, :delta_sharps, :delta_interval_sign, :delta_interval, :delta_octave,
                   :abs_duration, :delta_duration, :factor_duration,
                   :abs_velocity, :delta_velocity].freeze

    attr_accessor :base_duration

    def to_gdv(scale, previous:)
      r = previous.clone.delete_if {|k,_| !GDV::NaturalKeys.include?(k)}.extend GDV

      r.base_duration = @base_duration

      if include? :abs_grade
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

    def to_neuma(mode = nil)
      mode ||= :dots # :parenthesis

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

      if include?(:abs_octave)
        attributes[c += 1] = 'o' + positive_sign_of(self[:abs_octave]) + self[:abs_octave].to_s
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

      if mode == :dots
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

    module Parser
      class << self
        def parse(expression, base_duration: nil)
          base_duration ||= Rational(1,4)

          neuma = expression.clone

          command = {}.extend GDVd
          command.base_duration = base_duration

          grade = neuma.shift

          if grade && !grade.empty?
            if '+-#_'.include?(grade[0])
              sign, interval, number, sharps = parse_grade(grade)

              sign ||= 1

              command[:delta_grade] = number * sign if number
              command[:delta_sharps] = sharps * sign unless sharps.zero?

              command[:delta_interval] = interval if interval
              command[:delta_interval_sign] = sign if interval && sign && interval
            else
              _, name, number, sharps = parse_grade(grade)

              command[:abs_grade] = name || number
              command[:abs_sharps] = sharps unless sharps.zero?
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

            elsif /\A\/+·*\Z/x.match(duration)
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

        def parse_grade(neuma_grade)
          sign = name = wide_grade = nil
          accidentals = 0

          case neuma_grade
          when Symbol, String
            match = /\A(?<sign>[+|-]?)(?<name>[^[#|_]]*)(?<accidental_sharps>#*)(?<accidental_flats>_*)\Z/.match neuma_grade.to_s

            if match
              sign = (match[:sign] == '-' ? -1 : 1) unless match[:sign].empty?

              if match[:name] == match[:name].to_i.to_s
                wide_grade = match[:name].to_i
              else
                name = match[:name].to_sym unless match[:name].empty?
              end
              accidentals = match[:accidental_sharps].length - match[:accidental_flats].length
            else
              name = neuma_grade.to_sym unless (neuma_grade.nil? || neuma_grade.empty?)
            end
          when Numeric
            wide_grade = neuma_grade.to_i

          else
            raise ArgumentError, "Cannot eval #{neuma_grade} as name or grade position."
          end

          return sign, name, wide_grade, accidentals
        end

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
    end

    class NeumaDifferentialDecoder < Musa::Neumalang::DifferentialDecoder # to get a GDVd
      def initialize(base_duration: nil)
        @base_duration = base_duration || Rational(1,4)
      end

      def parse(expression)
        Parser.parse(expression, base_duration: @base_duration)
      end
    end
  end

  module GDV
    include Musa::Neumalang::Dataset

    NaturalKeys = [:grade, :sharps, :octave, :duration, :velocity, :silence].freeze

    attr_accessor :base_duration

    def to_pdv(scale)
      r = {}.extend Musa::Datasets::PDV
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

      attributes[c += 1] = 'o' + positive_sign_of(self[:octave]) + self[:octave].to_s if self[:octave]
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
      r = {}.extend Musa::Datasets::GDVd
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

    class NeumaDecoder < Musa::Neumalang::Decoder # to get a GDV
      def initialize(scale, base_duration: nil, processor: nil, **base)
        @base_duration = base_duration || Rational(1,4)

        base = { grade: 0, octave: 0, duration: @base_duration, velocity: 1 } if base.empty?

        @scale = scale

        super base, processor: processor
      end

      attr_accessor :scale, :base_duration

      def parse(expression)
        expression = expression.clone

        appogiatura_neuma = expression.find { |_| _.is_a?(Hash) && _[:appogiatura] }
        expression.delete appogiatura_neuma if appogiatura_neuma

        parsed = GDVd::Parser.parse(expression, base_duration: @base_duration)

        if appogiatura_neuma
          appogiatura = GDVd::Parser.parse(appogiatura_neuma[:appogiatura], base_duration: @base_duration)
          parsed[:appogiatura] = appogiatura
        end

        parsed
      end

      def subcontext
        NeumaDecoder.new @scale, base_duration: @base_duration, processor: @processor, **@last
      end

      def apply(action, on:)
        gdv = action.to_gdv @scale, previous: on

        appogiatura_action = action[:appogiatura]
        gdv[:appogiatura] = appogiatura_action.to_gdv @scale, previous: on if appogiatura_action

        gdv
      end

      def inspect
        "GDV NeumaDecoder: @last = #{@last}"
      end

      alias to_s inspect
    end
  end
end
