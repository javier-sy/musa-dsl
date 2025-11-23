# Neuma notation system for text-based musical representation.
#
# Neumas provide a compact, human-readable text format for musical notation.
# The system combines parsing, differential decoding, and integration with
# Musa-DSL's series and transcription systems.
#
# ## Architecture Overview
#
# ### Components
#
# 1. **Notation** (`string-to-neumas.rb`, `array-to-neumas.rb`)
#    - String/Array refinements for parsing neuma notation
#    - Text format: `"0 +2 +2 -1 0 .tr .mor"`
#
# 2. **Parsing** (via `Neumalang` parser)
#    - Converts text notation to structured GDVD objects
#    - Handles grade, duration, ornaments, articulations
#
# 3. **Decoding** (`neuma-decoder.rb`, `neuma-gdv-decoder.rb`, `neuma-gdvd-decoder.rb`)
#    - Converts differential GDVD to absolute GDV
#    - Stateful processing with context tracking
#    - Integration with scales and transcriptors
#
# 4. **Structure** (`neumas.rb`)
#    - `Neuma::Serie` - Sequential neuma structures
#    - `Neuma::Parallel` - Polyphonic neuma structures
#
# ## Neuma Notation Syntax
#
# ### Grade (Pitch in Scale Steps)
# ```ruby
# "0"         # Absolute grade 0 (tonic)
# "+2"        # Relative: up 2 steps
# "-1"        # Relative: down 1 step
# "^2"        # Up 2 octaves
# "v1"        # Down 1 octave
# ```
#
# ### Duration (Rhythmic Values)
# ```ruby
# "_"         # Base duration (e.g., quarter note)
# "_2"        # Double (half note)
# "_/2"       # Half (eighth note)
# "_3/2"      # Dotted (1.5x)
# "_*3"       # Triple
# ```
#
# ### Ornaments & Articulations
# ```ruby
# ".tr"       # Trill
# ".mor"      # Mordent
# ".turn"     # Turn
# ".st"       # Staccato
# ".b"        # Base/rest (zero duration)
# ```
#
# ### Grace Notes (Appogiatura)
# ```ruby
# "(+1_/4)+2_"   # Grace note before main note
# ```
#
# ### Complete Sequences
# ```ruby
# "0 +2 +2 -1 0"                      # Simple melody
# "+2_ +2_2 +1_/2 +2_"                # With durations
# "+2.tr +3.mor -1.st +2_"            # With ornaments
# "(+1_/4)+2_ +2_ +3_ +2_"            # With grace notes
# "0 +2 +4" | "+7 +5 +7"              # Parallel (polyphonic)
# ```
#
# ## Data Flow
#
# ```ruby
# Text Notation → Parser → GDVD → Decoder → GDV → Transcriptor → MIDI/MusicXML
# "0 +2 +2"       ↓          ↓         ↓       ↓
#               Neuma    Differential Absolute  Ornament
#               Object    Format      Format    Expansion
# ```
#
# ## Differential vs Absolute
#
# - **GDVD** (Grade-Duration-Velocity-Differential): Relative values
#   ```ruby
#   { grade_diff: +2, duration_factor: 2 }  # "Up 2 steps, double duration"
#   ```
#
# - **GDV** (Grade-Duration-Velocity): Absolute values
#   ```ruby
#   { grade: 2, octave: 0, duration: 1/2r, velocity: 1 }  # Ready for playback
#   ```
#
# ## Basic Usage
#
# ```ruby
# using Musa::Extension::Neumas
#
# # 1. Parse neuma notation
# neumas = "0 +2 +2 -1 0".to_neumas  # or .n for short
#
# # 2. Access parsed GDVD (differential) values
# neumas.i.each do |neuma|
#   gdvd = neuma[:gdvd]
#   puts "Grade diff: #{gdvd[:delta_grade]}"
#   puts "Duration: #{gdvd[:abs_duration]}"
# end
#
# # 3. Create decoder for absolute values (requires scale)
# # decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)
#
# # 4. Decode to GDV events (absolute values)
# # gdvs = neumas.map { |neuma| decoder.decode(neuma) }.flatten
# ```
#
# ## Neuma Structures
#
# Neumas can be organized as:
# - **Serie**: Sequential notes (monophonic)
# - **Parallel**: Simultaneous notes (polyphonic)
#
# Use `|` operator to create parallel structures:
# ```ruby
# melody = "0 +2 +4 +5"
# bass = "-7 -5 -3 -1"
# harmony = melody | bass  # Parallel structure
# ```
#
# ## Integration
#
# Neumas integrate with:
# - **Scales**: Grade values interpreted through scales
# - **Series**: Neuma notation generates series
# - **Transcription**: Ornaments expanded via transcriptors
# - **Sequencer**: GDV events played via sequencer
# - **Generative**: Neumas can be generative nodes
#
# ## Musical Applications
#
# - **Compact notation**: Quick melodic/rhythmic entry
# - **Algorithmic composition**: Generate neuma strings programmatically
# - **Pattern libraries**: Store and reuse musical patterns
# - **Live coding**: Real-time pattern manipulation
# - **Score representation**: Text-based music storage
#
# @example Basic neuma parsing
#   using Musa::Extension::Neumas
#
#   # Parse simple melody notation
#   melody = "0 +2 +2 -1 0".to_neumas
#
#   # Iterate through parsed neumas
#   melody.i.each do |neuma|
#     puts "GDVD: #{neuma.inspect}"
#   end
#
# @example Parse with duration and ornaments
#   using Musa::Extension::Neumas
#
#   # Neuma with varied durations and ornaments
#   notation = "+2_ +2_2 +1_/2 +2_.tr"
#   neumas = notation.to_neumas
#
#   # Access differential values
#   neumas.i.first.tap do |first_neuma|
#     puts "Grade diff: #{first_neuma[:gdvd][:delta_grade]}"
#     puts "Duration: #{first_neuma[:gdvd][:abs_duration]}"
#   end
#
# @example Create parallel voices
#   using Musa::Extension::Neumas
#
#   # Define individual voice lines
#   soprano = "0 +2 +4 +5 +7"
#   alto = "-2 0 +2 +3 +5"
#   tenor = "-5 -3 -1 0 +2"
#   bass = "-9 -7 -5 -4 -2"
#
#   # Combine into parallel (polyphonic) structure
#   satb = soprano | alto | tenor | bass
#
#   # Verify structure
#   satb[:kind]             # => :parallel
#   satb[:parallel].size    # => 4 voices
#
# @example Compose sections from arrays
#   using Musa::Extension::Neumas
#
#   # Define musical sections
#   verse = "0 +2 +2 -1 0"
#   chorus = "+7 +5 +7 +5 +4"
#   bridge = "+2 +4 +5 +4 +2"
#
#   # Create song structure (verse-chorus-verse-chorus-bridge-chorus)
#   song = [verse, chorus, verse, chorus, bridge, chorus].to_neumas
#
#   # Count total neumas
#   song.i.to_a.size   # => Combined count from all sections
#
# @see Musa::Neumalang
# @see Musa::Neumas::Decoders
# @see Musa::Extension::Neumas
# @see Musa::Scales
# @see Musa::Transcription
#
# @api public
require_relative 'string-to-neumas'

