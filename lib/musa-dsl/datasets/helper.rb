module Musa::Datasets
  # Helper utilities for dataset formatting and string generation.
  #
  # Helper provides utility methods for converting datasets to string
  # representations, particularly for the Neuma notation format.
  #
  # These methods handle:
  #
  # - Sign formatting (+/-)
  # - Velocity to dynamics conversion
  # - Modifier parameter formatting
  #
  # @api private
  module Helper
    private

    # Returns '+' for non-negative numbers, empty string for negative.
    #
    # Used for formatting delta values in Neuma notation.
    #
    # @param x [Numeric] number to check
    # @return [String] '+' or ''
    #
    # @example positive_sign_of
    #   positive_sign_of(5)   # => '+'
    #   positive_sign_of(-3)  # => ''
    #
    # @api private
    def positive_sign_of(x)
      x >= 0 ? '+' : ''
    end

    # Returns '+', '+', or '-' based on number's sign.
    #
    # @param x [Numeric] number to check
    # @return [String] '+' (positive), '+' (zero), or '-' (negative)
    #
    # @example sign_of
    #   sign_of(5)   # => '+'
    #   sign_of(0)   # => '+'
    #   sign_of(-3)  # => '-'
    #
    # @api private
    def sign_of(x)
      '++-'[x <=> 0]
    end

    # Converts numeric velocity to dynamics marking.
    #
    # The exact inverse of the neumalang parser's absolute velocity rule, which
    # is generative rather than tabular -- `p+` and `f+` accept any number of
    # letters -- so this is generative too, and every integer has a name:
    #
    #     ... ppp (-3)  pp (-2)  p (-1)  mp (0)  mf (1)  f (2)  ff (3)  fff (4) ...
    #
    # Zero is `mp` and one is `mf`. That is not a convention chosen here: it is
    # what the parser reads and what {GDV::VELOCITY_MAP} encodes (64 and 80,
    # which are MuseScore's mp and mf).
    #
    # WHY NOT A TABLE. It used to be `%w[ppp pp p mp mf f ff fff][x + 3]`, and
    # eight entries could not name the ten the rest of the code works with:
    # below -3 the index went negative, Ruby counted from the end, and the
    # softest dynamics came back as the loudest -- `pppp`, which the notation
    # accepts and the parser reads as -4, was reprinted as `fff` (issue #74).
    #
    # This function is total on purpose. The dynamic range of MIDI is not its
    # business: {GDV#to_pdv} clamps to -5..+4 when it converts, which is where
    # the physical range actually ends.
    #
    # @param x [Numeric] velocity value (fractional values floor, as GDV
    #   interpolates them)
    # @return [String] dynamics marking
    #
    # @example velocity_of
    #   velocity_of(-3)  # => "ppp"
    #   velocity_of(0)   # => "mp"
    #   velocity_of(1)   # => "mf"
    #   velocity_of(4)   # => "fff"
    #
    # @example Beyond the named eight, which the notation reaches
    #   velocity_of(-4)  # => "pppp"
    #   velocity_of(-5)  # => "ppppp"
    #   velocity_of(5)   # => "ffff"
    #
    # @api private
    def velocity_of(x)
      x = x.floor

      case x <=> 0
      when -1 then 'p' * -x
      when 0 then 'mp'
      else x == 1 ? 'mf' : 'f' * (x - 1)
      end
    end

    # Formats modifier with parameters for Neuma notation.
    #
    # Converts modifier keys and their parameters into Neuma string format.
    #
    # @param modificator [Symbol] modifier key name
    # @param parameter_or_parameters [Boolean, Array, Object] modifier parameters
    # @return [String] formatted modifier string
    #
    # @example Boolean modifier (flag)
    #   modificator_string(:staccato, true)  # => 'staccato'
    #
    # @example Single parameter
    #   modificator_string(:pedal, 'down')  # => 'pedal("down")'
    #
    # @example Multiple parameters
    #   modificator_string(:bend, [2, 'up'])  # => 'bend(2, "up")'
    #
    # @api private
    def modificator_string(modificator, parameter_or_parameters)
      case parameter_or_parameters
      when true
        modificator.to_s
      when Array
        "#{modificator.to_s}(#{parameter_or_parameters.collect { |p| parameter_to_string(p) }.join(', ')})"
      else
        "#{modificator.to_s}(#{parameter_to_string(parameter_or_parameters)})"
      end
    end

    private

    # Converts parameter to string representation.
    #
    # Handles different parameter types for Neuma notation.
    #
    # @param parameter [String, Numeric, Symbol] parameter value
    # @return [String] formatted parameter
    #
    # @api private
    def parameter_to_string(parameter)
      case parameter
      when String
        "\"#{parameter}\""
      when Numeric
        "#{parameter}"
      when Symbol
        "#{parameter}"
      end
    end
  end
end