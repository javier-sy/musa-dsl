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
            _SE(captures(:sentence).collect(&:value), extends: Neuma::Serie)
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

        module NeumaAsDottedAttributesBeginningWithSimpleAttribute
          include Musa::Neumas

          def value
            { kind: :neuma,
              neuma: (capture(:a) ? [capture(:a).value] : []) + captures(:b).collect(&:value) }.extend Neuma
          end
        end

        module NeumaAsDottedAttributesBeginningWithDot
          include Musa::Neumas

          def value
            { kind: :neuma,
              neuma: (capture(:attribute) ? [ nil ] : []) + captures(:attribute).collect(&:value) }.extend Neuma
          end
        end

        module NeumaBetweenParenthesisAttributes
          include Musa::Neumas

          def value
            { kind: :neuma,
              neuma: (capture(:simple_attribute) ? [capture(:simple_attribute).value] : []) + captures(:attribute).collect(&:value) }.extend Neuma
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
              value: capture(:str).value.to_f }.extend Neuma
          end
        end

        module Integer
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:digits).value.to_i }.extend Neuma
          end
        end

        module Rational
          include Musa::Neumas

          def value
            { kind: :value,
              value: capture(:str).value.to_r }.extend Neuma
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
