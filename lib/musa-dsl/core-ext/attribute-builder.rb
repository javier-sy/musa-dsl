module Musa
  module Extension
    # Module providing metaprogramming methods for creating DSL builder patterns.
    #
    # AttributeBuilder defines class methods that generate instance methods for
    # creating and managing collections of objects in a DSL-friendly way. It's
    # heavily used throughout Musa DSL to create fluent, expressive APIs.
    #
    # ## Method Categories
    #
    # - **Adders to Hash**: Create methods that build hash-based collections
    # - **Adders to Array**: Create methods that build array-based collections
    # - **Builders**: Create single-object getter/setter DSL methods
    #
    # ## Naming Conventions
    #
    # - `add_item` / `item`: singular form adds one object
    # - `items`: plural form adds multiple or retrieves collection
    # - Automatic pluralization (item → items) unless specified
    #
    # @example Using in a class
    #   class Score
    #     extend Musa::Extension::AttributeBuilder
    #
    #     def initialize
    #       @tracks = {}
    #     end
    #
    #     attr_tuple_adder_to_hash :track, Track
    #   end
    #
    #   score = Score.new
    #   score.add_track :piano, params
    #   score.tracks  # => { piano: Track(...) }
    #
    # @see Musa::Datasets Score classes use these extensively
    module AttributeBuilder
      # Creates methods for adding id/value tuples to a hash collection.
      #
      # Generates:
      # - `add_#{name}(id, parameter)` → creates instance and adds to hash
      # - `#{plural}(**parameters)` → batch add or retrieve hash
      #
      # @param name [Symbol] singular name for the item.
      # @param klass [Class] class to instantiate (receives id, parameter).
      # @param plural [Symbol, nil] plural name (defaults to name + 's').
      # @param variable [Symbol, nil] instance variable name (defaults to '@' + plural).
      def attr_tuple_adder_to_hash(name, klass, plural: nil, variable: nil)

        plural ||= name.to_s + 's'
        variable ||= ('@' + plural.to_s).to_sym

        adder_method = "add_#{name}".to_sym

        define_method adder_method do |id, parameter|
          klass.new(id, parameter).tap do |object|
            instance_variable_get(variable)[id] = object
          end
        end

        define_method plural do |**parameters|
          parameters&.each_pair do |id, value|
            send adder_method, id, value
          end
          instance_variable_get variable
        end
      end

      # Creates methods for adding id/value tuples to an array collection.
      #
      # Similar to attr_tuple_adder_to_hash but stores items in an array instead of hash.
      # Useful when order matters or duplicates are allowed.
      #
      # @param name [Symbol] singular name for the item.
      # @param klass [Class] class to instantiate.
      # @param plural [Symbol, nil] plural name.
      # @param variable [Symbol, nil] instance variable name.
      def attr_tuple_adder_to_array(name, klass, plural: nil, variable: nil)

        plural ||= name.to_s + 's'
        variable ||= ('@' + plural.to_s).to_sym

        adder_method = "add_#{name}".to_sym

        define_method adder_method do |id, parameter, &block|
          klass.new(id, parameter, &block).tap do |object|
            instance_variable_get(variable) << object
          end
        end

        define_method plural do |**parameters, &block|
          parameters.each_pair do |id, value|
            send adder_method, id, value, &block
          end
          instance_variable_get variable
        end
      end

      # Creates methods for adding complex objects (with multiple parameters) to an array.
      #
      # Supports both positional and keyword arguments when creating instances.
      #
      # @param name [Symbol] singular name.
      # @param klass [Class] class to instantiate.
      # @param plural [Symbol, nil] plural name.
      # @param variable [Symbol, nil] instance variable name.
      def attr_complex_adder_to_array(name, klass, plural: nil, variable: nil)

        plural ||= name.to_s + 's'
        variable ||= ('@' + plural.to_s).to_sym

        adder_method = "add_#{name}".to_sym

        define_method adder_method do |*parameters, **key_parameters, &block|
          klass.new(*parameters, **key_parameters, &block).tap do |object|
            instance_variable_get(variable) << object
          end
        end

        if plural == name
          define_method plural do |*parameters, **key_parameters, &block|
            if parameters.empty? && key_parameters.empty? && block.nil?
              instance_variable_get variable
            else
              send adder_method, *parameters, **key_parameters, &block
            end
          end
        else
          alias_method name, adder_method

          define_method plural do
            instance_variable_get variable
          end
        end
      end


      # Creates methods for adding complex objects with custom construction logic.
      #
      # The block receives parameters and should construct and add the object.
      #
      # @param name [Symbol] singular name.
      # @param plural [Symbol, nil] plural name.
      # @param variable [Symbol, nil] instance variable name.
      # @yield Constructor block executed in instance context.
      def attr_complex_adder_to_custom(name, plural: nil, variable: nil, &constructor_and_adder)

        plural ||= name.to_s + 's'

        adder_method = "add_#{name}".to_sym

        define_method adder_method do |*parameters, **key_parameters, &block|
          instance_exec(*parameters, **key_parameters, &constructor_and_adder).tap do |object|
            object.with &block if block
          end
        end

        if plural == name && variable
          define_method plural do |*parameters, **key_parameters, &block|
            if parameters.empty? && key_parameters.empty? && block.nil?
              instance_variable_get variable
            else
              send adder_method, *parameters, **key_parameters, &block
            end
          end
        else
          alias_method name, adder_method

          if variable
            define_method plural do
              instance_variable_get variable
            end
          end
        end
      end

      # Creates a simple getter/setter DSL method for a single value.
      #
      # @param name [Symbol] attribute name.
      # @param klass [Class, nil] class to instantiate (nil = use value as-is).
      # @param variable [Symbol, nil] instance variable name.
      def attr_simple_builder(name, klass = nil, variable: nil)
        variable ||= ('@' + name.to_s).to_sym

        define_method name do |parameter = nil, &block|
          if parameter.nil?
            instance_variable_get variable
          else
            (klass&.new(parameter, &block) || parameter).tap do |object|
              instance_variable_set variable, object
            end
          end
        end

        attr_writer name
      end

      # Creates a getter/setter DSL method for a single id/value tuple.
      #
      # @param name [Symbol] attribute name.
      # @param klass [Class] class to instantiate.
      # @param variable [Symbol, nil] instance variable name.
      def attr_tuple_builder(name, klass, variable: nil)
        variable ||= ('@' + name.to_s).to_sym

        define_method name do |**parameters, &block|
          if parameters.empty?
            instance_variable_get variable
          elsif parameters.size == 1
            parameter = parameters.first
            klass.new(*parameter, &block).tap do |object|
              instance_variable_set variable, object
            end
          else
            raise ArgumentError, "Method #{name} can only create instances with one id: value arguments pattern"
          end
        end

        attr_writer name
      end

      # Creates a getter/setter DSL method for complex objects with multiple parameters.
      #
      # Supports optional first_parameter that's automatically prepended when constructing.
      #
      # @param name [Symbol] attribute name.
      # @param klass [Class] class to instantiate.
      # @param variable [Symbol, nil] instance variable name.
      # @param first_parameter [Object, nil] parameter automatically prepended to constructor.
      def attr_complex_builder(name, klass, variable: nil, first_parameter: nil)
        variable ||= ('@' + name.to_s).to_sym

        define_method name do |*parameters, **key_parameters, &block|
          if parameters.empty? && key_parameters.empty? && block.nil?
            instance_variable_get variable
          else
            if first_parameter
              klass.new(first_parameter, *parameters, **key_parameters, &block).tap do |object|
                instance_variable_set variable, object
              end
            else
              klass.new(*parameters, **key_parameters, &block).tap do |object|
                instance_variable_set variable, object
              end
            end
          end
        end

        attr_writer name
      end
    end
  end
end
