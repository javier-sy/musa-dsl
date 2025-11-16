# GDV (Grade-Duration-Velocity) base transcriptor for processing fundamental features.
#
# Provides the foundational transcriptor for handling base/rest events in GDV notation.
# GDV is Musa-DSL's internal representation for musical events with grade (pitch),
# duration, and velocity information.
#
# ## GDV Format
#
# GDV events are hashes with musical attributes:
# ```ruby
# {
#   grade: 0,          # Scale degree
#   duration: 1r,      # Rational duration
#   velocity: 0.8,     # Note velocity (0.0-1.0)
#   base: true         # Mark as base/rest (zero duration)
# }
# ```
#
# ## Base/Rest Processing
#
# The `.base` (or `.b`) attribute marks an event as a base or rest, which is
# converted to a zero-duration event. This is useful for representing rests
# or structural markers in the musical timeline.
#
# ## Transcriptor Pattern
#
# All transcriptors follow the same pattern:
#
# 1. Extract specific features from GDV hash
# 2. Process/transform the event based on those features
# 3. Return modified event(s) or array of events
#
# @example Basic base event
#   gdv = { grade: 0, duration: 1r, base: true }
#   transcriptor = Musa::Transcriptors::FromGDV::Base.new
#   result = transcriptor.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
#   # => { duration: 0 } (marked as AbsD)
#
# @see Musa::Transcription::FeatureTranscriptor
# @see Musa::Transcription::Transcriptor
#
# @api public
require_relative 'transcription'

module Musa::Transcriptors
  module FromGDV
    # Base transcriptor for processing `.base` or `.b` attributes.
    #
    # Converts GDV events marked with `:base` or `:b` to zero-duration events,
    # useful for representing rests or structural markers.
    #
    # ## Processing
    #
    # - Checks for `:base` or `:b` attribute
    # - If found, replaces event with `{duration: 0}` marked as `AbsD`
    # - If not found, passes through unchanged
    #
    # @example Process base event
    #   base = Base.new
    #   gdv = { grade: 0, duration: 1r, base: true }
    #   result = base.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
    #   # => { duration: 0 }
    #
    # @example Normal event (unchanged)
    #   gdv = { grade: 0, duration: 1r }
    #   result = base.transcript(gdv, base_duration: 1/4r, tick_duration: 1/96r)
    #   # => { grade: 0, duration: 1r }
    #
    # @api public
    class Base < Musa::Transcription::FeatureTranscriptor
      # Transcribes GDV event, converting base markers to zero-duration events.
      #
      # @param gdv [Hash] GDV event with musical attributes
      # @param base_duration [Rational] base duration unit (e.g., quarter note)
      # @param tick_duration [Rational] minimum tick duration (e.g., 1/96)
      #
      # @return [Hash] transcribed event (zero-duration if base, unchanged otherwise)
      #
      # @api public
      def transcript(gdv, base_duration:, tick_duration:)
        base = gdv.delete :base
        base ||= gdv.delete :b

        super base ? { duration: 0 }.extend(Musa::Datasets::AbsD) : gdv, base_duration: base_duration, tick_duration: tick_duration
      end
    end
  end
end
