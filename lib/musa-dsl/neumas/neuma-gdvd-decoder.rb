# GDVD neuma decoder for preserving differential format.
#
# Simple decoder that processes GDVD (Grade-Duration-Velocity-Differential) neumas
# without converting to absolute GDV format. Useful when you need to work with
# differential values directly or perform intermediate processing.
#
# ## GDVD Format
#
# GDVD maintains relative/differential values:
# ```ruby
# {
#   grade_diff: +2,        # Relative grade change
#   duration_factor: 2,    # Duration multiplier
#   velocity_factor: 1.2,  # Velocity multiplier
#   modifiers: {...}       # Ornaments, articulations
# }
# ```
#
# ## Use Cases
#
# - **Intermediate processing**: Transform neumas before converting to GDV
# - **Pattern analysis**: Analyze melodic intervals without absolute pitch
# - **Transposition**: Work with relative values for easy transposition
#
# ## vs NeumaDecoder
#
# - **NeumaDifferentialDecoder**: Keeps differential format (GDVD)
# - **NeumaDecoder**: Converts to absolute format (GDV) using scale
#
# @example Process GDVD
#   decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new(
#     base_duration: 1/4r
#   )
#
#   gdvd = decoder.decode({ grade_diff: +2, duration_factor: 2 })
#   # => { grade_diff: +2, duration_factor: 2, base_duration: 1/4r }
#   # Still differential, not converted to absolute
#
# @example Intermediate processing workflow
#   # Process neumas in differential format before final conversion
#   using Musa::Extension::Neumas
#
#   neumas = "0 +2 +2 -1 0".to_neumas
#   differential_decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new
#
#   # Process each neuma (keeping differential format)
#   gdvds = []
#   neumas.i.each do |neuma|
#     gdvd = differential_decoder.decode(neuma[:gdvd])
#     gdvds << gdvd
#   end
#
#   # GDVD objects still have differential values
#   # Can transform them before converting to absolute GDV
#
# @see Musa::Neumas::Decoders::NeumaDecoder
# @see Musa::Neumas::Decoders::DifferentialDecoder
#
# @api public
require_relative 'neuma-decoder'

module Musa::Neumas
  module Decoders
    # Differential decoder that preserves GDVD format.
    #
    # Processes GDVD neumas by setting base_duration but keeping differential
    # values intact. Does not convert to absolute GDV format.
    #
    # ## Processing
    #
    # Only sets `base_duration` on GDVD for duration calculations:
    # ```ruby
    # Input:  { grade_diff: +2, duration_factor: 2 }
    # Output: { grade_diff: +2, duration_factor: 2, base_duration: 1/4r }
    # ```
    #
    # @api public
    class NeumaDifferentialDecoder < DifferentialDecoder # to get a GDVd
      # Creates differential GDVD decoder.
      #
      # @param base_duration [Rational, nil] base duration unit (default: 1/4)
      #
      # @example Create decoder with eighth note base
      #   decoder = NeumaDifferentialDecoder.new(base_duration: 1/8r)
      #
      # @api public
      def initialize(base_duration: nil)
        @base_duration = base_duration || Rational(1,4)
      end

      # Processes GDVD by setting base_duration.
      #
      # Clones GDVD and sets base_duration for duration calculations.
      # Does not convert to absolute values.
      #
      # @param gdvd [Hash] GDVD attributes
      #
      # @return [Hash] GDVD with base_duration set
      #
      # @example Process differential neuma
      #   gdvd = { grade_diff: +2, duration_factor: 2 }
      #   result = decoder.process(gdvd)
      #   # => { grade_diff: +2, duration_factor: 2, base_duration: 1/4r }
      #
      # @api public
      def process(gdvd)
        gdvd.clone.tap { |_| _.base_duration = @base_duration }
      end
    end
  end
end