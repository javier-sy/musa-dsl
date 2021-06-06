require 'spec_helper'

require 'musa-dsl'

# require_relative '../core-ext/with'

class Composer
  using Musa::Extension::Arrayfy

  attr_reader :context

  def initialize(inputs: [:input], outputs: [:output], &block)
    @inputs = inputs
    @outputs = outputs

    @context = Context.new

    @context.with &block
  end

  def update(&block)
    @context.with &block
  end

  class Context
    include Musa::Extension::With

    def initialize
      @pipelines = {}
    end

    def route(from, to:, as: nil)

    end

    def pipeline(name, elements)
      puts "pipeline name = #{name}"
      pp elements

      first = last = nil
      elements.each do |e|
        case e
        when Hash
          if e.size == 1
            operation = e.keys.first
            parameters = e.values.first

            if Musa::Series::Constructors.instance_methods.include?(operation)
              raise ArgumentError, "Called constructor '#{operation}' ignoring previous elements" unless last.nil?
              last = Musa::Series::Constructors.method(operation).call(*parameters)

            elsif Musa::Series::Operations.instance_methods.include?(operation)
              last = Musa::Series::Constructors::HOLDER.new if last.nil?
              last = last.send(operation, *parameters)

            end
          else
            raise ArgumentError, "Don\\'t know how to handle #{e}"
          end
        when Symbol
          operation = e

          if Musa::Series::Operations.instance_methods.include?(operation)
            last = last.send(operation)
          end
        end

        first ||= last
      end

      instance_variable_set "@#{name}", last

      define_singleton_method name do
        instance_variable_get "@#{name}"
      end
    end

    private def method_missing(symbol, *args, &block)
      if Musa::Series::Operations.instance_methods.include?(symbol)
        symbol
      elsif Musa::Series::Constructors.instance_methods.include?(symbol)
        symbol
      else
        raise ArgumentError, "Pipeline '#{symbol}' is undefined" if args.empty?
        pipeline(symbol, args)
      end
    end

    private def respond_to_missing?(method_name, include_private = false)
      Musa::Series::Operations.instance_methods.include?(method_name) ||
        Musa::Series::Constructors.instance_methods.include?(method_name) ||
        @pipelines.has_key?(method_name) ||
        super
    end
  end

  private_constant :Context
end

RSpec.describe Composer do
  context '' do
    it '' do
      x = Composer.new do
        input ({ S: [1, 2, 3, 4, 5] }), { skip: 2 }, reverse, { repeat: 2 }, reverse

        # parte1a reverse, { skip: 2 }, { repeat: 2 }
        # parte1b reverse, { skip: 3 }, { repeat: 3 }
        #
        # parte2 ({ skip: 3 }), { repeat: 2 }
        #
        # route input, to: parte1a
        # route input, to: parte1b
        #
        # route parte1a, to: parte2
        #
        # route parte2, to: output
      end

      ii = x.context.input.i

      while v = ii.next_value
        puts "ii.next_value = #{v}"
      end

      x.inputs[:input] = S(1, 2, 3)
      puts x.outputs[:output].next_value

      # esto...
      x.route :parte1b, to: :parte2
      x.route :input, to: :a

      # debería ser como esto otro...
      x.update do
        route parte1b, to: parte2
        route input, to: a
      end


    end
  end
end