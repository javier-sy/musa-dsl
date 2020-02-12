require_relative 'transcription'

include Musa::Transcription

module Musa::Transcriptors
  module FromGDV
    # Process: .base .b
    class Base < FeatureTranscriptor
      def transcript(gdv, base_duration:, tick_duration:)
        base = gdv.delete :base
        base ||= gdv.delete :b

        base ? { duration: 0 }.extend(Musa::Datasets::D) : gdv
      end
    end
  end
end
