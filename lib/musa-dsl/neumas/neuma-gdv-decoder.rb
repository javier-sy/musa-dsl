require_relative 'neuma-decoder'

module Musa::Neumas
  module Decoders
    class NeumaDecoder < Decoder # to get a GDV
      def initialize(scale, base_duration: nil, transcriptor: nil, base: nil)
        @base_duration = base_duration
        @base_duration ||= base[:duration] if base
        @base_duration ||= Rational(1,4)

        base ||= { grade: 0, octave: 0, duration: @base_duration, velocity: 1 }

        @scale = scale

        super base, transcriptor: transcriptor
      end

      attr_accessor :scale, :base_duration

      def process(gdvd)
        gdvd = gdvd.clone

        gdvd.base_duration = @base_duration

        appogiatura_gdvd = gdvd[:modifiers]&.delete :appogiatura

        if appogiatura_gdvd
          appogiatura_gdvd = appogiatura_gdvd.clone
          appogiatura_gdvd.base_duration = @base_duration

          gdvd[:modifiers][:appogiatura] = appogiatura_gdvd
        end

        gdvd
      end

      def subcontext
        NeumaDecoder.new @scale, base_duration: @base_duration, transcriptor: @transcriptor, base: @last
      end

      def apply(gdvd, on:)
        gdv = gdvd.to_gdv @scale, previous: on

        appogiatura_action = gdvd.dig(:modifiers, :appogiatura)
        gdv[:appogiatura] = appogiatura_action.to_gdv @scale, previous: on if appogiatura_action

        gdv
      end

      def inspect
        "GDV NeumaDecoder: @last = #{@last}"
      end

      alias to_s inspect
    end
  end
end
