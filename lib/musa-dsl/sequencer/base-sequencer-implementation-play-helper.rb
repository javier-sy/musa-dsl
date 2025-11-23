# Play evaluation modes for interpreting series elements.
#
# PlayEval and its subclasses implement different strategies for interpreting
# series elements during play operations. Each mode determines:
# - What operation to perform (call block, launch event, nested play, etc.)
# - When to continue (now, at position, after wait, on event)
#
# ## Available Modes
#
# - **:at**: Elements specify absolute positions via :at key
# - **:wait**: Elements with duration specify wait time
# - **:neumalang**: Full Neumalang DSL with variables, commands, series, etc.
#
# ## Operation Hash Format
#
# run_operation returns hash with:
#
# - current_operation: :none, :block, :event, :play, :parallel_play, :no_eval_play
# - current_parameter: data for current operation
# - continue_operation: :now, :at, :wait, :on
# - continue_parameter: data for continue operation
#
# @api private
module Musa
  module Sequencer
    class BaseSequencer
      # Base class for play evaluation strategies.
      #
      # Defines interface for evaluating series elements and determining
      # operations. Subclasses implement specific interpretation modes.
      #
      # @api private
      class PlayEval
        # Factory method creating appropriate evaluator for mode.
        #
        # @param mode [Symbol, nil] evaluation mode
        # @param block_procedure_binder [SmartProcBinder] user block binder
        # @param decoder [Object, nil] decoder for GDVD elements
        # @param nl_context [Object, nil] Neumalang execution context
        #
        # @return [PlayEval] evaluator instance
        #
        # @raise [ArgumentError] if mode unknown
        #
        # @api private
        def self.create(mode, block_procedure_binder, decoder, nl_context)
          case mode
          when :at
            AtModePlayEval.new block_procedure_binder
          when :wait
            WaitModePlayEval.new block_procedure_binder
          when :neumalang
            NeumalangModePlayEval.new block_procedure_binder, decoder, nl_context
          else
            raise ArgumentError, "Unknown mode #{mode}"
          end
        end

        # @return [SmartProcBinder] user block binder
        attr_reader :block_procedure_binder

        # Creates subcontext for nested plays.
        #
        # Default returns self. Neumalang mode creates new isolated context.
        #
        # @return [PlayEval] subcontext evaluator
        #
        # @api private
        def subcontext
          self
        end

        # Evaluates element (mode-dependent).
        #
        # @param _element [Object] element to evaluate
        #
        # @return [Object] evaluated result
        #
        # @raise [NotImplementedError] must be implemented by subclass
        #
        # @api private
        def eval_element(_element)
          raise NotImplementedError
        end

        # Determines operations from element.
        #
        # Returns hash specifying current and continue operations.
        #
        # @param _element [Object] element to process
        #
        # @return [Hash] operation specification
        #
        # @raise [NotImplementedError] must be implemented by subclass
        #
        # @api private
        def run_operation(_element)
          raise NotImplementedError
        end
      end

      private_constant :PlayEval

      # At-mode evaluator for absolute position scheduling.
      #
      # Interprets elements as data with optional :at key specifying absolute
      # position. If :at present, schedules at that position. Otherwise uses
      # current position.
      #
      # @example At-mode usage
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   series = Musa::Series::S(
      #     { pitch: 60, at: 0r },
      #     { pitch: 62, at: 1r },
      #     { pitch: 64, at: 2r }
      #   )
      #
      #   played_notes = []
      #
      #   seq.play(series, mode: :at) do |element|
      #     played_notes << { pitch: element[:pitch], position: seq.position }
      #   end
      #
      #   seq.run
      #   # Result: played_notes contains [{pitch: 60, position: 0r}, {pitch: 62, position: 1r}, ...]
      #
      # @api private
      class AtModePlayEval < PlayEval
        # Creates at-mode evaluator.
        #
        # @param block_procedure_binder [SmartProcBinder] user block binder
        #
        # @api private
        def initialize(block_procedure_binder)
          @block_procedure_binder = block_procedure_binder
          super()
        end

        # Determines operation from element.
        #
        # Hash elements with :at key schedule at absolute position.
        # Other elements use current position.
        #
        # @param element [Hash, Object] element to process
        #
        # @return [Hash] operation hash
        #
        # @api private
        def run_operation(element)
          value = nil

          if element.is_a? Hash
            value = {
              current_operation: :block,
              current_block: @block_procedure_binder,
              current_parameter: element,
              continue_operation: :at,
              continue_parameter: element[:at]
            }
          end

          value ||= {
            current_operation: @block_procedure_binder,
            current_parameter: element,
            continue_operation: :at,
            continue_parameter: position
          }

          value
        end
      end

      private_constant :AtModePlayEval

      # Wait-mode evaluator for duration-based scheduling.
      #
      # Interprets elements as data with duration (AbsD compatible) specifying
      # wait time before next element. Supports :wait_event for event-driven
      # continuation.
      #
      # @example Wait-mode with duration
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   series = Musa::Series::S(
      #     { pitch: 60, duration: 1r },
      #     { pitch: 62, duration: 0.5r },
      #     { pitch: 64, duration: 1.5r }
      #   )
      #
      #   played_notes = []
      #
      #   seq.play(series, mode: :wait) do |element|
      #     played_notes << { pitch: element[:pitch], duration: element[:duration], position: seq.position }
      #   end
      #
      #   seq.run
      #   # Result: played_notes contains [{pitch: 60, duration: 1r, position: 0}, ...]
      #
      # @example Wait-mode with event
      #   # Elements can also use :wait_event for event-driven continuation
      #   # Example: { pitch: 60, wait_event: :next }
      #
      # @api private
      class WaitModePlayEval < PlayEval
        include Musa::Datasets

        # Creates wait-mode evaluator.
        #
        # @param block_procedure_binder [SmartProcBinder] user block binder
        #
        # @api private
        def initialize(block_procedure_binder)
          @block_procedure_binder = block_procedure_binder
          super()
        end

        # Determines operation from element.
        #
        # AbsD-compatible elements wait by duration.
        # Elements with :wait_event continue on event.
        # Other elements continue immediately.
        #
        # @param element [Hash, Object] element to process
        #
        # @return [Hash] operation hash
        #
        # @api private
        def run_operation(element)
          value = nil

          if element.is_a? Hash
            if AbsD.is_compatible?(element)
              element = AbsD.to_AbsD(element)

              value = {
                current_operation: :block,
                current_block: @block_procedure_binder,
                current_parameter: element,
                continue_operation: :wait,
                continue_parameter: element.forward_duration
              }
            end

            if element.key? :wait_event
              value = {
                current_operation: :block,
                current_block: @block_procedure_binder,
                current_parameter: element,
                continue_operation: :on,
                continue_parameter: element[:wait_event]
              }
            end
          end

          value ||= {
            current_operation: :block,
            current_block: @block_procedure_binder,
            current_parameter: element,
            continue_operation: :now
          }

          value
        end
      end

      private_constant :WaitModePlayEval

      # Neumalang-mode evaluator for full DSL support.
      #
      # Implements complete Neumalang DSL evaluation including:
      # - Variables (assign, use)
      # - Commands (code blocks with parameters)
      # - Series (nested plays)
      # - Parallel execution
      # - GDVD decoding
      # - P (pattern) sequences
      # - Event launching
      # - Method chaining
      #
      # ## Neumalang Elements
      #
      # Elements have :kind specifying type:
      # - :value - Simple value
      # - :gdvd - Generative Diatonic Value/Duration
      # - :p - Pattern sequence
      # - :serie - Nested series
      # - :parallel - Parallel series
      # - :assign_to - Variable assignment
      # - :use_variable - Variable reference
      # - :command - Code block execution
      # - :event - Event launch
      # - :call_methods - Method chain
      #
      # ## Context Isolation
      #
      # Each nested play gets isolated subcontext with:
      # - Shared neumalang context (variables persist)
      # - Fresh decoder subcontext
      # - Hierarchical ID for debugging
      #
      # @example Neumalang mode
      #   seq = Musa::Sequencer::BaseSequencer.new(4, 24)
      #
      #   scale = Musa::Scales::Scales.et12[440.0].major[60]
      #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)
      #
      #   using Musa::Extension::Neumas
      #   neumalang_series = "0 +2 +2 -1 0".to_neumas
      #
      #   played_notes = []
      #
      #   seq.play(neumalang_series, mode: :neumalang, decoder: decoder) do |gdv|
      #     played_notes << { pitch: gdv[:pitch], duration: gdv[:duration], velocity: gdv[:velocity] }
      #   end
      #
      #   seq.run
      #   # Result: played_notes contains decoded GDVD values with pitch, duration, velocity
      #
      # @api private
      class NeumalangModePlayEval < PlayEval
        include Musa::Datasets

        # Marker module for parallel series.
        #
        # @api private
        module Parallel end

        @@id = 0

        # @return [Object] Neumalang execution context
        # @return [SmartProcBinder] user block binder
        attr_reader :neumalang_context,
                    :block_procedure_binder

        # Creates Neumalang-mode evaluator.
        #
        # @param block_procedure_binder [SmartProcBinder] user block binder
        # @param decoder [Object] GDVD decoder
        # @param nl_context [Object, nil] Neumalang context (creates if nil)
        # @param parent [NeumalangModePlayEval, nil] parent evaluator
        #
        # @api private
        def initialize(block_procedure_binder, decoder, nl_context, parent: nil)
          @id = @@id += 1
          @parent = parent

          @block_procedure_binder = block_procedure_binder
          @decoder = decoder
          @nl_context = nl_context

          @nl_context ||= Object.new

          super()
        end

        # Creates isolated subcontext for nested plays.
        #
        # Shares neumalang context but creates fresh decoder subcontext.
        #
        # @return [NeumalangModePlayEval] subcontext evaluator
        #
        # @api private
        def subcontext
          NeumalangModePlayEval.new @block_procedure_binder, @decoder.subcontext, @nl_context, parent: self
        end

        # Evaluates Neumalang element by kind.
        #
        # Dispatches to appropriate eval_* method based on element :kind.
        # AbsD-compatible elements converted directly.
        #
        # @param element [Hash, Object] element to evaluate
        #
        # @return [Object] evaluated result
        #
        # @raise [ArgumentError] if element kind unknown
        #
        # @api private
        def eval_element(element)
          if AbsD.is_compatible?(element)
            AbsD.to_AbsD(element)
          else
            case element[:kind]
            when :serie             then eval_serie element[:serie]
            when :parallel          then eval_parallel element[:parallel]
            when :assign_to         then eval_assign_to element[:assign_to], element[:assign_value]
            when :use_variable      then eval_use_variable element[:use_variable]
            when :command           then eval_command element[:command], element[:value_parameters], element[:key_parameters]
            when :value             then eval_value element[:value]
            when :gdvd              then eval_gdvd element[:gdvd]
            when :p                 then eval_p element[:p]
            when :call_methods      then eval_call_methods element[:on], element[:call_methods]
            when :command_reference then eval_command_reference element[:command]
            when :event             then element
            else
              raise ArgumentError, "eval_element: don't know how to process #{element}"
            end
          end
        end

        # @api private
        def eval_value(value)
          value
        end

        # Decodes GDVD (Generative Diatonic Value/Duration) element.
        #
        # @param gdvd [Object] GDVD element
        # @return [Object] decoded value
        # @api private
        def eval_gdvd(gdvd)
          @decoder.decode(gdvd)
        end

        # Converts P (pattern) to series.
        #
        # @param p [Object] pattern object
        # @return [Series] pattern series instance
        # @api private
        def eval_p(p)
          p.to_ps_serie(base_duration: @decoder.base_duration).instance
        end

        # Evaluates series with subcontext.
        #
        # @param serie [Object] series definition
        # @return [Series] evaluated series instance
        # @api private
        def eval_serie(serie)
          context = subcontext
          serie.instance.eval(on_restart: proc { context = subcontext }) { |e| context.eval_element e }
        end

        # Evaluates parallel series.
        #
        # @param series [Array] array of series definitions
        # @return [Array] array of series instances (with Parallel marker)
        # @api private
        def eval_parallel(series)
          context = subcontext
          series.collect { |s| context.eval_serie s[:serie] }.extend Parallel
        end

        # Assigns value to variable(s) in neumalang context.
        #
        # @param variable_names [Array<Symbol>] variable names
        # @param value [Object] value to assign
        # @return [Object] assigned value
        # @api private
        def eval_assign_to(variable_names, value)
          _value = nil

          variable_names.each do |var_name|
            @nl_context.instance_variable_set var_name, _value = subcontext.eval_element(value)
          end

          _value
        end

        # Retrieves variable value from neumalang context.
        #
        # @param variable_name [Symbol] variable name
        # @return [Object] variable value
        # @raise [NameError] if variable not defined
        # @api private
        def eval_use_variable(variable_name)
          if @nl_context.instance_variable_defined?(variable_name)
            @nl_context.instance_variable_get(variable_name)
          else
            raise NameError, "Variable #{variable_name} is not defined in context #{@nl_context}"
          end
        end

        # Executes command block in neumalang context.
        #
        # Evaluates parameters then executes block via instance_exec.
        #
        # @param block [Proc] command block
        # @param value_parameters [Array, nil] positional parameters
        # @param key_parameters [Hash, nil] keyword parameters
        # @return [Object] command result
        # @api private
        def eval_command(block, value_parameters, key_parameters)
          _value_parameters = value_parameters&.collect { |e| subcontext.eval_element(e) } || []
          _key_parameters = key_parameters&.transform_values { |e| subcontext.eval_element(e) } || {}

          # used instance_exec because the code on block comes from a neumalang source, so the correct
          # execution context is the neumalang context (no other context has any sense)
          #
          @nl_context.instance_exec *_value_parameters, **_key_parameters, &block
        end

        # @api private
        def eval_call_methods(on, call_methods)
          play_eval = subcontext

          value = play_eval.eval_element on

          if value.is_a? Parallel
            value.collect { |_value| eval_methods(play_eval, _value, call_methods) }.extend Parallel
          else
            eval_methods(play_eval, value, call_methods)
          end
        end

        # @api private
        def eval_methods(play_eval, value, methods)
          methods.each do |methd|
            value_parameters = methd[:value_parameters]&.collect { |e| play_eval.subcontext.eval_element(e) } || []
            key_parameters = methd[:key_parameters]&.transform_values { |e| play_eval.subcontext.eval_element(e) } || {}
            proc_parameter = eval_proc_parameter(methd[:proc_parameter][:codeblock]) if methd[:proc_parameter]

            value = value.send methd[:method], *value_parameters, **key_parameters, &proc_parameter
          end

          value
        end

        # @api private
        def eval_command_reference(element)
          element[:command]
        end

        # @api private
        def eval_proc_parameter(element)
          case element
          when Proc
            element
          when nil
            nil
          else
            case element[:kind]
            when :use_variable
              eval_proc_parameter(eval_use_variable(element[:use_variable]))
            when :command_reference
              eval_proc_parameter(element[:command])
            when :command
              element[:command]
            end
          end
        end

        # Determines operation from Neumalang element.
        #
        # Dispatches based on element type and :kind, returning operation hash
        # specifying current and continue operations.
        #
        # Handles all Neumalang element types including values, series, parallel
        # plays, variables, commands, and events.
        #
        # @param element [Object] element to process
        #
        # @return [Hash] operation hash
        #
        # @raise [ArgumentError] if element kind unknown
        #
        # @api private
        def run_operation(element)
          case element
          when nil
            { current_operation: :none,
              continue_operation: :now }

          when Musa::Datasets::AbsD
            { current_operation: :block,
              current_parameter: element,
              continue_operation: :wait,
              continue_parameter: element.forward_duration }

          when Musa::Series::Serie
            { current_operation: :play,
              current_parameter: element.instance.restart }

          when Parallel
            { current_operation: :parallel_play,
              current_parameter: element.tap { |e| e.each(&:restart) } }

          when Array
            { current_operation: :no_eval_play,
              current_parameter: Musa::Series::Constructors.S(*element) }
          else
            case element[:kind]
            when :value
              _value = eval_value element[:value]

              if AbsD.is_compatible?(_value)
                _value = AbsD.to_AbsD(_value)

                { current_operation: :block,
                  current_parameter: _value,
                  continue_operation: :wait,
                  continue_parameter: _value.forward_duration }
              else
                { current_operation: :block,
                  current_parameter: _value,
                  continue_operation: :now }
              end

            when :gdvd
              _value = eval_gdvd element[:gdvd]

              if _value.is_a?(Array)
                { current_operation: :no_eval_play,
                  current_parameter: Musa::Series::Constructors.S(*_value) }
              else
                { current_operation: :block,
                  current_parameter: _value,
                  continue_operation: :wait,
                  continue_parameter: _value.forward_duration }
              end

            when :p
              { current_operation: :play,
                current_parameter: eval_p(element[:p]) }

            when :serie
              { current_operation: :play,
                current_parameter: eval_serie(element[:serie]) }

            when :parallel
              { current_operation: :parallel_play,
                current_parameter: eval_parallel(element[:parallel]) }

            when :assign_to
              eval_assign_to element[:assign_to], element[:assign_value]

              { current_operation: :none,
                continue_operation: :now }

            when :use_variable
              run_operation eval_use_variable(element[:use_variable])

            when :event
              value_parameters = element[:value_parameters]&.collect { |e| subcontext.eval_element(e) } || []
              key_parameters = element[:key_parameters]&.transform_values { |e| subcontext.eval_element(e) } || {}
              proc_parameter = eval_proc_parameter(element[:proc_parameter][:codeblock]) if element[:proc_parameter]

              { current_operation: :event,
                current_event: element[:event],
                current_value_parameters: value_parameters,
                current_key_parameters: key_parameters,
                current_proc_parameter: proc_parameter,
                continue_operation: :now }

            when :command
              run_operation eval_command(element[:command], element[:value_parameters], element[:key_parameters])

            when :call_methods
              run_operation eval_call_methods(element[:on], element[:call_methods])

            when :reference
              run_operation eval_command_reference(element[:reference])

            else
              raise ArgumentError, "run_operation: don't know how to process #{element}"
            end
          end
        end

        def inspect
          "NeumalangModePlayEval #{id} #{@decoder}"
        end

        def id
          if @parent
            "#{@parent.id}.#{@id}"
          else
            @id.to_s
          end
        end

        alias to_s inspect
      end

      private_constant :NeumalangModePlayEval
    end
  end
end
