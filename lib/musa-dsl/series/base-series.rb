require_relative '../core-ext/deep-copy'
require_relative '../generative/generative-grammar'

module Musa
  module Series
    module Constructors; extend self; end
    module Operations; end

    include Constructors

    module Serie
      def self.base
        Module.new do
          include SerieImplementation

          def has_source; false; end
          private def mandatory_source; false; end

          def has_sources; false; end
          private def mandatory_sources; false; end
        end
      end

      def self.with(source: false,
                    source_as: nil,
                    private_source: nil,
                    mandatory_source: nil,
                    sources: false,
                    sources_as: nil,
                    private_sources: nil,
                    mandatory_sources: nil,
                    smart_block: false,
                    block: false,
                    block_as: nil)

        source_as ||= :source
        source_setter = (source_as.to_s + '=').to_sym
        _mandatory_source = source if mandatory_source.nil?

        sources_as ||= :sources
        sources_setter = (sources_as.to_s + '=').to_sym
        _mandatory_sources = sources if mandatory_sources.nil?

        block_as ||= :proc
        block_setter = (block_as.to_s + '=').to_sym

        Module.new do
          include SerieImplementation

          if source
            private def has_source; true; end
            define_method(:mandatory_source) { _mandatory_source }
            private :mandatory_source

            define_method source_as do
              @source
            end

            define_method source_setter do |serie|
              unless @source.nil? || @source.undefined? || serie.state == @source.state
                raise ArgumentError, "New serie for #{source_as} should be a #{@state} instead of a #{serie.state}"
              end

              @source = serie
              mark_regarding! @source
            end

            if private_source
              private source_as
              private source_setter
            end
          else
            private def has_source; false; end
            private def mandatory_source; false; end
          end

          if sources
            private def has_sources; true; end
            define_method(:mandatory_sources) { _mandatory_sources }
            private :mandatory_source

            define_method sources_as do
              @sources
            end

            define_method sources_setter do |series|
              unless series.is_a?(Hash) || series.is_a?(Array)
                raise ArgumentError, "New series for #{sources_as} should be a Hash or an Array instead of a #{series.class.name}"
              end

              @sources = series
              try_to_resolve_undefined_state_if_needed
            end

            if private_sources
              private sources_as
              private sources_setter
            end
          else
            private def has_sources; false; end
            private def mandatory_sources; false; end
          end

          if smart_block
            define_method block_as do |&block|
              if block
                @block = Extension::SmartProcBinder::SmartProcBinder.new(block)
              else
                @block.proc
              end
            end

            define_method block_setter do |block|
              @block = Extension::SmartProcBinder::SmartProcBinder.new(block)
            end

          elsif block
            define_method block_as do |&block|
              if block
                @block = block
              else
                @block
              end
            end

            define_method block_setter do |block|
              @block = block
            end
          end
        end
      end

      module Prototyping
        def state
          try_to_resolve_undefined_state_if_needed
          @state || :undefined
        end

        def prototype?
          try_to_resolve_undefined_state_if_needed
          @state&.==(:prototype)
        end

        def instance?
          try_to_resolve_undefined_state_if_needed
          @state&.==(:instance)
        end

        def undefined?
          try_to_resolve_undefined_state_if_needed
          @state.nil? || @state == :undefined
        end

        def defined?
          !undefined?
        end

        def prototype
          try_to_resolve_undefined_state_if_needed

          if prototype?
            self
          elsif instance?
            # if the series has been directly created as an instance (i.e., because is an operation over an instance)
            # the prototype doesn't exist.
            #
            @instance_of
          else
            raise PrototypingError, 'Can\'t get the prototype of an undefined serie'
          end
        end

        alias_method :p, :prototype

        def instance
          try_to_resolve_undefined_state_if_needed

          if instance?
            self
          elsif prototype?
            new_instance = clone

            new_instance._instance!
            new_instance.mark_as_instance!(self)
            new_instance.init if new_instance.respond_to?(:init)

            new_instance
          else
            raise PrototypingError, 'Can\'t get an instance of an undefined serie'
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

          case @sources
          when Array
            @sources = @sources.collect(&:prototype)
          when Hash
            @sources = @sources.transform_values(&:prototype)
          end
        end

        protected def _instance!
          @source = @source.instance if @source

          case @sources
          when Array
            @sources = @sources.collect(&:instance)
          when Hash
            @sources = @sources.transform_values(&:instance)
          end
        end

        protected def mark_as!(state)
          case state
          when nil, :undefined
            mark_as_undefined!
          when :prototype
            mark_as_prototype!
          when :instance
            mark_as_instance!
          else
            raise ArgumentError, "Unexpected state #{state}. Only accepted nil, :undefined, :prototype or :instance."
          end
        end

        protected def mark_regarding!(source)
          if source.nil? || source.undefined?
            mark_as_undefined!
          elsif source.prototype?
            mark_as_prototype!
          elsif source.instance?
            mark_as_instance!
          end
        end

        protected def mark_as_undefined!
          @state = :undefined
          self
        end

        protected def mark_as_prototype!
          notify = @state != :prototype

          @state = :prototype

          _sources_resolved if notify
          self
        end

        protected def mark_as_instance!(prototype = nil)
          notify = @state != :instance

          @state = :instance
          @instance_of = prototype

          _sources_resolved if notify
          self
        end

        protected def _sources_resolved; end

        private def try_to_resolve_undefined_state_if_needed

          return unless @state.nil? || @state == :undefined

          states = []

          if has_source
            if mandatory_source
              states << @source&.state || :undefined
            elsif @source
              states << @source.state
            end
          end

          if has_sources
            sources = case @sources
                      when Array
                        @sources
                      when Hash
                        @sources.values
                      when nil
                        []
                      end

            undefined_sources =
              sources.empty? ||
                sources.any?(&:undefined?) ||
                sources.any?(&:instance?) && sources.any?(&:prototype?)

            instance_sources = sources.all?(&:instance?) unless undefined_sources

            sources_state = if undefined_sources
                              :undefined
                            elsif instance_sources
                              :instance
                            else
                              :prototype
                            end

            if mandatory_sources
              states << sources_state
            elsif !(@sources.nil? || @sources.empty?)
              states << sources_state
            end
          end

          # in case of having source and sources, if both states are equal the final state is that one, else the final state is undefined
          #
          new_state = states.first if states.first == states.last
          new_state ||= :undefined

          mark_as!(new_state)
        end

        class PrototypingError < RuntimeError
          def initialize(message = nil)
            message ||= 'This serie is a prototype serie: cannot be consumed. To consume the serie use an instance serie via .instance method'
            super message
          end
        end
      end

      module SerieImplementation
        include Serie
        include Prototyping
        include Operations

        using Musa::Extension::DeepCopy

        def init
          @_have_peeked_next_value = false
          @_peeked_next_value = nil
          @_have_current_value = false
          @_current_value = nil

          _init

          self
        end

        private def _init; end

        def restart(...)
          check_state_permissions
          init
          _restart(...)

          self
        end

        private def _restart; end

        def next_value
          check_state_permissions

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

        private def _next_value; end

        alias_method :v, :next_value

        def peek_next_value
          check_state_permissions

          if !@_have_peeked_next_value
            @_have_peeked_next_value = true
            @_peeked_next_value = _next_value
          end

          @_peeked_next_value
        end

        def current_value
          check_state_permissions

          @_current_value
        end

        def infinite?
          check_state_permissions(allows_prototype: true)
          @source&.infinite? || false
        end

        def to_a(duplicate: nil, recursive: nil, restart: nil, dr: nil)
          check_state_permissions(allows_prototype: true)
          raise 'Cannot convert to array an infinite serie' if infinite?

          recursive ||= false

          dr = instance? if dr.nil?

          duplicate = dr if duplicate.nil?
          restart = dr if restart.nil?

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

        def to_node(**attributes)
          Nodificator.to_node(self, **attributes)
        end

        alias_method :node, :to_node

        private def check_state_permissions(allows_prototype: nil)
          try_to_resolve_undefined_state_if_needed

          raise PrototypingError if !allows_prototype && prototype?

          unless instance? || prototype?
            raise PrototypingError, 'This serie is in undefined state: cannot be consumed. To consume the serie be sure the serie\'s sources are all in a defined state.'
          end
        end

        class Nodificator
          extend Musa::GenerativeGrammar

          def self.to_node(serie, **attributes)
            N(serie, **attributes)
          end
        end

        private_constant :Nodificator
      end

      private_constant :SerieImplementation
    end
  end
end
