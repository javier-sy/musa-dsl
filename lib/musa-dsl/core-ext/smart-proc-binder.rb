module Musa
  module Extension
    module SmartProcBinder
      class SmartProcBinder
        def initialize(block, on_rescue: nil)
          @block = block
          @on_rescue = on_rescue

          @key_parameters = {}
          @has_key_rest = false

          @value_parameters_count = 0
          @has_value_rest = false

          block.parameters.each do |parameter|
            @key_parameters[parameter[1]] = nil if parameter[0] == :key || parameter[0] == :keyreq
            @has_key_rest = true if parameter[0] == :keyrest

            @value_parameters_count += 1 if parameter[0] == :req || parameter[0] == :opt
            @has_value_rest = true if parameter[0] == :rest
          end
        end

        def proc
          @block
        end

        def parameters
          @block.parameters
        end

        def call(*value_parameters, **key_parameters)
          _call value_parameters, key_parameters
        end

        def _call(value_parameters, key_parameters)
          if @on_rescue
            begin
              __call value_parameters, key_parameters
            rescue StandardError, ScriptError => e
              @on_rescue.call e
            end
          else
            __call value_parameters, key_parameters
          end
        end

        private def __call(value_parameters, key_parameters)
          effective_value_parameters, effective_key_parameters = apply(*value_parameters, **key_parameters)

          if effective_key_parameters.empty?
            if effective_value_parameters.empty?
              @block.call
            else
              @block.call *effective_value_parameters
            end
          else
            if effective_value_parameters.empty?
              @block.call **effective_key_parameters
            else
              @block.call *effective_value_parameters, **effective_key_parameters
            end
          end
        end

        def key?(key)
          @has_key_rest || @key_parameters.include?(key)
        end

        alias_method :has_key?, :key?

        def apply(*value_parameters, **key_parameters)
          _apply(value_parameters, key_parameters)
        end

        def _apply(value_parameters, key_parameters)
          value_parameters ||= []
          key_parameters ||= {}

          if @has_value_rest
            values_result = value_parameters.clone
          else
            values_result = value_parameters.first(@value_parameters_count)
            values_result += Array.new(@value_parameters_count - values_result.size)
          end

          hash_result = @key_parameters.clone

          @key_parameters.each_key do |parameter_name|
            hash_result[parameter_name] = key_parameters[parameter_name]
          end

          if @has_key_rest
            key_parameters.each do |key, value|
              hash_result[key] = value unless hash_result.key?(key)
            end
          end

          return values_result, hash_result
        end

        def inspect
          "KeyParametersProcedureBinder: parameters = #{@key_parameters} has_rest = #{@has_key_rest}"
        end

        alias to_s inspect
      end
    end
  end
end
