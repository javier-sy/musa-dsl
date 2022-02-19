require_relative 'smart-proc-binder'

module Musa
  module Extension
    module With
      def with(*value_parameters, keep_block_context: nil, **key_parameters, &block)
        binder = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

        send_self_as_underscore_parameter = binder.parameters[0][1] == :_ unless binder.parameters.empty?

        effective_keep_block_context = keep_block_context
        effective_keep_block_context ||= send_self_as_underscore_parameter
        effective_keep_block_context ||= false

        effective_value_parameters, effective_key_parameters = binder._apply(value_parameters, key_parameters)

        if effective_keep_block_context
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
