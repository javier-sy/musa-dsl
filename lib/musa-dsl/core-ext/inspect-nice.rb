module Musa
  module Extension
    module InspectNice
      refine Hash do
        def inspect
          all = collect { |key, value| [', ', key.is_a?(Symbol) ? key.to_s + ': ' : key.inspect + ' => ', value.inspect] }.flatten
          all.shift
          '{ ' + all.join + ' }'
        end

        alias _to_s to_s
        alias to_s inspect
      end

      refine Rational do
        def inspect(simple: nil)
          value = self.abs
          sign = negative? ? '-' : ''

          if simple
            if value.denominator == 1
              "#{sign}#{value.numerator}"
            else
              "#{sign}#{value.numerator}/#{value.denominator}"
            end
          else
            sign2 = negative? ? '-' : '+'

            d = value - value.to_i

            if d == 0
              "#{sign}#{value.to_i.to_s}r"
            else
              i = "#{value.to_i}#{sign2}" if value.to_i != 0
              "#{sign}#{i}#{d.numerator}/#{d.denominator}r"
            end
          end
        end

        def to_s
          inspect simple: true
        end
      end
    end
  end
end
