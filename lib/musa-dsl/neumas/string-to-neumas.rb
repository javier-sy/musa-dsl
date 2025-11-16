# String refinement for parsing neuma notation.
#
# Adds methods to String class for converting text-based neuma notation into
# structured neuma objects. Uses Neumalang parser to process the notation.
#
# ## Neuma Notation Syntax
#
# Neuma notation is a compact text format for musical sequences:
#
# ### Grade (Pitch)
# ```ruby
# "0"         # Absolute grade 0
# "+2"        # Up 2 scale steps
# "-1"        # Down 1 scale step
# "^3"        # Up 3 octaves
# "v1"        # Down 1 octave
# ```
#
# ### Duration
# ```ruby
# "_"         # Base duration
# "_2"        # Double duration (half note if base is quarter)
# "_/2"       # Half duration (eighth note if base is quarter)
# "_3/2"      # 1.5x duration (dotted)
# ```
#
# ### Ornaments & Articulations
# ```ruby
# ".tr"       # Trill
# ".mor"      # Mordent
# ".turn"     # Turn
# ".st"       # Staccato
# ```
#
# ### Grace Notes (Appogiatura)
# ```ruby
# "(+1_/4)+2_"   # Grace note +1 (1/4 duration) before main note +2
# ```
#
# ### Complete Examples
# ```ruby
# "0 +2 +2 -1 0"              # Simple melodic sequence
# "+2_ +2_2 +1_/2"            # With duration variations
# "+2.tr +3.mor -1.st"        # With ornaments
# "(+1_/4)+2_ +2_"            # With appogiatura
# ```
#
# ## Parallel Notation
#
# Use `|` operator to create parallel (polyphonic) structures:
# ```ruby
# "0 +2 +4" | "+7 +5 +7"      # Two voices in parallel
# ```
#
# ## Usage with Refinement
#
# This is a refinement - must be activated with `using`:
# ```ruby
# using Musa::Extension::Neumas
#
# melody = "0 +2 +2 -1 0".to_neumas
# # or shorter:
# melody = "0 +2 +2 -1 0".n
# ```
#
# ## Integration with Decoders
#
# Parsed neumas are typically decoded to GDV:
# ```ruby
# using Musa::Extension::Neumas
#
# neumas = "0 +2 +2 -1 0".to_neumas
# scale = Musa::Scales::Scales.et12[440.0].major[60]
# decoder = NeumaDecoder.new(scale, base_duration: 1/4r)
# gdvs = neumas.map { |neuma| decoder.decode(neuma) }
# ```
#
# @example Basic parsing
#   using Musa::Extension::Neumas
#
#   melody = "0 +2 +2 -1 0".to_neumas
#   # Returns series of GDVD hashes
#
# @example With ornaments
#   using Musa::Extension::Neumas
#
#   ornate = "+2.tr +3.mor -1.st".to_neumas
#
# @example Parallel voices
#   using Musa::Extension::Neumas
#
#   harmony = "0 +2 +4" | "+7 +5 +7"
#
# @example Convert to generative node
#   using Musa::Extension::Neumas
#
#   node = "0 +2 +2 -1 0".nn  # to_neumas_to_node
#
# @see Musa::Neumalang
# @see Musa::Neumas::Decoders::NeumaDecoder
# @see Musa::Generative
#
# @api public
require_relative '../neumalang'
require_relative '../generative/generative-grammar'

module Musa
  module Extension
    # Namespace for neuma-related refinements.
    #
    # Contains refinements for String and Array to support neuma notation.
    #
    # @api public
    module Neumas
      # String refinement adding neuma parsing methods.
      #
      # Must be activated with `using Musa::Extension::Neumas`.
      #
      # @api public
      refine String do
        # Parses neuma notation string to structured neumas.
        #
        # Uses Neumalang parser to convert text notation into GDVD (differential)
        # neuma objects that can be decoded to GDV events.
        #
        # @param decode_with [Decoder, nil] optional decoder to apply immediately
        # @param debug [Boolean, nil] enable debug output from parser
        #
        # @return [Serie, Array] parsed neuma series or array
        #
        # @example Parse simple melody
        #   using Musa::Extension::Neumas
        #   neumas = "0 +2 +2 -1 0".to_neumas
        #
        # @example Parse with immediate decoding
        #   scale = Musa::Scales::Scales.et12[440.0].major[60]
        #   decoder = NeumaDecoder.new(scale)
        #   gdvs = "0 +2 +2 -1 0".to_neumas(decode_with: decoder)
        #
        # @example Parse with debug
        #   neumas = "0 +2 +2".to_neumas(debug: true)
        #
        # @api public
        def to_neumas(decode_with: nil, debug: nil)
          Musa::Neumalang::Neumalang.parse(self, decode_with: decode_with, debug: debug)
        end

        # Parses neuma notation and converts to generative node.
        #
        # Combines parsing with node conversion for use in generative grammars.
        #
        # @param decode_with [Decoder, nil] optional decoder to apply
        # @param debug [Boolean, nil] enable debug output
        #
        # @return [Node] generative node structure
        #
        # @example Convert to node for generative grammar
        #   using Musa::Extension::Neumas
        #   node = "0 +2 +2 -1 0".to_neumas_to_node
        #
        # @see Musa::Generative
        #
        # @api public
        def to_neumas_to_node(decode_with: nil, debug: nil)
          to_neumas(decode_with: decode_with, debug: debug).to_node
        end

        # Creates parallel neuma structure.
        #
        # Combines two neuma strings into parallel (polyphonic) structure.
        # Both voices are parsed and wrapped in parallel container.
        #
        # @param other [String] second neuma string to parallelize
        #
        # @return [Hash] parallel neuma structure with two series
        #
        # @raise [ArgumentError] if other is not a String
        #
        # @example Two-voice harmony
        #   using Musa::Extension::Neumas
        #
        #   melody = "0 +2 +4 +5"
        #   bass = "-7 -5 -3 -1"
        #   harmony = melody | bass
        #
        # @api public
        def |(other)
          case other
          when String
            { kind: :parallel,
              parallel: [{ kind: :serie, serie: self.to_neumas },
                         { kind: :serie, serie: other.to_neumas }] }.extend(Musa::Neumas::Neuma::Parallel)
          else
            raise ArgumentError, "Don't know how to parallelize #{other}"
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

        # Short alias for `to_neumas_to_node`.
        #
        # @api public
        alias_method :nn, :to_neumas_to_node
      end
    end
  end
end
