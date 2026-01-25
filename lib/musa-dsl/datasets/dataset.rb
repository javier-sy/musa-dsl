# frozen_string_literal: true

# Musical dataset framework for MusaDSL.
#
# The Datasets module provides a comprehensive framework for representing and transforming
# musical events and data structures. It supports multiple representations (MIDI-style,
# score-style, serialized formats) and conversions between them.
#
# ## Architecture
#
# The framework consists of several layers:
#
# ### 1. Event Types ({E})
#
# Hierarchy of event types defining absolute vs. delta encoding:
#
# - **{E}**: Base event module
# - **{Abs}**: Absolute values (actual pitch, duration, etc.)
# - **{Delta}**: Delta values (incremental changes)
# - **{AbsI}**: Absolute indexed (array-based)
# - **{AbsTimed}**: Absolute with time component
# - **{AbsD}**: Absolute with duration
# - **{DeltaD}**: Delta duration (absolute/delta/factor)
#
# ### 2. Data Structures
#
# Basic container types:
#
# - **{V}**: Value array - simple ordered values
# - **{PackedV}**: Packed value hash - named key-value pairs
# - **{P}**: Pitch series - alternating values and durations
#
# ### 3. Musical Datasets
#
# Domain-specific musical representations:
#
# - **{PS}**: Pitch series (from/to/duration for glissandi)
# - **{PDV}**: Pitch/Duration/Velocity (MIDI-style representation)
# - **{GDV}**: Grade/Duration/Velocity (score-style with scale degrees)
# - **{GDVd}**: Grade/Duration/Velocity delta (incremental encoding)
#
# ### 4. Score Container
#
# - **{Score}**: Time-indexed container for musical events
#
# ## Basic Usage
#
#     # Create a packed value (hash)
#     pv = { a: 1, b: 2, c: 3 }.extend(Musa::Datasets::PackedV)
#
#     # Convert to array
#     v = pv.to_V([:c, :b, :a])  # => [3, 2, 1]
#
#     # Create pitch series
#     p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)
#     # [pitch, duration, pitch, duration, pitch]
#
#     # Convert to timed series
#     timed = p.to_timed_serie
#
# ## Conversion Patterns
#
# The framework supports rich conversions:
#
# - PackedV ↔ V (hash to array and vice versa)
# - P → PS (pitch series to glissando segments)
# - PDV ↔ GDV (MIDI to score notation)
# - GDV ↔ GDVd (absolute to delta encoding)
# - GDV → Neuma (score notation string format)
#
# @example MIDI-style pitch/duration/velocity
#   pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
#   pdv.base_duration = 1/4r
#
#   # Convert to score notation using scale
#   scale = Musa::Scales::Scales.et12[440.0].major[60]
#   gdv = pdv.to_gdv(scale)  # Uses scale degrees
#
# @example Score-style grade/duration/velocity
#   gdv = { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
#   gdv.base_duration = 1/4r
#
#   # Convert to MIDI using scale
#   scale = Musa::Scales::Scales.et12[440.0].major[60]
#   pdv = gdv.to_pdv(scale)  # Converts to MIDI pitches
#
# @example Delta encoding for compression
#   scale = Musa::Scales::Scales.et12[440.0].major[60]
#   gdv1 = { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
#   gdv2 = { grade: 2, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::GDV)
#
#   gdvd = gdv2.to_gdvd(scale, previous: gdv1)
#   # => { delta_grade: 2, delta_velocity: 1 }
#   # Duration unchanged, so omitted
#
# @example Score container
#   score = Musa::Datasets::Score.new
#   score.at(0, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
#   score.at(1, add: { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV))
#
# @see E Base event type
# @see PDV MIDI-style representation
# @see GDV Score-style representation
# @see Score Event container
module Musa::Datasets
  # Base marker module for dataset types.
  #
  # Dataset is a simple marker module included by various dataset types
  # to indicate they are part of the dataset framework.
  #
  # @see E Event base module
  # @see P Pitch series dataset
  module Dataset; end
end