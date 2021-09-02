require_relative 'from-gdv'

module Musa::Transcriptors
  module FromGDV
    module ToMusicXML
      def self.transcription_set
        [ Appogiatura.new,
          Base.new ]
      end

      # Process: appogiatura (neuma)neuma
      class Appogiatura < Musa::Transcription::FeatureTranscriptor
        def transcript(gdv, base_duration:, tick_duration:)
          if gdv_appogiatura = gdv[:appogiatura]
            gdv.delete :appogiatura

            # TODO process with Decorators the gdv_appogiatura
            # TODO implement also posterior appogiatura neuma(neuma)
            # TODO implement also multiple appogiatura with several notes (neuma ... neuma)neuma or neuma(neuma ... neuma)

            gdv_appogiatura[:grace] = true
            gdv[:graced] = true
            gdv[:graced_by] = gdv_appogiatura

            [ gdv_appogiatura, gdv ]
          else
            gdv
          end
        end
      end
    end
  end
end
