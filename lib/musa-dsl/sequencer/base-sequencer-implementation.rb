require_relative '../core-ext/smart-proc-binder'
require_relative '../core-ext/inspect-nice'

module Musa::Sequencer
  using Musa::Extension::InspectNice

  class BaseSequencer
    # Executes all events scheduled at position.
    #
    # Processes the event queue at the given position, executing each command's
    # block in sequence. Handles parent control hierarchy for event handlers,
    # thread safety with mutexes, and cleanup of empty timeslots.
    #
    # ## Execution Flow
    #
    # 1. Calls all before_tick callbacks with position
    # 2. Gets event queue at position from timeslots
    # 3. For each command in queue:
    #
    #    - Shifts command from queue
    #    - Deletes timeslot if queue becomes empty
    #    - Pushes parent_control to event handler stack if present and not stopped
    #    - If command has skip_if_stopped and control is stopped, skips block execution
    #    - Otherwise executes command block with parameters (mutex-protected)
    #    - Pops parent_control from stack
    #
    # 4. Yields to other threads
    #
    # ## skip_if_stopped
    #
    # Commands scheduled with `skip_if_stopped: true` (via `_numeric_at`) are
    # silently skipped when their control is stopped. Used by `at`, `wait`, `now`
    # and `_serie_at` which have no cleanup logic. Not used by `play`, `every`,
    # `move` or `play_timed` whose blocks mix user callbacks with cleanup/recursion
    # that must execute even when stopped.
    #
    # @param position_to_run [Rational] position to execute events at
    #
    # @return [void]
    #
    # @api private
    private def _tick(position_to_run)
      @before_tick.each { |block| block.call position_to_run }
      queue = @timeslots[position_to_run]

      if queue
        until queue.empty?
          command = queue.shift
          @timeslots.delete position_to_run if queue.empty?

          push_parent = command.key?(:parent_control) && !command[:parent_control].stopped?

          @event_handlers.push(command[:parent_control]) if push_parent

          unless command[:skip_if_stopped] && command[:parent_control]&.stopped?
            @tick_mutex.synchronize do
              command[:block]&.call *command[:value_parameters], **command[:key_parameters]
            end
          end

          @event_handlers.pop if push_parent
        end
      end

      Thread.pass
    end

    # Low-level event scheduling without control or quantization.
    #
    # Schedules a block at a position with minimal overhead. Used internally
    # for basic scheduling where control hierarchy and quantization are not
    # needed. Executes immediately if at current position, schedules for future
    # if ahead, warns if attempting to schedule in past.
    #
    # @param at_position [Rational] position to schedule at
    # @param force_first [Boolean] if true, insert at front of queue
    # @yield block to execute at position
    #
    # @return [void]
    #
    # @example Force execution order
    #   _raw_numeric_at(1r) { puts "second" }
    #   _raw_numeric_at(1r, force_first: true) { puts "first" }
    #
    # @api private
    private def _raw_numeric_at(at_position, force_first: nil, &block)
      force_first ||= false

      if at_position == @position
        begin
          yield
        rescue StandardError, ScriptError => e
          _rescue_error e
        end

      elsif at_position > @position
        @timeslots[at_position] ||= []

        value = { block: block, value_parameters: [], key_parameters: {} }
        if force_first
          @timeslots[at_position].insert 0, value
        else
          @timeslots[at_position] << value
        end
      else
        @logger.warn('BaseSequencer') { "._raw_numeric_at: ignoring past at command for #{at_position}" }
      end

      nil
    end

    # Schedules event with control hierarchy and quantization.
    #
    # Full-featured event scheduling that:
    # - Quantizes position to timing grid (tick-based) or passes through (tickless)
    # - Wraps block in SmartProcBinder for parameter binding and error handling
    # - Passes control parameter to block if it accepts it
    # - Adds debug callbacks if logging enabled
    # - Handles parent_control hierarchy for event handlers
    # - Thread-safe execution
    #
    # ## Position Handling
    #
    # - **Current position**: Executes immediately with try_lock
    # - **Future position**: Adds to timeslots queue
    # - **Past position**: Warns and ignores
    # - **nil position** (tickless before first event): Allows scheduling
    #
    # ## skip_if_stopped
    #
    # When `skip_if_stopped: true`, the block is silently skipped if `control`
    # is stopped at execution time. This applies both for immediate execution
    # (current position) and for future execution (checked in `_tick`).
    # Used by `at`, `wait`, `now` and `_serie_at` for clean cancellation
    # without wrapper procs or extra SmartProcBinder overhead.
    #
    # Not suitable for `play`/`every`/`move`/`play_timed` whose scheduled
    # blocks contain cleanup logic (do_on_stop, do_after) that must run
    # even when stopped.
    #
    # @param at_position [Rational] position to schedule at
    # @param control [EventHandler] parent control for hierarchy
    # @param debug [Boolean, nil] enable debug callbacks
    # @param skip_if_stopped [Boolean, nil] when true, skip block execution
    #   if control is stopped. Used by at/wait/now/_serie_at.
    # @yield block to execute at position (may accept control:)
    #
    # @return [nil]
    #
    # @raise [ArgumentError] if at_position is nil or block not given
    #
    # @api private
    private def _numeric_at(at_position, control, debug: nil, skip_if_stopped: nil, &block)
      raise ArgumentError, "'at_position' parameter cannot be nil" if at_position.nil?
      raise ArgumentError, 'Yield block is mandatory' unless block

      at_position = _quantize_position(at_position)

      block_key_parameters_binder =
        Musa::Extension::SmartProcBinder::SmartProcBinder.new block, on_rescue: proc { |e| _rescue_error(e) }

      key_parameters = {}
      key_parameters[:control] = control if block_key_parameters_binder.key?(:control)

      if at_position == @position
        @on_debug_at.each(&:call) if @logger.sev_threshold >= ::Logger::Severity::DEBUG

        unless skip_if_stopped && control.stopped?
          begin
            locked = @tick_mutex.try_lock
            block_key_parameters_binder._call(nil, key_parameters)
          ensure
            @tick_mutex.unlock if locked
          end
        end

      elsif @position.nil? || at_position > @position

        @timeslots[at_position] ||= []

        if @logger.sev_threshold <= ::Logger::Severity::DEBUG
          @on_debug_at.each do |block|
            @timeslots[at_position] << { parent_control: control, block: block }
          end
        end

        @timeslots[at_position] << { parent_control: control,
                                     block: block_key_parameters_binder,
                                     key_parameters: key_parameters,
                                     skip_if_stopped: skip_if_stopped }
      else
        @logger.warn('BaseSequencer') { "._numeric_at: ignoring past 'at' command for #{at_position}" }
      end

      nil
    end

    # Recursively schedules events from a series of positions.
    #
    # Implements series-based scheduling by:
    # 1. Getting next position from series
    # 2. Scheduling user block at that position
    # 3. Scheduling recursive call to continue series
    #
    # This enables scheduling blocks at positions generated by a Musa::Series,
    # creating patterns like "every 4 beats" or "at positions from fibonacci
    # sequence". Recursion continues until series is exhausted.
    #
    # ## Recursive Structure
    #
    # Each iteration schedules two events at the same position:
    # - User's block (with debug enabled)
    # - Recursive call to _serie_at (debug disabled to avoid duplication)
    #
    # @param position_or_serie [Series] series yielding positions
    # @param control [EventHandler] parent control for hierarchy
    # @param debug [Boolean, nil] enable debug callbacks
    # @yield block to execute at each position from series
    #
    # @return [nil]
    #
    # @example Series scheduling
    #   positions = Musa::Series.from_array([1r, 1.5r, 2r, 3r])
    #   _serie_at(positions, control) { puts "event" }
    #   # Schedules events at 1r, 1.5r, 2r, 3r
    #
    # @api private
    private def _serie_at(position_or_serie, control, debug: nil, &block)
      bar_position = position_or_serie.next_value

      if bar_position
        _numeric_at bar_position, control, debug: debug, skip_if_stopped: true, &block

        _numeric_at bar_position, control, debug: false, skip_if_stopped: true do
          _serie_at position_or_serie, control, debug: debug, &block
        end
      else
        # serie finalizada
      end

      nil
    end

    # Handles errors during event execution.
    #
    # Logs error message and full backtrace, then calls all registered
    # on_error callbacks with the exception. Used by SmartProcBinder and
    # direct rescue blocks to centralize error handling.
    #
    # @param e [Exception] exception that occurred
    #
    # @return [void]
    #
    # @api private
    def _rescue_error(e)
      @logger.error('BaseSequencer') { e.to_s }
      @logger.error('BaseSequencer') { e.full_message(highlight: true, order: :top) }

      @on_error.each do |block|
        block.call e
      end
    end

    # Hierarchical event handler with parent delegation.
    #
    # EventHandler implements a pub/sub event system with hierarchical event
    # propagation. Handlers can be registered for named events, and events
    # bubble up to parent handlers if not handled locally. Used as control
    # objects for play, every, and move operations.
    #
    # ## Event Hierarchy
    #
    # Events are first checked locally. If no handler is registered, the event
    # propagates to the parent handler. This enables:
    # - Control-specific event handling (e.g., :stop for this play)
    # - Global event handling (e.g., :stop for entire sequencer)
    # - Override parent behavior by registering local handler
    #
    # ## Lifecycle
    #
    # - **stop**: Marks handler as stopped (events no longer execute)
    # - **stopped?**: Checks if stopped
    # - **pause/continue**: Not fully implemented
    #
    # ## Event Registration
    #
    # Use `on(event, &block)` to register handlers. Handlers receive parameters
    # via SmartProcBinder, enabling flexible parameter signatures.
    #
    # @example Basic event handling
    #   control = EventHandler.new
    #   control.on(:finished) { puts "Done!" }
    #   control.launch(:finished)  # Prints "Done!"
    #
    # @example Parent delegation
    #   parent = EventHandler.new
    #   parent.on(:stop) { puts "Parent stops" }
    #
    #   child = EventHandler.new(parent)
    #   child.launch(:stop)  # Prints "Parent stops" (delegates to parent)
    #
    #   child.on(:stop) { puts "Child stops" }
    #   child.launch(:stop)  # Prints "Child stops" (local handler, no delegation)
    #
    # @example One-time handler
    #   control.on(:init, only_once: true) { puts "Initialize" }
    #   control.launch(:init)  # Prints "Initialize"
    #   control.launch(:init)  # Does nothing (handler removed)
    #
    # @api private
    class EventHandler
      # Parameters for continue operation (not fully implemented).
      #
      # @return [Hash, nil] continue parameters
      attr_accessor :continue_parameters

      @@counter = 0

      # Creates event handler with optional parent.
      #
      # @param parent [EventHandler, nil] parent for event delegation
      #
      # @api private
      def initialize(parent = nil)
        @id = (@@counter += 1)

        @parent = parent
        @handlers = {}

        @stop = false
      end

      # Stops this event handler.
      #
      # Marks handler as stopped, preventing future event execution. Used by
      # control objects to halt play/every/move operations.
      #
      # @return [void]
      #
      # @api private
      def stop
        @stop = true
      end

      # Checks if handler is stopped.
      #
      # @return [Boolean] true if stopped
      #
      # @api private
      def stopped?
        @stop
      end

      # Pauses handler (not implemented).
      #
      # @raise [NotImplementedError] pause not yet implemented
      #
      # @api private
      def pause
        raise NotImplementedError
      end

      # Continues from pause (not fully implemented).
      #
      # @return [void]
      #
      # @api private
      def continue
        @paused = false
      end

      # Checks if handler is paused.
      #
      # @return [Boolean] true if paused
      #
      # @api private
      def paused?
        @paused
      end

      # Registers event handler.
      #
      # Registers a block to be called when event is launched. Handlers are
      # identified by event name and optional handler name. If only_once is
      # true, handler is removed after first invocation.
      #
      # Block is wrapped in SmartProcBinder for flexible parameter binding.
      #
      # @param event [Symbol] event name to handle
      # @param name [Symbol, nil] optional handler name (for removal)
      # @param only_once [Boolean] remove after first call (default: false)
      # @yield handler block with flexible parameters
      #
      # @return [void]
      #
      # @example Register handler
      #   control.on(:finished) { puts "Done" }
      #   control.on(:progress, name: :logger) { |pct| puts "#{pct}%" }
      #
      # @api private
      def on(event, name: nil, only_once: nil, &block)
        only_once ||= false

        @handlers[event] ||= {}

        # TODO: add on_rescue: proc { |e| _rescue_block_error(e) } [this method is on Sequencer, not in EventHandler]
        @handlers[event][name] = { block: Musa::Extension::SmartProcBinder::SmartProcBinder.new(block), only_once: only_once }
      end

      # Launches event with parameters.
      #
      # Triggers all registered handlers for the event, passing parameters.
      # If no local handlers exist, delegates to parent handler (bubbling).
      # Supports value parameters (*args), keyword parameters (**kwargs),
      # and block parameter (&block).
      #
      # @param event [Symbol] event name to launch
      # @param value_parameters [Array] positional arguments for handlers
      # @param key_parameters [Hash] keyword arguments for handlers
      # @param proc_parameter [Proc, nil] block parameter for handlers
      #
      # @return [void]
      #
      # @example Launch with parameters
      #   control.on(:progress) { |percent| puts "#{percent}%" }
      #   control.launch(:progress, 50)  # Prints "50%"
      #
      # @example Launch with keyword parameters
      #   control.on(:update) { |position:, value:| puts "#{position}: #{value}" }
      #   control.launch(:update, position: 1r, value: 60)
      #
      # @api private
      def launch(event, *value_parameters, **key_parameters, &proc_parameter)
        _launch event, value_parameters, key_parameters, proc_parameter
      end

      # Internal launch implementation with delegation.
      #
      # Processes handlers locally, then delegates to parent if no local
      # handlers processed the event. Removes only_once handlers after
      # first invocation.
      #
      # @param event [Symbol] event name
      # @param value_parameters [Array] positional args
      # @param key_parameters [Hash] keyword args
      # @param proc_parameter [Proc, nil] block arg
      #
      # @return [void]
      #
      # @api private
      def _launch(event, value_parameters = nil, key_parameters = nil, proc_parameter = nil)
        value_parameters ||= []
        key_parameters ||= {}
        processed = false

        if @handlers.key? event
          @handlers[event].each do |name, handler|
            handler[:block].call *value_parameters, **key_parameters, &proc_parameter
            @handlers[event].delete name if handler[:only_once]
            processed = true
          end
        end

        @parent._launch event, value_parameters, key_parameters, proc_parameter if @parent && !processed
      end

      # Returns string representation.
      #
      # @return [String] "EventHandler <id>"
      #
      # @api private
      def inspect
        "EventHandler #{id}"
      end

      # Returns hierarchical identifier.
      #
      # Builds identifier showing parent chain and instance ID.
      #
      # @return [String] hierarchical ID like "EventHandler-1.PlayControl-5"
      #
      # @api private
      def id
        if @parent
          "#{@parent.id}.#{self.class.name.split('::').last}-#{@id}"
        else
          "#{self.class.name.split('::').last}-#{@id.to_s}"
        end
      end

      alias to_s inspect
    end

    private_constant :EventHandler
  end
end
