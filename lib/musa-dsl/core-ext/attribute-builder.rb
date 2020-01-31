module AttributeBuilder
  # add_thing id, parameter
  # things id1: parameter1, id2: parameter2 -> { id1: Thing(id1, parameter1), id2: Thing(id2, parameter2) }
  # things -> { id1: Thing(id1, parameter1), id2: Thing(id2, parameter2) }
  #
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

  # add_thing id, parameter
  # things id1: parameter1, id2: parameter2 -> [ Thing(id1, parameter1), Thing(id2, parameter2) ]
  # things -> [ Thing(id1, parameter1), Thing(id2, parameter2) ]

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

  # add_thing param1, param2, key1: parameter1, key2: parameter2 -> Thing(...)
  # thing param1, param2, key1: parameter1, key2: parameter2 -> Thing(...)
  # things -> (collection)

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


  # add_thing param1, param2, key1: parameter1, key2: parameter2 -> Thing(...)
  # thing param1, param2, key1: parameter1, key2: parameter2 -> Thing(...)
  # things -> (collection)

  def attr_complex_adder_to_custom(name, plural: nil, variable: nil, &constructor_and_adder)

    plural ||= name.to_s + 's'
    getter ||= true

    adder_method = "add_#{name}".to_sym

    define_method adder_method do |*parameters, **key_parameters, &block|
      instance_exec(*parameters, **key_parameters, &constructor_and_adder).tap do |object|
        object.as_context_run block if block && object.is_a?(AsContextRun)
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

  # thing value -> crea Thing(value)
  # thing -> Thing(value)

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

  # thing id: value -> crea Thing(id, value)
  # thing -> Thing(id, value)

  def attr_tuple_builder(name, klass, variable: nil)
    variable ||= ('@' + name.to_s).to_sym

    define_method name do |**parameters, &block|
      raise ArgumentError, "Method #{name} can only create instances with one id: value arguments pattern" unless parameters.size == 1

      if parameters.empty?
        instance_variable_get variable
      else
        parameter = parameters.first
        klass.new(*parameter, &block).tap do |object|
          instance_variable_set variable, object
        end
      end
    end

    attr_writer name
  end

  # thing key1: value1, key2: value2 -> crea Thing(key1: value1, key2: value2)
  # thing -> Thing(value1, value2)

  def attr_complex_builder(name, klass, variable: nil)
    variable ||= ('@' + name.to_s).to_sym

    define_method name do |*parameters, **key_parameters, &block|
      if parameters.empty? && key_parameters.empty? && block.nil?
        instance_variable_get variable
      else
        klass.new(*parameters, **parameters, &block).tap do |object|
          instance_variable_set variable, object
        end
      end
    end

    attr_writer name
  end
end
