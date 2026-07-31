require_relative 'string-to-neumas'

using Musa::Extension::Neumas

module Musa
  # Neuma notation system namespace.
  #
  # Contains all neuma-related modules, classes, and functionality.
  #
  # @api public
  module Neumas
    # Base neuma module for serie and parallel structures.
    #
    # Mixed into neuma hashes to provide structure-specific methods.
    # Neumas are extended with either `Neuma::Serie` or `Neuma::Parallel`.
    #
    # @api public
    module Neuma
      # Parallel neuma structure (polyphonic).
      #
      # Represents simultaneous musical events (multiple voices, chords).
      # Contains array of neuma series in `:parallel` key.
      #
      # The shape it takes (a structure, not a runnable example):
      #
      #     { kind: :parallel,
      #       parallel: [{ kind: :serie, serie: melody_neumas },
      #                  { kind: :serie, serie: bass_neumas }] }.extend(Parallel)
      #
      # It is built by {Neuma#|} rather than written out; see there.
      #
      # @api public
      module Parallel
        include Neuma
      end

      # Serie neuma structure (monophonic).
      #
      # Represents sequential musical events (single voice melody).
      # Contains array of neuma objects in `:serie` key.
      #
      # The shape it takes (a structure, not a runnable example):
      #
      #     { kind: :serie, serie: [neuma1, neuma2, neuma3] }.extend(Serie)
      #
      # @api public
      module Serie
        include Neuma
      end

      # Creates parallel structure with another neuma.
      #
      # Combines this neuma with another into parallel (polyphonic) structure.
      # If already parallel, adds to existing parallel array.
      #
      # @param other [String, Neuma] neuma to parallelize with
      #
      # @return [Parallel] parallel neuma structure
      #
      # @raise [ArgumentError] if other cannot be converted
      #
      # @example Create parallel from neumas
      #   using Musa::Extension::Neumas  # refinements are per file
      #
      #   # The voices are parallelised as notation. The right operand has to be
      #   # something convertible to neumas -- a String -- so an already parsed
      #   # serie works on the left but not on the right.
      #   harmony = "(0) (+2) (+4)" | "(-7) (-5) (-3)"
      #
      #   harmony[:kind]           # => :parallel
      #   harmony[:parallel].size  # => 2
      #
      # @example Chain multiple parallels
      #   using Musa::Extension::Neumas
      #
      #   satb = "(+7) (+9)" | "(+4) (+5)" | "(0) (+2)" | "(-7) (-5)"
      #
      #   # Chaining adds to the existing parallel instead of nesting it.
      #   satb[:parallel].size  # => 4
      #
      # @api public
      def |(other)
        if is_a?(Parallel)
          clone.tap { |_| _[:parallel] << convert_to_parallel_element(other) }.extend(Parallel)
        else
          { kind: :parallel,
            parallel: [clone, convert_to_parallel_element(other)]
          }.extend(Parallel)
        end
      end

      private

      # Converts element to parallel-compatible format.
      #
      # @param e [String, Neuma] element to convert
      #
      # @return [Hash] neuma serie structure
      #
      # @raise [ArgumentError] if cannot convert
      #
      # @api private
      def convert_to_parallel_element(e)
        case e
        when String then { kind: :serie, serie: e.to_neumas }.extend(Neuma)
        else
          raise ArgumentError, "Don't know how to convert to neumas #{e}"
        end
      end
    end
  end
end
