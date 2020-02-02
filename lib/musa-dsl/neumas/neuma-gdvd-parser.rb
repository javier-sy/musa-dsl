module Musa::Neumas
  module Decoder
    module Parser
      extend self

      def parse(expression, base_duration: nil)
        base_duration ||= Rational(1,4)

        neuma = expression.clone

        command = {}.extend Musa::Dataset::GDVd
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
end
