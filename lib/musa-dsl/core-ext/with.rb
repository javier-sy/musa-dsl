require_relative 'smart-proc-binder'

module Musa
  module Extension
    module With
      def with(*value_parameters, keep_block_context: nil, **key_parameters, &block)
        smart_block = Musa::Extension::SmartProcBinder::SmartProcBinder.new(block)

        send_self_as_underscore_parameter = smart_block.parameters[0][1] == :_ unless smart_block.parameters.empty?

        effective_keep_block_context = keep_block_context
        effective_keep_block_context = send_self_as_underscore_parameter if effective_keep_block_context.nil?
        effective_keep_block_context = false if effective_keep_block_context.nil?

        effective_value_parameters, effective_key_parameters = smart_block._apply(value_parameters, key_parameters)

        if effective_keep_block_context
          if send_self_as_underscore_parameter
            smart_block.call(self, *effective_value_parameters, **effective_key_parameters)
          else
            smart_block.call(*effective_value_parameters, **effective_key_parameters)
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
