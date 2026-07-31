require_relative 'neuma-decoder'

module Musa::Neumas
  module Decoders
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
    #   # The keys are GDVd's own, and the event must carry the dataset: a bare
    #   # hash has no base_duration to set.
    #   gdvd = decoder.decode({ delta_grade: 2, factor_duration: 2 }.extend(Musa::Datasets::GDVd))
    #   gdvd  # => { delta_grade: 2, factor_duration: 2 }
    #   gdvd.base_duration  # => 1/4r
    #   # Still differential, not converted to absolute
    #
    # @example Intermediate processing workflow
    #   # Process neumas in differential format before final conversion
    #   using Musa::Extension::Neumas
    #
    #   neumas = "(0) (+2) (+2) (-1) (0)".to_neumas
    #   differential_decoder = Musa::Neumas::Decoders::NeumaDifferentialDecoder.new
    #
    #   # Process each neuma, keeping the differential format. A serie has no
    #   # `each`: `map` is a serie operation and stays lazy until consumed.
    #   gdvds = neumas.map { |neuma| differential_decoder.decode(neuma[:gdvd]) }
    #
    #   gdvds.i.to_a
    #   # => [{ abs_grade: 0 }, { delta_grade: 2 }, { delta_grade: 2 },
    #   #     { delta_grade: -1 }, { abs_grade: 0 }]
    #   # Still differential, and transformable before converting to absolute GDV
    #
    # @see Musa::Neumas::Decoders::NeumaDecoder
    # @see Musa::Neumas::Decoders::DifferentialDecoder
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
      #   quarters = NeumaDifferentialDecoder.new(base_duration: 1/4r)
      #   gdvd = { delta_grade: 2, factor_duration: 2 }.extend(Musa::Datasets::GDVd)
      #   result = quarters.process(gdvd)
      #   result  # => { delta_grade: 2, factor_duration: 2 }
      #   result.base_duration  # => 1/4r
      #   # base_duration travels with the event, it is not one of its keys
      #
      # @api public
      def process(gdvd)
        gdvd.clone.tap { |_| _.base_duration = @base_duration }
      end
    end
  end
end