require 'citrus'

require_relative '../series'
require_relative '../neumas'
require_relative '../datasets'

module Musa
  module Neumalang
    module Neumalang
      module Parser
        module Grammar; end

        module Sentences
          def value
            Musa::Series::Constructors.S(*captures(:expression).collect(&:value)).extend(Musa::Neumas::Neuma::Serie)
          end
        end

        module BracketedBarSentences
          def value
            { kind: :parallel,
              parallel: [{ kind: :serie,
                           serie: Musa::Series::Constructors.S(*capture(:aa).value) }] +
                                  captures(:bb).collect { |c| { kind: :serie, serie: Musa::Series::Constructors.S(*c.value) } }
            }.extend(Musa::Neumas::Neuma::Parallel)
          end
        end

        module BracketedSentences
          def value
            { kind: :serie,
              serie: Musa::Series::Constructors.S(*capture(:sentences).value) }.extend Musa::Neumas::Neuma
          end
        end

        module ReferencedBracedCommand
          def value
            { kind: :command_reference,
              command: capture(:braced_command).value }.extend Musa::Neumas::Neuma
          end
        end

        module VariableAssign
          def value
            { kind: :assign_to,
              assign_to: captures(:use_variable).collect { |c| c.value[:use_variable] },
              assign_value: capture(:expression).value
            }.extend Musa::Neumas::Neuma
          end
        end

        module Event
          def value
            { kind: :event,
              event: capture(:name).value.to_sym
            }.merge(capture(:parameters) ? capture(:parameters).value : {}).extend Musa::Neumas::Neuma
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

              _[:proc_parameter] = capture(:codeblock).value if capture(:codeblock)
            end
          end
        end

        module Codeblock
          def value
            { codeblock:
                capture(:braced_command)&.value ||
                  capture(:referenced_braced_command)&.value ||
                  capture(:use_variable)&.value }
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
          def value
            { kind: :command,
              command: eval("proc { #{capture(:complex_command).value.strip} }")
            }.merge(capture(:parameters) ? capture(:parameters).value : {}).extend Musa::Neumas::Neuma
          end
        end

        module CallMethodsExpression
          def value
            { kind: :call_methods,
              call_methods: captures(:method_call).collect(&:value),
              on: capture(:object_expression).value }.extend Musa::Neumas::Neuma
          end
        end

        module UseVariable
          def value
            { kind: :use_variable,
              use_variable: "@#{capture(:name).value}".to_sym }.extend Musa::Neumas::Neuma
          end
        end

        module NeumaAsAttributes
          def value
            h = {}.extend Musa::Datasets::GDVd

            capture(:grade)&.value&.tap { |_| h.merge! _ if _ }
            capture(:octave)&.value&.tap { |_| h.merge! _ if _ }
            capture(:duration)&.value&.tap { |_| h.merge! _ if _ }
            capture(:velocity)&.value&.tap { |_| h.merge! _ if _ }

            h[:modifiers] = {} unless captures(:modifiers).empty?
            captures(:modifiers).collect(&:value).each { |_| h[:modifiers].merge! _ if _ }

            { kind: :gdvd, gdvd: h }.extend Musa::Neumas::Neuma
          end
        end

        module PackedVector
          def value
            { kind: :packed_v, packed_v: capture(:raw_packed_vector).value }.extend(Musa::Neumas::Neuma)
          end
        end

        module RawPackedVector
          def value
            captures(:key_value).collect(&:value).to_h.extend(Musa::Datasets::PackedV)
          end
        end

        module Vector
          def value
            { kind: :v, v: capture(:raw_vector).value }.extend(Musa::Neumas::Neuma)
          end
        end

        module RawVector
          def value
            captures(:raw_number).collect(&:value).extend(Musa::Datasets::V)
          end
        end

        module ProcessOfVectors
          def value
            durations_rest = []
            i = 0

            rests = captures(:rest).collect(&:value)
            captures(:durations).collect(&:value).each do |duration|
              durations_rest[i * 2] = duration
              durations_rest[i * 2 + 1] = rests[i]
              i += 1
            end

            p = ([ capture(:first).value ] + durations_rest).extend(Musa::Datasets::P)
            { kind: :p, p: p }.extend(Musa::Neumas::Neuma)
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

        module DeltaOctaveAttribute
          def value
            { delta_octave: capture(:sign).value * capture(:number).value }
          end
        end

        module AbsOctaveAttribute
          def value
            { abs_octave: capture(:number).value }
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
              _[:gdvd][:modifiers] ||= {}
              _[:gdvd][:modifiers][:appogiatura] = capture(:appogiatura).value[:gdvd]
            end
          end
        end

        module Symbol
          def value
            { kind: :value,
              value: capture(:name).value.to_sym }.extend Musa::Neumas::Neuma
          end
        end

        module String
          def value
            { kind: :value,
              value: capture(:everything_except_double_quote).value }.extend Musa::Neumas::Neuma
          end
        end

        module Number
          def value
            { kind: :value,
              value: capture(:raw_number).value }.extend Musa::Neumas::Neuma
          end
        end

        module Special
          def value
            v = captures(0)
            { kind: :value,
              value: v == 'nil' ? nil : (v == 'true' ? true : false) }.extend Musa::Neumas::Neuma
          end
        end
      end

      extend self

      def parse(string_or_file, decode_with: nil, debug: nil)
        case string_or_file
        when String
          match = Parser::Grammar::Grammar.parse string_or_file

        when File
          match = Parser::Grammar::Grammar.parse string_or_file.read

        else
          raise ArgumentError, 'Only String or File allowed to be parsed'
        end

        match.dump if debug

        serie = match.value

        if decode_with
          serie.eval do |e|
            if e[:kind] == :gdvd
              decode_with.decode(e[:gdvd])
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

      Citrus.load File.join(File.dirname(__FILE__), 'terminals.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'datatypes.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'neuma.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'vectors.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'process.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'neumalang.citrus')
    end
  end
end
