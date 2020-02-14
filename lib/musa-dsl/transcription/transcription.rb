module Musa
  module Transcription
    class Transcriptor
      attr_reader :transcriptors

      def initialize(transcriptors = nil, base_duration: nil, tick_duration: nil)
        @transcriptors = transcriptors || []

        @base_duration = base_duration || 1/4r
        @tick_duration = tick_duration || 1/96r
      end

      def transcript(element)
        @transcriptors.each do |transcriptor|
          if element
            if element.is_a?(Array)
              element = element.collect { |element_i| transcriptor.transcript(element_i, base_duration: @base_duration, tick_duration: @tick_duration) }.flatten(1)
            else
              element = transcriptor.transcript(element, base_duration: @base_duration, tick_duration: @tick_duration)
            end
          end
        end

        element
      end
    end

    class FeatureTranscriptor
      def transcript(element, base_duration:, tick_duration:)
        element
      end

      def check(value_or_array)
        if block_given?
          if value_or_array.is_a?(Array)
            value_or_array.each { |value| yield value }
          else
            yield value_or_array
          end
        end
      end
    end
  end

  module Transcriptors; end
end