# Based on https://github.com/adamluzsi/duplicate.rb/blob/master/lib/duplicate.rb
# Modifications by Javier Sánchez Yeste

module Musa
  module Extension
    module DeepCopy
      module DeepCopy
        extend self

        def deep_copy(object, method: :dup, freeze: true)
          raise ArgumentError, "deep_copy method can only be :dup or :clone" unless method == :dup || method == :clone
          register = {}

          _deep_copy(register, object, method, freeze)
        end

        def copy_singleton_class_modules(source, target)
          source.singleton_class.included_modules.each do |m|
            target.extend m unless target.is_a?(m)
          end

          target
        end

        protected

        def registered(object, register)
          register[object.__id__]
        end

        def register(register, object, duplicate)
          register[object.__id__] = duplicate
          duplicate
        end

        def _deep_copy(register, object, method, freeze)
          return registered(object, register) if registered(object, register)
          return register(register, object, object) unless identifiable?(object)

          case object

          when Array
            deep_copy_array(register, object, method, freeze)

          when Hash
            deep_copy_hash(register, object, method, freeze)

          when Range
            deep_copy_range(register, object, method, freeze)

          when Struct
            deep_copy_struct(register, object, method, freeze)

          when Proc
            deep_copy_proc(register, object, method, freeze)

          when NilClass, Symbol, Numeric, TrueClass, FalseClass, Method
            register(register, object, object)

          else
            deep_copy_object(register, object, method, freeze)

          end
        end

        def identifiable?(object)
          object.class && object.respond_to?(:is_a?)
        rescue NoMethodError
          false
        end

        def deep_copy_array(register, object, method, freeze)
          deep_copy_object(register, object, method, freeze) do |_, copy|
            copy.map! { |e| _deep_copy(register, e, method, freeze) }
          end
        end

        def deep_copy_hash(register, object, method, freeze)
          deep_copy_object(register, object, method, freeze) do |object, copy|
            object.reduce(copy) { |hash, (k, v)| hash.merge!(_deep_copy(register, k, method, freeze) => _deep_copy(register, v, method, freeze)) }
          end
        end

        def deep_copy_range(register, range, method, freeze)
          copy = range.class.new(_deep_copy(register, range.first, method, freeze), _deep_copy(register, range.last, method, freeze))
          copy.freeze if range.frozen?

          register(register, range, copy)
        rescue StandardError
          register(register, range, range.send(method))
        end

        def deep_copy_struct(register, struct, method, freeze)
          duplication = register(register, struct, struct.send(method))

          struct.each_pair do |attr, value|
            duplication.__send__("#{attr}=", _deep_copy(register, value, method, freeze))
          end

          duplication
        end

        def deep_copy_object(register, object, method, freeze)
          if method == :clone && object.frozen?
            copy = try_deep_copy(object, :clone, false)
          else
            copy = try_deep_copy(object, method, freeze)
          end

          register(register, object, copy)
          deep_copy_instance_variables(register, object, register(register, object, copy), method, freeze)

          yield object, copy if block_given?

          copy.freeze if method == :clone && object.frozen? && freeze

          copy
        end

        def deep_copy_proc(register, object, method, freeze)
          register(register, object, object.dup)
        end

        def deep_copy_instance_variables(register, object, duplication, method, freeze)
          return duplication unless respond_to_instance_variables?(object)

          object.instance_variables.each do |instance_variable|
            value = get_instance_variable(object, instance_variable)

            set_instance_variable(duplication, instance_variable, _deep_copy(register, value, method, freeze))
          end

          duplication
        end

        def get_instance_variable(object, instance_variable_name)
          object.instance_variable_get(instance_variable_name)
        rescue NoMethodError
          object.instance_eval(instance_variable_name.to_s)
        end

        def set_instance_variable(duplicate, instance_variable_name, value_to_set)
          duplicate.instance_variable_set(instance_variable_name, value_to_set)
        rescue NoMethodError
          duplicate.instance_eval("#{instance_variable_name} = Marshal.load(#{Marshal.dump(value_to_set).inspect})")
        end

        def try_deep_copy(object, method, freeze)
          if method == :dup
            object.dup
          else
            object.clone(freeze: freeze)
          end
        rescue NoMethodError, TypeError
          object
        end

        def respond_to_instance_variables?(object)
          object.respond_to?(:instance_variables) && object.instance_variables.is_a?(Array)
        rescue NoMethodError
          false
        end
      end

      refine Object do
        def dup(deep: false)
          if deep
            Musa::Extension::DeepCopy::DeepCopy.deep_copy(self, method: :dup)
          else
            super()
          end
        end

        def clone(freeze: true, deep: false)
          if deep
            Musa::Extension::DeepCopy::DeepCopy.deep_copy(self, method: :clone, freeze: freeze)
          else
            super(freeze: freeze)
          end
        end
      end
    end
  end
end

