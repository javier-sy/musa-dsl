# Array refinement for converting to neuma series.
#
# Adds methods to Array class for converting arrays of neuma elements (strings,
# neuma objects) into merged series. Enables convenient composition of multiple
# neuma sequences.
#
# ## Array to Neumas Conversion
#
# Arrays are converted using `MERGE` to create sequential series:
# ```ruby
# ["0 +2 +4", "+5 +7"].to_neumas
# # Equivalent to:
# MERGE("0 +2 +4".to_neumas, "+5 +7".to_neumas)
# ```
#
# ## Element Types
#
# Array elements can be:
# - **Strings**: Parsed as neuma notation
# - **Neuma::Serie**: Used directly
# - **Neuma::Parallel**: Wrapped in series
#
# ## Usage with Refinement
#
# This is a refinement - must be activated with `using`:
# ```ruby
# using Musa::Extension::Neumas
#
# phrases = [
#   "0 +2 +4 +5",    # First phrase
#   "+7 +5 +4 +2",   # Second phrase
#   "0 -2 -4 -5"     # Third phrase
# ].to_neumas
# ```
#
# ## Musical Applications
#
# - **Phrase composition**: Combine multiple musical phrases
# - **Section building**: Assemble larger structures from fragments
# - **Pattern sequencing**: Chain melodic/rhythmic patterns
# - **Mixed sources**: Combine string notation with existing neuma objects
#
# @example Sequential phrases
#   using Musa::Extension::Neumas
#
#   melody = [
#     "0 +2 +4 +5",    # Phrase A
#     "+7 +5 +4 +2",   # Phrase B
#     "0 -2 -4 -5"     # Phrase C
#   ].to_neumas
#
# @example Mixed element types
#   using Musa::Extension::Neumas
#
#   intro = "0 +2 +4".to_neumas
#   verse = "0 +2 +2 -1 0"
#   chorus = "+7 +5 +7"
#
#   song = [intro, verse, chorus].to_neumas
#
# @example Single element
#   using Musa::Extension::Neumas
#
#   # Single element returns converted element directly (not merged)
#   single = ["0 +2 +4"].to_neumas
#
# @see Musa::Series::Constructors.MERGE
# @see Musa::Extension::Neumas String refinement
#
# @api public
require_relative '../series'
require_relative '../neumalang'

module Musa
  module Extension
    module Neumas
      # Array refinement adding neuma conversion methods.
      #
      # Must be activated with `using Musa::Extension::Neumas`.
      #
      # @api public
      refine Array do
        # Converts array elements to merged neuma series.
        #
        # - Single element: Returns converted element directly
        # - Multiple elements: Returns MERGE of all converted elements
        #
        # Each element is converted based on its type:
        # - String → parsed as neuma notation
        # - Neuma::Serie → used directly
        # - Neuma::Parallel → wrapped in series
        #
        # @return [Serie, Neuma] merged series or single neuma
        #
        # @raise [ArgumentError] if element type cannot be converted
        #
        # @example Convert string array
        #   using Musa::Extension::Neumas
        #
        #   phrases = [
        #     "0 +2 +4",
        #     "+5 +7"
        #   ].to_neumas
        #   # Returns MERGE of two parsed series
        #
        # @example Mixed types
        #   using Musa::Extension::Neumas
        #
        #   existing = "0 +2".to_neumas
        #   combined = [existing, "+4 +5"].to_neumas
        #
        # @example Single element
        #   using Musa::Extension::Neumas
        #
        #   single = ["0 +2 +4"].to_neumas
        #   # Returns parsed series directly (not merged)
        #
        # @api public
        def to_neumas
          if length > 1
            Musa::Series::Constructors.MERGE(*collect { |e| convert_to_neumas(e) })
          else
            convert_to_neumas(first)
          end
        end

        # Alias for `to_neumas`.
        #
        # @api public
        alias_method :neumas, :to_neumas

        # Short alias for `to_neumas`.
        #
        # @api public
        alias_method :n, :to_neumas

        private

        # Converts element to neuma based on type.
        #
        # @param e [Object] element to convert
        #
        # @return [Serie] converted neuma serie
        #
        # @raise [ArgumentError] if type cannot be converted
        #
        # @api private
        def convert_to_neumas(e)
          case e
          when Musa::Neumas::Neuma::Serie then e
          when Musa::Neumas::Neuma::Parallel then Musa::Series::Constructors.S(e).extend(Musa::Neumas::Neuma::Serie)
          when String then e.to_neumas
          else
            raise ArgumentError, "Don't know how to convert to neumas #{e}"
          end
        end
      end
    end
  end
end

