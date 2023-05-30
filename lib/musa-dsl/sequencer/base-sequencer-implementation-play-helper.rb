module Musa
  module Sequencer
    class BaseSequencer
      class PlayEval
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

        attr_reader :block_procedure_binder

        def subcontext
          self
        end

        def eval_element(_element)
          raise NotImplementedError
        end

        def run_operation(_element)
          raise NotImplementedError
        end
      end

      private_constant :PlayEval

      class AtModePlayEval < PlayEval
        def initialize(block_procedure_binder)
          @block_procedure_binder = block_procedure_binder
          super()
        end

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

      class WaitModePlayEval < PlayEval
        include Musa::Datasets

        def initialize(block_procedure_binder)
          @block_procedure_binder = block_procedure_binder
          super()
        end

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

      class NeumalangModePlayEval < PlayEval
        include Musa::Datasets

        module Parallel end

        @@id = 0

        attr_reader :neumalang_context,
                    :block_procedure_binder

        def initialize(block_procedure_binder, decoder, nl_context, parent: nil)
          @id = @@id += 1
          @parent = parent

          @block_procedure_binder = block_procedure_binder
          @decoder = decoder
          @nl_context = nl_context

          @nl_context ||= Object.new

          super()
        end

        def subcontext
          NeumalangModePlayEval.new @block_procedure_binder, @decoder.subcontext, @nl_context, parent: self
        end

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

        def eval_value(value)
          value
        end

        def eval_gdvd(gdvd)
          @decoder.decode(gdvd)
        end

        def eval_p(p)
          p.to_ps_serie(base_duration: @decoder.base_duration).instance
        end

        def eval_serie(serie)
          context = subcontext
          serie.instance.eval(on_restart: proc { context = subcontext }) { |e| context.eval_element e }
        end

        def eval_parallel(series)
          context = subcontext
          series.collect { |s| context.eval_serie s[:serie] }.extend Parallel
        end

        def eval_assign_to(variable_names, value)
          _value = nil

          variable_names.each do |var_name|
            @nl_context.instance_variable_set var_name, _value = subcontext.eval_element(value)
          end

          _value
        end

        def eval_use_variable(variable_name)
          if @nl_context.instance_variable_defined?(variable_name)
            @nl_context.instance_variable_get(variable_name)
          else
            raise NameError, "Variable #{variable_name} is not defined in context #{@nl_context}"
          end
        end

        def eval_command(block, value_parameters, key_parameters)
          _value_parameters = value_parameters ? value_parameters.collect { |e| subcontext.eval_element(e) } : []
          _key_parameters = key_parameters ? key_parameters.transform_values { |e| subcontext.eval_element(e) } : {}

          # used instance_exec because the code on block comes from a neumalang source, so the correct
          # execution context is the neumalang context (no other context has any sense)
          #
          @nl_context.instance_exec *_value_parameters, **_key_parameters, &block
        end

        def eval_call_methods(on, call_methods)
          play_eval = subcontext

          value = play_eval.eval_element on

          if value.is_a? Parallel
            value.collect { |_value| eval_methods(play_eval, _value, call_methods) }.extend Parallel
          else
            eval_methods(play_eval, value, call_methods)
          end
        end

        def eval_methods(play_eval, value, methods)
          methods.each do |methd|
            value_parameters = methd[:value_parameters]&.collect { |e| play_eval.subcontext.eval_element(e) } || []
            key_parameters = methd[:key_parameters]&.transform_values { |e| play_eval.subcontext.eval_element(e) } || {}
            proc_parameter = eval_proc_parameter(methd[:proc_parameter][:codeblock]) if methd[:proc_parameter]

            value = value.send methd[:method], *value_parameters, **key_parameters, &proc_parameter
          end

          value
        end

        def eval_command_reference(element)
          element[:command]
        end

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
