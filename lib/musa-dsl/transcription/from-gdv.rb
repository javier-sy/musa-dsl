require_relative 'transcription'

include Musa::Transcription

module Musa::Transcriptors
  module FromGDV
    # Process: .base .b
    class Base < FeatureTranscriptor
      def transcript(gdv, base_duration:, tick_duration:)
        base = gdv.delete :base
        base ||= gdv.delete :b

        super base ? { duration: 0 }.extend(Musa::Datasets::AbsD) : gdv, base_duration: base_duration, tick_duration: tick_duration
      end
    end
  end
end
