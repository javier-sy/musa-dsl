module Musa::Datasets
  # Helper utilities for dataset formatting and string generation.
  #
  # Helper provides utility methods for converting datasets to string
  # representations, particularly for the Neuma notation format.
  #
  # These methods handle:
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
    # @example
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
    # @example
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
    # Maps velocity values (-5 to +4) to standard dynamics markings.
    # Range: ppp (-5) to fff (+4), centered at mf (0).
    #
    # @param x [Integer] velocity value
    # @return [String] dynamics marking
    #
    # @example
    #   velocity_of(-5)  # => 'ppp'
    #   velocity_of(0)   # => 'mf'
    #   velocity_of(4)   # => 'fff'
    #
    # @api private
    def velocity_of(x)
      %w[ppp pp p mp mf f ff fff][x + 3]
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