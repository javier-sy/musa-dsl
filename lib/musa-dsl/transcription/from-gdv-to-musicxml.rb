# MusicXML-specific GDV transcriptors for music notation output.
#
# Transcribes GDV events to MusicXML format, handling ornaments and articulations
# as notation metadata rather than expanded note sequences. MusicXML is an XML-based
# standard for representing Western music notation.
#
# ## MusicXML vs MIDI Approach
#
# MusicXML transcription differs from MIDI transcription:
#
# - **MusicXML**: Preserves ornaments as notation symbols (grace notes, trills, etc.)
# - **MIDI**: Expands ornaments to explicit note sequences for playback
#
# ## Supported Features
#
# - **Appogiatura**: Grace note ornaments marked with `:grace` attribute
#
# ## Usage
#
# ```ruby
# transcriptor = Musa::Transcription::Transcriptor.new(
#   Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
#   base_duration: 1/4r,
#   tick_duration: 1/96r
# )
# result = transcriptor.transcript(gdv_event)
# ```
#
# ## Transcription Set
#
# The `transcription_set` method returns an array of transcriptors applied
# in order:
#
# 1. `Appogiatura` - Process appogiatura ornaments
# 2. `Base` - Process base/rest markers
#
# @example MusicXML appogiatura
#   gdv = {
#     grade: 0,
#     duration: 1r,
#     appogiatura: { grade: -1, duration: 1/8r }
#   }
#   transcriptor = Musa::Transcriptors::FromGDV::ToMusicXML::Appogiatura.new
#   result = transcriptor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
#   # => [
#   #   { grade: -1, duration: 1/8r, grace: true },
#   #   { grade: 0, duration: 1r, graced: true, graced_by: {...} }
#   # ]
#
# @see Musa::Transcriptors::FromGDV::ToMIDI
# @see Musa::MusicXML
#
# @api public
require_relative 'from-gdv'

module Musa::Transcriptors
  module FromGDV
    # MusicXML-specific GDV transcriptors for music notation output.
    #
    # Transcribes GDV events to MusicXML format, preserving ornaments and
    # articulations as notation metadata rather than expanding them to note
    # sequences. This differs from MIDI transcription which expands ornaments
    # for playback.
    #
    # ## Supported Features
    #
    # - **Appogiatura**: Grace notes marked with `:grace` attribute
    # - **Base/Rest**: Zero-duration structural markers
    #
    # ## Usage
    #
    # Use {transcription_set} to get pre-configured transcriptor chain:
    # ```ruby
    # transcriptor = Musa::Transcription::Transcriptor.new(
    #   Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
    #   base_duration: 1/4r,
    #   tick_duration: 1/96r
    # )
    # ```
    #
    # @see ToMIDI Playback-oriented transcription
    # @see Musa::MusicXML MusicXML output system
    module ToMusicXML
      # Returns standard transcription set for MusicXML output.
      #
      # Creates array of transcriptors for processing GDV to MusicXML format.
      #
      # @return [Array<FeatureTranscriptor>] transcriptor chain
      #
      # @example Create MusicXML transcription chain
      #   transcriptors = Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set
      #   transcriptor = Musa::Transcription::Transcriptor.new(
      #     transcriptors,
      #     base_duration: 1/4r
      #   )
      #
      # @api public
      def self.transcription_set
        [ Appogiatura.new,
          Base.new ]
      end

      # Appogiatura transcriptor for MusicXML notation.
      #
      # Processes appogiatura ornaments, marking them as grace notes for MusicXML
      # output rather than expanding to explicit note sequences. The grace note
      # relationship is preserved through `:grace`, `:graced`, and `:graced_by`
      # attributes.
      #
      # ## Appogiatura Format
      #
      # Input GDV with `:appogiatura` key:
      # ```ruby
      # {
      #   grade: 0,
      #   duration: 1r,
      #   appogiatura: { grade: -1, duration: 1/8r }
      # }
      # ```
      #
      # Output (array of two events):
      # ```ruby
      # [
      #   { grade: -1, duration: 1/8r, grace: true },           # Grace note
      #   { grade: 0, duration: 1r, graced: true, graced_by: ... } # Main note
      # ]
      # ```
      #
      # ## MusicXML Representation
      #
      # The `:grace` attribute indicates the note should be rendered as a grace
      # note in the score. The `:graced_by` reference allows the notation engine
      # to properly link the grace note to its principal note.
      #
      # @example Process appogiatura
      #   app = Appogiatura.new
      #   gdv = {
      #     grade: 0,
      #     duration: 1r,
      #     appogiatura: { grade: -1, duration: 1/8r }
      #   }
      #   result = app.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
      #   # => [grace_note, main_note]
      #
      # @api public
      # Process: appogiatura (neuma)neuma
      class Appogiatura < Musa::Transcription::FeatureTranscriptor
        # Transcribes GDV appogiatura to grace note representation.
        #
        # @param gdv [Hash] GDV event possibly containing `:appogiatura`
        # @param base_duration [Rational] base duration unit
        # @param tick_duration [Rational] minimum tick duration
        #
        # @return [Array<Hash>, Hash] array with grace note and main note, or
        #   unchanged event if no appogiatura
        #
        # @api public
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
