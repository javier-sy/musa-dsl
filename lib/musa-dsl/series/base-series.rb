require_relative '../core-ext/deep-copy'
require_relative '../generative/generative-grammar'

using Musa::Extension::DeepCopy

module Musa
  module Series
    module Constructors; extend self; end
    module Operations; end

    include Constructors

    module SeriePrototyping
      def prototype?
        @is_instance ? false : true
      end

      def instance?
        @is_instance ? true : false
      end

      def prototype
        if @is_instance
          @instance_of || (@instance_of = clone._prototype!.mark_as_prototype!)
        else
          self
        end
      end

      alias_method :p, :prototype

      def instance
        if @is_instance
          self
        else
          clone(freeze: false)._instance!.mark_as_instance!(self).tap(&:restart)
        end
      end

      alias_method :i, :instance

      # By default, if there is a @source attribute that contains the source of the serie, SeriePrototyping will
      # handle prototyping/instancing automatically.
      # If there is a @sources attribute with the eventual several sources, SeriePrototyping will handle them by
      # default.
      # If needed the subclasses can override this behaviour to accommodate to real subclass specificities.
      #
      protected def _prototype!
        @source = @source.prototype if @source

        if @sources
          if @sources.is_a?(Array)
            @sources = @sources.collect(&:prototype)
          elsif @sources.is_a?(Hash)
            @sources = @sources.transform_values(&:prototype)
          end
        end

        self
      end

      protected def _instance!
        @source = @source.instance if @source

        if @sources
          if @sources.is_a?(Array)
            @sources = @sources.collect(&:instance)
          elsif @sources.is_a?(Hash)
            @sources = @sources.transform_values(&:instance)
          end
        end

        self
      end

      protected def mark_regarding!(source)
        if source.prototype?
          mark_as_prototype!
        else
          mark_as_instance!
        end
      end

      protected def mark_as_prototype!
        @is_instance = nil
        self
      end

      protected def mark_as_instance!(prototype = nil)
        @instance_of = prototype
        @is_instance = true
        self
      end

      class PrototypingSerieError < RuntimeError
        def initialize(message = nil)
          message ||= 'This serie is a prototype serie: cannot be consumed. To consume the serie use an instance serie via .instance method'
          super message
        end
      end
    end

    module Serie
      include SeriePrototyping
      include Operations

      def restart
        raise PrototypingSerieError unless @is_instance

        @_have_peeked_next_value = false
        @_peeked_next_value = nil
        @_have_current_value = false
        @_current_value = nil

        _restart if respond_to? :_restart

        self
      end

      def next_value
        raise PrototypingSerieError unless @is_instance

        unless @_have_current_value && @_current_value.nil?
          if @_have_peeked_next_value
            @_have_peeked_next_value = false
            @_current_value = @_peeked_next_value
          else
            @_current_value = _next_value
          end
        end

        @_current_value
      end

      alias_method :v, :next_value

      def peek_next_value
        raise PrototypingSerieError unless @is_instance

        if !@_have_peeked_next_value
          @_have_peeked_next_value = true
          @_peeked_next_value = _next_value
        end

        @_peeked_next_value
      end

      def current_value
        raise PrototypingSerieError unless @is_instance

        @_current_value
      end

      def infinite?
        false
      end

      def to_a(recursive: nil, duplicate: nil, restart: nil, dr: nil)
        recursive ||= false

        dr ||= instance?

        duplicate = dr if duplicate.nil?
        restart = dr if restart.nil?

        raise 'Cannot convert to array an infinite serie' if infinite?

        array = []

        serie = instance

        serie = serie.clone(deep: true) if duplicate
        serie = serie.restart if restart

        while value = serie.next_value
          array << if recursive
                     process_for_to_a(value)
                   else
                     value
                   end
        end

        array
      end

      alias_method :a, :to_a

      def to_node(**attributes)
        Nodificator.to_node(self, **attributes)
      end

      alias_method :node, :to_node

      class Nodificator
        extend Musa::GenerativeGrammar

        def self.to_node(serie, **attributes)
          N(serie, **attributes)
        end
      end

      private_constant :Nodificator

      private def process_for_to_a(value)
        case value
        when Serie
          value.to_a(recursive: true, restart: false, duplicate: false)
        when Array
          a = value.clone
          a.collect! { |v| v.is_a?(Serie) ? v.to_a(recursive: true, restart: false, duplicate: false) : process_for_to_a(v) }
        when Hash
          h = value.clone
          h.transform_values! { |v| v.is_a?(Serie) ? v.to_a(recursive: true, restart: false, duplicate: false) : process_for_to_a(v) }
        else
          value
        end
      end
    end
  end
end