using Musa::Extension::Neumas

module Musa
  # Neuma notation system namespace.
  #
  # Contains all neuma-related modules, classes, and functionality.
  #
  # @api public
  module Neumas
    # Base neuma module for serie and parallel structures.
    #
    # Mixed into neuma hashes to provide structure-specific methods.
    # Neumas are extended with either `Neuma::Serie` or `Neuma::Parallel`.
    #
    # @api public
    module Neuma
      # Parallel neuma structure (polyphonic).
      #
      # Represents simultaneous musical events (multiple voices, chords).
      # Contains array of neuma series in `:parallel` key.
      #
      # @example Parallel structure
      #   {
      #     kind: :parallel,
      #     parallel: [
      #       { kind: :serie, serie: melody_neumas },
      #       { kind: :serie, serie: bass_neumas }
      #     ]
      #   }.extend(Musa::Neumas::Neuma::Parallel)
      #
      # @api public
      module Parallel
        include Neuma
      end

      # Serie neuma structure (monophonic).
      #
      # Represents sequential musical events (single voice melody).
      # Contains array of neuma objects in `:serie` key.
      #
      # @example Serie structure
      #   {
      #     kind: :serie,
      #     serie: [neuma1, neuma2, neuma3]
      #   }.extend(Musa::Neumas::Neuma::Serie)
      #
      # @api public
      module Serie
        include Neuma
      end

      # Creates parallel structure with another neuma.
      #
      # Combines this neuma with another into parallel (polyphonic) structure.
      # If already parallel, adds to existing parallel array.
      #
      # @param other [String, Neuma] neuma to parallelize with
      #
      # @return [Parallel] parallel neuma structure
      #
      # @raise [ArgumentError] if other cannot be converted
      #
      # @example Create parallel from neumas
      #   melody = "0 +2 +4".to_neumas
      #   bass = "-7 -5 -3".to_neumas
      #   harmony = melody | bass
      #
      # @example Chain multiple parallels
      #   satb = soprano | alto | tenor | bass
      #
      # @api public
      def |(other)
        if is_a?(Parallel)
          clone.tap { |_| _[:parallel] << convert_to_parallel_element(other) }.extend(Parallel)
        else
          { kind: :parallel,
            parallel: [clone, convert_to_parallel_element(other)]
          }.extend(Parallel)
        end
      end

      private

      # Converts element to parallel-compatible format.
      #
      # @param e [String, Neuma] element to convert
      #
      # @return [Hash] neuma serie structure
      #
      # @raise [ArgumentError] if cannot convert
      #
      # @api private
      def convert_to_parallel_element(e)
        case e
        when String then { kind: :serie, serie: e.to_neumas }.extend(Neuma)
        else
          raise ArgumentError, "Don't know how to convert to neumas #{e}"
        end
      end
    end
  end
end
