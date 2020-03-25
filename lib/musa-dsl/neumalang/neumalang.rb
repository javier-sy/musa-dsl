require 'citrus'

require_relative '../series'
require_relative '../neumas'

module Musa
  module Neumalang
    module Neumalang
      module Parser
        module Sentences
          include Musa::Series
          include Musa::Neumas

          def value
            _SE(captures(:expression).collect(&:value), extends: Neuma::Serie)
          end
        end

        module BracketedBarSentences
          include Musa::Series
          include Musa::Neumas

          def value
            { kind: :parallel,
              parallel: [{ kind: :serie, serie: S(*capture(:aa).value) }] + captures(:bb).collect { |c| { kind: :serie, serie: S(*c.value) } }
            }.extend(Neuma::Parallel)
          end
        end

        module BracketedSentences
          include Musa::Series
          include Musa::Neumas

          def value
            { kind: :serie,
              serie: S(*capture(:sentences).value) }.extend Neuma
          end
        end

        module ReferenceExpression
          include Musa::Neumas

          def value
            { kind: :reference,
              reference: capture(:expression).value }.extend Neuma
          end
        end

        module VariableAssign
          include Musa::Neumas

          def value
            { kind: :assign_to,
              assign_to: captures(:use_variable).collect { |c| c.value[:use_variable] }, assign_value: capture(:expression).value
            }.extend Neuma
          end
        end

        module Event
          include Musa::Neumas

          def value
            { kind: :event,
              event: capture(:name).value.to_sym
            }.merge(capture(:parameters) ? capture(:parameters).value : {}).extend Neuma
          end
        end

        module Parameters
          def value
            value_parameters = []
            key_value_parameters = {}

            captures(:parameter).each do |pp|
              p = pp.value
              if p.has_key? :key_value
                key_value_parameters.merge! p[:key_value]
              else
                value_parameters << p[:value]
              end
            end

            {}.tap do |_|
              _[:value_parameters] = value_parameters unless value_parameters.empty?
              _[:key_parameters] = key_value_parameters unless key_value_parameters.empty?
            end
          end
        end

        module Parameter
          def value
            if capture(:key_value_parameter)
              { key_value: capture(:key_value_parameter).value }
            else
              { value: capture(:expression).value }
            end
          end
        end

        module BracedCommand
          include Musa::Neumas

          def value
            { kind: :command,
              command: eval("proc { #{capture(:complex_command).value.strip} }")
            }.merge(capture(:parameters) ? capture(:parameters).value : {}).extend Neuma
          end
        end

        module CallMethodsExpression
          include Musa::Neumas

          def value
            { kind: :call_methods,
              call_methods: captures(:method_call).collect(&:value),
              on: capture(:object_expression).value }.extend Neuma
          end
        end

        module UseVariable
          include Musa::Neumas

          def value
            { kind: :use_variable,
              use_variable: "@#{capture(:name).value}".to_sym }.extend Neuma
          end
        end

        module NeumaAsAttributes
          include Musa::Neumas

          def value
            h = Hash.new

            capture(:grade)&.value&.tap { |_| h.merge! _ if _ }
            capture(:octave)&.value&.tap { |_| h.merge! _ if _ }
            capture(:duration)&.value&.tap { |_| h.merge! _ if _ }
            capture(:velocity)&.value&.tap { |_| h.merge! _ if _ }

            h[:modifiers] = {} unless captures(:modifiers).empty?
            captures(:modifiers).collect(&:value).each { |_| h[:modifiers].merge! _ if _ }

            { kind: :neuma, neuma: h }.extend Neuma
          end
        end

        module DeltaGradeAttribute
          def value

            value = {}

            sign = capture(:sign)&.value || 1

            value[:delta_grade] = capture(:grade).value * sign if capture(:grade)
            value[:delta_sharps] = capture(:accidentals).value * sign if capture(:accidentals)

            value[:delta_interval] = capture(:interval).value if capture(:interval)
            value[:delta_interval_sign] = sign if capture(:interval) && capture(:sign)

            value
          end
        end

        module AbsGradeAttribute
          def value
            value = {}

            value[:abs_grade] = capture(:grade).value if capture(:grade)
            value[:abs_grade] ||= capture(:interval).value.to_sym if capture(:interval)

            value[:abs_sharps] = capture(:accidentals).value if capture(:accidentals)

            value
          end
        end

        module DurationCalculation
          def duration
            base = capture(:number)&.value

            slashes = capture(:slashes)&.value || 0
            base ||= Rational(1, 2**slashes.to_r)

            dots_extension = 0
            capture(:mid_dots)&.value&.times do |i|
              dots_extension += Rational(base, 2**(i+1))
            end

            base + dots_extension
          end
        end

        module DeltaDurationAttribute
          include DurationCalculation

          def value
            sign = capture(:sign).value

            { delta_duration: sign * duration }
          end
        end

        module AbsDurationAttribute
          include DurationCalculation

          def value
            { abs_duration: duration }
          end
        end

        module FactorDurationAttribute
          def value
            { factor_duration: capture(:number).value ** (capture(:factor).value == '/' ? -1 : 1) }
          end
        end

        module AbsVelocityAttribute
          def value
            if capture(:p)
              v = -capture(:p).length
            elsif capture(:mp)
              v = 0
            elsif capture(:mf)
              v = 1
            else
              v = capture(:f).length + 1
            end

            { abs_velocity: v }
          end
        end

        module DeltaVelocityAttribute
          def value
            d = capture(:delta).value
            s = capture(:sign).value

            if /p+/.match?(d)
              v = -d.length
            else
              v = d.length
            end

            { delta_velocity: s * v }
          end
        end

        module AppogiaturaNeuma
          def value
            capture(:base).value.tap do |_|
              _[:neuma][:modifiers] ||= {}
              _[:neuma][:modifiers][:appogiatura] = capture(:appogiatura).value[:neuma]
            end
          end
        end

        module Symbol
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:name).value.to_sym }.extend Neuma
          end
        end

        module String
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:everything_except_double_quote).value }.extend Neuma
          end
        end

        module Float
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:raw_float).value }.extend Neuma
          end
        end

        module RawFloat
          def value
            "#{capture(:minus)&.value}#{capture(:a).value}.#{capture(:b).value}".to_f
          end
        end

        module Integer
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:raw_integer).value }.extend Neuma
          end
        end

        module Rational
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:raw_rational).value }.extend Neuma
          end
        end
      end

      extend self

      def register(grammar_path)
        Citrus.load grammar_path
      end

      def parse(string_or_file, language: nil, decode_with: nil, debug: nil)
        language ||= ::NeumalangGrammar

        match = nil

        if string_or_file.is_a? String
          match = language.parse string_or_file

        elsif string_or_file.is_a? File
          match = language.parse string_or_file.read

        else
          raise ArgumentError, 'Only String or File allowed to be parsed'
        end

        match.dump if debug

        serie = match.value

        if decode_with
          serie.eval do |e|
            if e[:kind] == :neuma
              decode_with.decode(e[:neuma])
            else
              raise ArgumentError, "Don't know how to convert #{e} to neumas"
            end
          end
        else
          serie
        end
      end

      def parse_file(filename, decode_with: nil, debug: nil)
        File.open filename do |file|
          parse file, decode_with: decode_with, debug: debug
        end
      end

      register File.join(File.dirname(__FILE__), 'neumalang')
    end
  end
end
