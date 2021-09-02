require_relative 'transcription'

module Musa::Transcriptors
  module FromGDV
    # Process: .base .b
    class Base < Musa::Transcription::FeatureTranscriptor
      def transcript(gdv, base_duration:, tick_duration:)
        base = gdv.delete :base
        base ||= gdv.delete :b

        super base ? { duration: 0 }.extend(Musa::Datasets::AbsD) : gdv, base_duration: base_duration, tick_duration: tick_duration
      end
    end
  end
end
