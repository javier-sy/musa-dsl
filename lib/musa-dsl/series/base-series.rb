require_relative '../core-ext/deep-copy'
require_relative '../generative/generative-grammar'

module Musa
  # Core Serie infrastructure providing prototype/instance system and base implementation.
  #
  # This module defines the fundamental architecture for all Series in Musa DSL:
  #
  # ## Core Concepts
  #
  # ### Prototype/Instance Pattern
  #
  # Series use a **prototype/instance pattern** to enable reusable series definitions:
  #
  # - **Prototype**: Template/blueprint for series (cannot be consumed)
  # - **Instance**: Cloned copy ready for consumption (can call next_value)
  # - **Undefined**: Series with unresolved dependencies
  #
  # ### Serie States
  #
  # Every serie exists in one of three states:
  #
  # - **:prototype** - Template state, cannot consume, can create instances
  # - **:instance** - Active state, can consume values, has independent state
  # - **:undefined** - Unresolved state, cannot use until dependencies resolve
  #
  # ### Why Prototype/Instance?
  #
  # Enables **reusable series definitions** without re-evaluating constructors:
  #
  # ```ruby
  # # Define once (prototype)
  # melody = S(60, 64, 67, 72)
  #
  # # Use multiple times (instances)
  # voice1 = melody.instance  # Independent playback
  # voice2 = melody.instance  # Separate playback
  # ```
  #
  # ## Integration
  #
  # Series integrate with:
  #
  # - **Sequencer**: Play series over time via play() method
  # - **Generative**: Use with generative grammars
  # - **MIDI**: Generate MIDI events from series
  # - **Datasets**: Use AbsTimed, AbsD for timing
  #
  # ## Module Architecture
  #
  # ### Serie Module
  #
  # Factory module providing:
  #
  # - **Serie.base**: Base module without source/sources
  # - **Serie.with**: Configurable module with source/sources/block
  #
  # ### Prototyping Module
  #
  # Implements prototype/instance lifecycle:
  #
  # - State management (:prototype, :instance, :undefined)
  # - Cloning (prototype -> instance)
  # - State resolution from sources
  # - Validation and permissions
  #
  # ### SerieImplementation Module
  #
  # Core iteration protocol:
  #
  # - **init**: Initialize instance state
  # - **restart**: Reset to beginning
  # - **next_value**: Consume next element
  # - **peek_next_value**: Look ahead without consuming
  # - **current_value**: Last consumed value
  #
  # ## Serie Protocol
  #
  # All series must implement:
  #
  # ```ruby
  # def _next_value
  #   # Return next value or nil when finished
  # end
  #
  # def _init
  #   # Initialize instance state (optional)
  # end
  #
  # def _restart
  #   # Reset to beginning (optional)
  # end
  # ```
  #
  # ## Usage Patterns
  #
  # ### Basic Prototype/Instance
  #
  # ```ruby
  # # Create prototype
  # proto = S(1, 2, 3)
  # proto.prototype?  # => true
  #
  # # Create instance
  # inst = proto.instance  # or proto.i
  # inst.instance?  # => true
  #
  # # Consume values
  # inst.next_value  # => 1
  # inst.next_value  # => 2
  # ```
  #
  # ### Multiple Instances
  #
  # ```ruby
  # proto = S(1, 2, 3)
  #
  # a = proto.i
  # b = proto.i  # Independent instance
  #
  # a.next_value  # => 1
  # b.next_value  # => 1 (independent)
  # ```
  #
  # ### State Resolution
  #
  # ```ruby
  # proxy = PROXY()  # Undefined - no source yet
  # proxy.undefined?  # => true
  #
  # proxy.source = S(1, 2, 3)  # Becomes prototype
  # proxy.prototype?  # => true
  # ```
  #
  # ## Technical Details
  #
  # ### Peek Mechanism
  #
  # `peek_next_value` uses internal buffering to look ahead without state change:
  #
  # ```ruby
  # s = S(1, 2, 3).i
  # s.peek_next_value  # => 1 (buffered)
  # s.peek_next_value  # => 1 (same)
  # s.next_value       # => 1 (consumes buffered)
  # ```
  #
  # ### Source/Sources Pattern
  #
  # Series can depend on:
  #
  # - **source**: Single upstream serie
  # - **sources**: Multiple upstream series (Array or Hash)
  #
  # State automatically resolves based on dependencies:
  #
  # - All sources :prototype → :prototype
  # - All sources :instance → :instance
  # - Mixed or undefined → :undefined
  #
  # ### Deep Copy Support
  #
  # Uses Musa::Extension::DeepCopy for proper cloning including nested structures.
  #
  # ## Applications
  #
  # - Reusable melodic/harmonic patterns
  # - Multiple voices from single definition
  # - Lazy evaluation of algorithmic sequences
  # - Composable transformations
  # - Memory-efficient sequence playback
  #
  # @see Musa::Series::Constructors Serie constructor methods
  # @see Musa::Series::Operations Serie transformation operations
  #
  # @api public
  module Series
    # Series constructor methods.
    #
    # @api public
    module Constructors; extend self; end

    # Serie transformation operations.
    #
    # @api public
    module Operations; end

    include Constructors

    # Serie mixins for building serie implementations.
    #
    # Provides composable modules for serie classes:
    #
    # - {Base} - Core functionality without dependencies
    # - {WithSource} - Single upstream serie dependency
    # - {WithSources} - Multiple upstream serie dependencies
    # - {WithBlock} - Simple proc storage
    # - {WithSmartBlock} - SmartProcBinder-wrapped proc
    #
    # ## Usage Pattern
    #
    # ```ruby
    # class MySerie
    #   include Serie::Base
    #   include Serie::WithSource
    #
    #   def initialize(source)
    #     self.source = source
    #     init
    #     mark_as_prototype!
    #   end
    #
    #   private def _next_value
    #     @source.next_value&.transform
    #   end
    # end
    # ```
    #
    # ## Custom Accessor Names
    #
    # Use `alias` to create custom accessor names:
    #
    # ```ruby
    # class MySerie
    #   include Serie::Base
    #   include Serie::WithSource
    #   alias upstream source
    #   alias upstream= source=
    # end
    # ```
    #
    # @see Base Core serie module
    # @see WithSource Single source dependency
    # @see WithSources Multiple sources dependency
    # @see WithBlock Simple proc storage
    # @see WithSmartBlock SmartProcBinder-wrapped proc
    # @see Prototyping Prototype/instance state management
    module Serie
      # Prototype/instance state management for Series.
      #
      # Implements the prototype/instance pattern enabling reusable serie
      # definitions. Every serie exists in one of three states:
      #
      # ## States
      #
      # - **:prototype** - Template state, cannot consume, can create instances
      # - **:instance** - Active state, can consume values, has independent state
      # - **:undefined** - Unresolved state, dependencies not yet resolved
      #
      # ## State Queries
      #
      # ```ruby
      # serie.state        # => :prototype | :instance | :undefined
      # serie.prototype?   # => true if prototype
      # serie.instance?    # => true if instance
      # serie.undefined?   # => true if undefined
      # ```
      #
      # ## State Transitions
      #
      # ### Prototype Creation
      #
      # Created by constructors (S, E, RND, etc.):
      #
      # ```ruby
      # proto = S(1, 2, 3)
      # proto.prototype?  # => true
      # ```
      #
      # ### Instance Creation
      #
      # Via `.instance` (or `.i` alias):
      #
      # ```ruby
      # inst = proto.instance
      # inst.instance?  # => true
      # ```
      #
      # ### State Resolution
      #
      # Undefined series resolve state from sources:
      #
      # ```ruby
      # proxy = PROXY()  # Undefined
      # proxy.source = S(1, 2, 3)  # Becomes prototype
      # ```
      #
      # ## Cloning Behavior
      #
      # Creating instance clones the serie and all dependencies:
      #
      # ```ruby
      # proto = S(1, 2, 3).map { |x| x * 2 }
      # inst = proto.instance  # Clones both map and S
      # ```
      #
      # ## Validation
      #
      # Operations check state permissions:
      # - `next_value`, `restart` require :instance
      # - `infinite?`, `to_a` allow :prototype
      # - Undefined state raises PrototypingError
      #
      # ## Musical Applications
      #
      # - Reusable melodic patterns
      # - Multiple independent playbacks
      # - Lazy definition of transformations
      # - Memory-efficient pattern libraries
      #
      # @api private
      module Prototyping
        # Returns current state of serie.
        #
        # Attempts to resolve undefined state from sources before returning.
        # State is one of: :prototype, :instance, or :undefined.
        #
        # @return [Symbol] current state (:prototype, :instance, :undefined)
        #
        # @api public
        def state
          try_to_resolve_undefined_state_if_needed
          @state || :undefined
        end

        # Checks if serie is in prototype state.
        #
        # @return [Boolean] true if prototype, false otherwise
        #
        # @api public
        def prototype?
          try_to_resolve_undefined_state_if_needed
          @state&.==(:prototype)
        end

        # Checks if serie is in instance state.
        #
        # @return [Boolean] true if instance, false otherwise
        #
        # @api public
        def instance?
          try_to_resolve_undefined_state_if_needed
          @state&.==(:instance)
        end

        # Checks if serie is in undefined state.
        #
        # @return [Boolean] true if undefined, false otherwise
        #
        # @api public
        def undefined?
          try_to_resolve_undefined_state_if_needed
          @state.nil? || @state == :undefined
        end

        # Checks if serie state is defined (not undefined).
        #
        # @return [Boolean] true if prototype or instance, false if undefined
        #
        # @api public
        def defined?
          !undefined?
        end

        # Returns prototype of serie.
        #
        # - If already prototype, returns self
        # - If instance, returns original prototype (if available)
        # - If undefined, raises PrototypingError
        #
        # @return [Serie] prototype serie
        #
        # @raise [PrototypingError] if serie is undefined
        #
        # @example Get prototype
        #   proto = S(1, 2, 3)
        #   inst = proto.instance
        #   inst.prototype  # => proto
        #
        # @api public
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

        # Short alias for {#prototype}.
        #
        # @return [Serie] prototype serie
        #
        # @api public
        alias_method :p, :prototype

        # Creates or returns instance of serie.
        #
        # - If already instance, returns self
        # - If prototype, creates new instance by cloning
        # - If undefined, raises PrototypingError
        #
        # ## Cloning Process
        #
        # 1. Clones serie structure
        # 2. Marks clone as :instance
        # 3. Propagates instance creation to sources
        # 4. Calls init if defined
        #
        # Each call creates independent instance with separate state.
        #
        # @return [Serie] instance serie
        #
        # @raise [PrototypingError] if serie is undefined
        #
        # @example Create instances
        #   proto = S(1, 2, 3)
        #   a = proto.instance
        #   b = proto.instance  # Different instance
        #
        #   a.next_value  # => 1
        #   b.next_value  # => 1 (independent)
        #
        # @api public
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

        # Short alias for {#instance}.
        #
        # @return [Serie] instance serie
        #
        # @api public
        alias_method :i, :instance

        # Converts serie and dependencies to prototype state.
        #
        # Called automatically during cloning. By default, handles +@source+ and
        # +@sources+ attributes automatically. Subclasses can override to add
        # custom prototyping logic.
        #
        # ## Default Behavior
        #
        # - Calls +.prototype+ on +@source+ if present
        # - Calls +.prototype+ on all +@sources+ elements (Array or Hash)
        #
        # @return [void]
        #
        # @api private
        protected def _prototype!
          @source = @source.prototype if @source

          case @sources
          when Array
            @sources = @sources.collect(&:prototype)
          when Hash
            @sources = @sources.transform_values(&:prototype)
          end
        end

        # Converts serie and dependencies to instance state.
        #
        # Called automatically during instance creation. By default, handles
        # +@source+ and +@sources+ attributes automatically. Subclasses can
        # override to add custom instancing logic.
        #
        # ## Default Behavior
        #
        # - Calls +.instance+ on +@source+ if present
        # - Calls +.instance+ on all +@sources+ elements (Array or Hash)
        #
        # @return [void]
        #
        # @api private
        protected def _instance!
          @source = @source.instance if @source

          case @sources
          when Array
            @sources = @sources.collect(&:instance)
          when Hash
            @sources = @sources.transform_values(&:instance)
          end
        end

        # Marks serie with specified state.
        #
        # @param state [Symbol, nil] desired state (:prototype, :instance, :undefined, nil)
        #
        # @return [void]
        #
        # @raise [ArgumentError] if state is not recognized
        #
        # @api private
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

        # Marks serie state based on source state.
        #
        # Propagates state from source:
        # - Source nil/undefined → mark as undefined
        # - Source prototype → mark as prototype
        # - Source instance → mark as instance
        #
        # @param source [Serie, nil] source serie
        #
        # @return [void]
        #
        # @api private
        protected def mark_regarding!(source)
          if source.nil? || source.undefined?
            mark_as_undefined!
          elsif source.prototype?
            mark_as_prototype!
          elsif source.instance?
            mark_as_instance!
          end
        end

        # Marks serie as undefined.
        #
        # @return [Serie] self
        #
        # @api private
        protected def mark_as_undefined!
          @state = :undefined
          self
        end

        # Marks serie as prototype.
        #
        # Calls _sources_resolved if state changed.
        #
        # @return [Serie] self
        #
        # @api private
        protected def mark_as_prototype!
          notify = @state != :prototype

          @state = :prototype

          _sources_resolved if notify
          self
        end

        # Marks serie as instance.
        #
        # Calls _sources_resolved if state changed.
        #
        # @param prototype [Serie, nil] original prototype
        #
        # @return [Serie] self
        #
        # @api private
        protected def mark_as_instance!(prototype = nil)
          notify = @state != :instance

          @state = :instance
          @instance_of = prototype

          _sources_resolved if notify
          self
        end

        # Hook called when sources are resolved to defined state.
        #
        # Subclasses can override to perform actions when state becomes
        # defined (e.g., validate configuration, initialize caches).
        #
        # @return [void]
        #
        # @api private
        protected def _sources_resolved; end

        # Attempts to resolve undefined state from sources.
        #
        # Called automatically before state queries. Resolves state based on
        # +@source+ and +@sources+ dependencies:
        #
        # - All sources :prototype → :prototype
        # - All sources :instance → :instance
        # - Mixed or any undefined → :undefined
        #
        # @return [void]
        #
        # @api private
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

        # Error raised when serie is used in wrong state.
        #
        # Raised when attempting to consume a prototype serie or perform
        # operations on undefined serie.
        #
        # ## Common Scenarios
        #
        # - Calling `next_value` on prototype
        # - Calling `restart` on prototype
        # - Using undefined serie
        #
        # ## Solution
        #
        # Call `.instance` (or `.i`) to create consumable instance:
        #
        # ```ruby
        # proto = S(1, 2, 3)
        # proto.next_value  # => PrototypingError
        #
        # inst = proto.instance
        # inst.next_value  # => 1
        # ```
        #
        # @api public
        class PrototypingError < RuntimeError
          # Creates prototyping error with message.
          #
          # @param message [String, nil] custom error message
          #
          # @api public
          def initialize(message = nil)
            message ||= 'This serie is a prototype serie: cannot be consumed. To consume the serie use an instance serie via .instance method'
            super message
          end
        end
      end

      # Core serie implementation providing iteration protocol.
      #
      # Includes all serie functionality:
      # - Serie module (marker interface)
      # - Prototyping (prototype/instance pattern)
      # - Operations (transformations)
      #
      # ## Iteration Protocol
      #
      # Implements standard protocol for all series:
      #
      # ```ruby
      # serie.init          # Initialize/reset state
      # serie.restart       # Reset to beginning
      # serie.next_value    # Get next value
      # serie.peek_next_value  # Look ahead
      # serie.current_value    # Last value
      # ```
      #
      # ## Subclass Requirements
      #
      # Subclasses must implement:
      #
      # ```ruby
      # def _next_value
      #   # Return next value or nil when finished
      # end
      # ```
      #
      # Optional hooks:
      #
      # ```ruby
      # def _init
      #   # Initialize instance state
      # end
      #
      # def _restart
      #   # Reset to beginning
      # end
      # ```
      #
      # ## Peek Buffering
      #
      # `peek_next_value` buffers one value ahead without advancing state:
      #
      # - First peek: calls _next_value and buffers result
      # - Subsequent peeks: returns buffered value
      # - Next next_value: consumes buffered value
      #
      # @api private
      module SerieImplementation
        include Serie
        include Prototyping
        include Operations

        using Musa::Extension::DeepCopy

        # Initializes instance state.
        #
        # Called automatically when creating instance. Resets:
        # - Peek buffer
        # - Current value cache
        # - Calls subclass _init hook
        #
        # @return [Serie] self
        #
        # @example Automatic initialization
        #   inst = S(1, 2, 3).instance  # init called
        #
        # @api public
        def init
          @_have_peeked_next_value = false
          @_peeked_next_value = nil
          @_have_current_value = false
          @_current_value = nil

          _init

          self
        end

        # Subclass hook for custom initialization.
        #
        # Override to initialize instance-specific state (e.g., counters,
        # buffers, internal series).
        #
        # @return [void]
        #
        # @api private
        private def _init; end

        # Restarts serie to beginning.
        #
        # Resets serie to initial state as if freshly created. Calls init
        # and subclass _restart hook.
        #
        # @return [Serie] self
        #
        # @raise [PrototypingError] if serie is not instance
        #
        # @example Restart series
        #   s = S(1, 2, 3).i
        #   s.next_value  # => 1
        #   s.next_value  # => 2
        #   s.restart
        #   s.next_value  # => 1
        #
        # @api public
        def restart(...)
          check_state_permissions
          init
          _restart(...)

          self
        end

        # Subclass hook for custom restart logic.
        #
        # Override to reset subclass-specific state beyond what init handles.
        #
        # @return [void]
        #
        # @api private
        private def _restart; end

        # Gets next value from serie.
        #
        # Advances serie to next element and returns it. Returns nil when
        # serie is exhausted. Once nil is returned, subsequent calls continue
        # returning nil.
        #
        # ## Peek Integration
        #
        # If peek_next_value was called, consumes peeked value instead of
        # calling _next_value again.
        #
        # @return [Object, nil] next value or nil if exhausted
        #
        # @raise [PrototypingError] if serie is not instance
        #
        # @example Basic iteration
        #   s = S(1, 2, 3).i
        #   s.next_value  # => 1
        #   s.next_value  # => 2
        #   s.next_value  # => 3
        #   s.next_value  # => nil
        #
        # @api public
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

        # Subclass implementation of value generation.
        #
        # Must be implemented by subclasses. Should return next value or nil
        # when serie is exhausted.
        #
        # @return [Object, nil] next value or nil if finished
        #
        # @api private
        private def _next_value; end

        # Short alias for {#next_value}.
        #
        # @return [Object, nil] next value
        #
        # @api public
        alias_method :v, :next_value

        # Peeks at next value without consuming it.
        #
        # Looks ahead to see what next_value will return, but doesn't advance
        # serie state. Multiple peeks return same value. Next next_value call
        # will consume peeked value.
        #
        # @return [Object, nil] next value that will be returned
        #
        # @raise [PrototypingError] if serie is not instance
        #
        # @example Peek ahead
        #   s = S(1, 2, 3).i
        #   s.peek_next_value  # => 1
        #   s.peek_next_value  # => 1 (same)
        #   s.next_value       # => 1
        #   s.peek_next_value  # => 2
        #
        # @api public
        def peek_next_value
          check_state_permissions

          if !@_have_peeked_next_value
            @_have_peeked_next_value = true
            @_peeked_next_value = _next_value
          end

          @_peeked_next_value
        end

        # Returns last consumed value.
        #
        # Returns value from most recent next_value call, or nil if
        # next_value hasn't been called yet.
        #
        # @return [Object, nil] last consumed value
        #
        # @raise [PrototypingError] if serie is not instance
        #
        # @example Track current
        #   s = S(1, 2, 3).i
        #   s.current_value  # => nil
        #   s.next_value     # => 1
        #   s.current_value  # => 1
        #
        # @api public
        def current_value
          check_state_permissions

          @_current_value
        end

        # Checks if serie is infinite.
        #
        # Returns true if serie never exhausts (e.g., generators, cycles).
        # Prototypes allowed for this query.
        #
        # @return [Boolean] true if infinite, false if finite
        #
        # @api public
        def infinite?
          check_state_permissions(allows_prototype: true)
          @source&.infinite? || false
        end

        # Converts serie to array by consuming all values.
        #
        # Creates instance, optionally duplicates/restarts it, consumes all
        # values, and returns them as array. Raises error if serie is infinite.
        #
        # ## Options
        #
        # - **duplicate**: Clone serie before consuming (default: based on dr)
        # - **recursive**: Convert nested Series to arrays (default: false)
        # - **restart**: Restart before consuming (default: based on dr)
        # - **dr**: Shorthand for duplicate+restart (default: true if instance)
        #
        # @param duplicate [Boolean, nil] clone before consuming
        # @param recursive [Boolean, nil] convert nested Series
        # @param restart [Boolean, nil] restart before consuming
        # @param dr [Boolean, nil] duplicate and restart shorthand
        #
        # @return [Array] array of all values
        #
        # @raise [RuntimeError] if serie is infinite
        # @raise [PrototypingError] if prototype and allows_prototype: false
        #
        # @example Basic conversion
        #   proto = S(1, 2, 3)
        #   proto.to_a  # => [1, 2, 3]
        #
        # @example Preserve instance
        #   inst = S(1, 2, 3).i
        #   inst.to_a(duplicate: true)  # Consumes copy, inst unchanged
        #
        # @example Recursive conversion
        #   s = S(S(1, 2), S(3, 4))
        #   s.to_a(recursive: true)  # => [[1, 2], [3, 4]]
        #
        # @api public
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

        # Short alias for {#to_a}.
        #
        # @return [Array] array of all values
        #
        # @api public
        alias_method :a, :to_a

        # Recursively converts series in value to arrays.
        #
        # Helper for to_a with recursive: true. Converts Serie values to
        # arrays and recursively processes Arrays and Hashes.
        #
        # @param value [Object] value to process
        #
        # @return [Object] processed value with Series converted to arrays
        #
        # @api private
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

        # Converts serie to generative grammar node.
        #
        # Creates Node wrapper for use in generative grammar system. Nodes
        # can be used in generative rules and substitutions.
        #
        # @param attributes [Hash] additional node attributes
        #
        # @return [Node] generative grammar node wrapping serie
        #
        # @see Musa::GenerativeGrammar
        #
        # @api public
        def to_node(**attributes)
          Nodificator.to_node(self, **attributes)
        end

        # Short alias for {#to_node}.
        #
        # @return [Node] generative grammar node
        #
        # @api public
        alias_method :node, :to_node

        # Validates serie state before operation.
        #
        # Checks if serie is in valid state for requested operation. Raises
        # PrototypingError if:
        # - Serie is undefined
        # - Serie is prototype and allows_prototype is false
        #
        # @param allows_prototype [Boolean, nil] allow prototype state
        #
        # @return [void]
        #
        # @raise [PrototypingError] if state is invalid for operation
        #
        # @api private
        private def check_state_permissions(allows_prototype: nil)
          try_to_resolve_undefined_state_if_needed

          raise PrototypingError if !allows_prototype && prototype?

          unless instance? || prototype?
            raise PrototypingError, 'This serie is in undefined state: cannot be consumed. To consume the serie be sure the serie\'s sources are all in a defined state.'
          end
        end

        # Helper class for converting Series to generative grammar nodes.
        #
        # Extends GenerativeGrammar to provide N() constructor for creating
        # nodes from series.
        #
        # @api private
        class Nodificator
          extend Musa::GenerativeGrammar

          # Converts serie to node using GenerativeGrammar#N.
          #
          # @param serie [Serie] serie to wrap
          # @param attributes [Hash] node attributes
          #
          # @return [Node] generative grammar node
          #
          # @api private
          def self.to_node(serie, **attributes)
            N(serie, **attributes)
          end
        end

        private_constant :Nodificator
      end

      private_constant :SerieImplementation

      # Base module for all Serie implementations.
      #
      # Provides the core Serie functionality without source or block support.
      # Include this module in classes that don't need source dependencies.
      #
      # @example Basic usage
      #   class MySerie
      #     include Serie::Base
      #
      #     def initialize
      #       init
      #       mark_as_prototype!
      #     end
      #
      #     private def _next_value
      #       # implementation
      #     end
      #   end
      #
      # @see WithSource For series with single source dependency
      # @see WithSources For series with multiple source dependencies
      module Base
        include SerieImplementation

        private def has_source; false; end
        private def mandatory_source; false; end
        private def has_sources; false; end
        private def mandatory_sources; false; end
      end

      # Mixin for series with single source dependency.
      #
      # Provides `source` and `source=` accessors for series that depend on
      # one upstream source serie.
      #
      # @example Usage
      #   class ProcessorSerie
      #     include Serie::Base
      #     include Serie::WithSource
      #
      #     def initialize(source)
      #       self.source = source
      #       init
      #     end
      #   end
      #
      # @example Custom accessor name using alias
      #   class MyCustomSerie
      #     include Serie::Base
      #     include Serie::WithSource
      #     alias my_source source
      #     alias my_source= source=
      #   end
      #
      # @see WithSources For multiple source dependencies
      module WithSource
        private def has_source; true; end
        private def mandatory_source; true; end

        # @return [Serie, nil] the upstream source serie
        def source
          @source
        end

        # Sets the source serie.
        #
        # @param serie [Serie] source serie (must match current state)
        # @raise [ArgumentError] if state mismatch between source and this serie
        def source=(serie)
          unless @source.nil? || @source.undefined? || serie.state == @source.state
            raise ArgumentError, "New serie for source should be a #{@state} instead of a #{serie.state}"
          end
          @source = serie
          mark_regarding! @source
        end
      end

      # Mixin for series with multiple source dependencies.
      #
      # Provides `sources` and `sources=` accessors for series that depend on
      # multiple upstream series (as Array or Hash).
      #
      # @example Usage with Array
      #   class MergeSerie
      #     include Serie::Base
      #     include Serie::WithSources
      #
      #     def initialize(*series)
      #       self.sources = series
      #       init
      #     end
      #   end
      #
      # @example Usage with Hash
      #   class NamedSourcesSerie
      #     include Serie::Base
      #     include Serie::WithSources
      #
      #     def initialize(melody:, rhythm:)
      #       self.sources = { melody: melody, rhythm: rhythm }
      #       init
      #     end
      #   end
      #
      # @see WithSource For single source dependency
      module WithSources
        private def has_sources; true; end
        private def mandatory_sources; true; end

        # @return [Array<Serie>, Hash{Symbol => Serie}, nil] upstream source series
        def sources
          @sources
        end

        # Sets the sources series.
        #
        # @param series [Array<Serie>, Hash{Symbol => Serie}] source series
        # @raise [ArgumentError] if series is not a Hash or Array
        def sources=(series)
          unless series.is_a?(Hash) || series.is_a?(Array)
            raise ArgumentError, "New series for sources should be a Hash or an Array instead of a #{series.class.name}"
          end
          @sources = series
          send(:try_to_resolve_undefined_state_if_needed)
        end
      end

      # Mixin for series with block/proc attribute (simple version).
      #
      # Provides `proc` accessor for series that use a Proc directly
      # without SmartProcBinder wrapping.
      #
      # @example Usage
      #   class MapperSerie
      #     include Serie::Base
      #     include Serie::WithBlock
      #
      #     def initialize(&block)
      #       self.proc = block
      #       init
      #     end
      #   end
      #
      # @see WithSmartBlock For SmartProcBinder-wrapped blocks
      module WithBlock
        # Gets or sets the proc.
        #
        # @overload proc
        #   @return [Proc, nil] the stored proc
        # @overload proc(&block)
        #   @param block [Proc] block to store
        #   @return [Proc] the stored block
        def proc(&block)
          block ? (@block = block) : @block
        end

        # Sets the proc directly.
        #
        # @param block [Proc] block to store
        def proc=(block)
          @block = block
        end
      end

      # Mixin for series with SmartProcBinder-wrapped block attribute.
      #
      # Similar to {WithBlock} but wraps procs in SmartProcBinder for
      # flexible parameter binding.
      #
      # @example Usage
      #   class SmartMapperSerie
      #     include Serie::Base
      #     include Serie::WithSmartBlock
      #
      #     def initialize(&block)
      #       self.proc = block
      #       init
      #     end
      #   end
      #
      # @see WithBlock For simple proc storage without wrapping
      # @see Extension::SmartProcBinder::SmartProcBinder
      module WithSmartBlock
        # Gets or sets the proc with SmartProcBinder wrapping.
        #
        # @overload proc
        #   @return [Proc, nil] the underlying proc (unwrapped)
        # @overload proc(&block)
        #   @param block [Proc] block to wrap and store
        #   @return [Extension::SmartProcBinder::SmartProcBinder] the wrapped binder
        def proc(&block)
          if block
            @block = Extension::SmartProcBinder::SmartProcBinder.new(block)
          else
            @block&.proc
          end
        end

        # Sets the proc with SmartProcBinder wrapping.
        #
        # @param block [Proc] block to wrap and store
        def proc=(block)
          @block = Extension::SmartProcBinder::SmartProcBinder.new(block)
        end
      end
    end
  end
end
