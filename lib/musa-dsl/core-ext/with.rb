module Musa
  module Extension
    module With
      def with(*parameters, **key_parameters, &block)
        keep_block_context = block.parameters[0][1] == :_ unless block.parameters.empty?
        keep_block_context ||= false

        if keep_block_context
          block.call(self, *parameters, **key_parameters)
        else
          if parameters.empty? && key_parameters.empty?
            instance_eval &block
          else
            instance_exec *parameters, **key_parameters, &block
          end
        end
      end
    end
  end
end
