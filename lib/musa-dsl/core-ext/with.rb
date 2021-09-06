require_relative 'smart-proc-binder'

module Musa
  module Extension
    module With
      def with(*value_parameters, **key_parameters, &block)
        binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

        keep_proc_context = @keep_proc_context_on_with
        send_self_as_underscore_parameter = binder.parameters[0][1] == :_ unless binder.parameters.empty?
        keep_proc_context ||= send_self_as_underscore_parameter
        keep_proc_context ||= false

        effective_value_parameters, effective_key_parameters = binder._apply(value_parameters, key_parameters)

        if keep_proc_context
          if send_self_as_underscore_parameter
            binder.call(self, *effective_value_parameters, **effective_key_parameters)
          else
            binder.call(*effective_value_parameters, **effective_key_parameters)
          end
        elsif effective_value_parameters.empty? && effective_key_parameters.empty?
          instance_eval &block
        else
          instance_exec *effective_value_parameters, **effective_key_parameters, &block
        end
      end
    end
  end
end
