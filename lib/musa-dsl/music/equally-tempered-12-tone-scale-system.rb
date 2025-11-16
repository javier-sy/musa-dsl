require_relative 'scales'

# Equal temperament 12-tone scale system and scale kinds.
#
# This file implements the equal temperament 12-tone (12-TET) scale system,
# the standard tuning system in Western music. It divides the octave into
# 12 equal semitones and provides common scale kinds (major, minor, chromatic).
#
# ## Scale System Hierarchy
#
# - **TwelveSemitonesScaleSystem**: Abstract base for 12-semitone systems
# - **EquallyTempered12ToneScaleSystem**: Concrete equal temperament implementation
#
# ## Scale Kinds
#
# - **ChromaticScaleKind**: All 12 semitones
# - **MajorScaleKind**: Major scale (Ionian mode)
# - **MinorNaturalScaleKind**: Natural minor (Aeolian mode)
# - **MinorHarmonicScaleKind**: Harmonic minor (raised 7th)
#
# ## Equal Temperament Tuning
#
# Equal temperament divides the octave into 12 logarithmically equal parts.
# Each semitone has a frequency ratio of 2^(1/12) ≈ 1.059463.
#
# Formula: frequency = 440 × 2^((pitch - 69) / 12)
# - MIDI pitch 69 = A4 = 440 Hz (concert pitch)
# - MIDI pitch 60 = C4 (middle C)
#
# ## Intervals
#
# Standard interval notation used:
# - **P0**: Perfect unison (0 semitones)
# - **m2/M2**: Minor/major second (1/2 semitones)
# - **m3/M3**: Minor/major third (3/4 semitones)
# - **P4**: Perfect fourth (5 semitones)
# - **TT**: Tritone (6 semitones)
# - **P5**: Perfect fifth (7 semitones)
# - **m6/M6**: Minor/major sixth (8/9 semitones)
# - **m7/M7**: Minor/major seventh (10/11 semitones)
# - **P8**: Perfect octave (12 semitones)
#
# @see ScaleSystem Abstract scale system base
# @see ScaleKind Abstract scale kind base
# @see scales.rb Scale system framework
module Musa
  module Scales
    # Base class for 12-semitone scale systems.
    #
    # TwelveSemitonesScaleSystem provides the foundation for any scale system
    # using 12 semitones per octave. It defines intervals and structure but
    # doesn't specify tuning (frequency calculation).
    #
    # Concrete subclasses must implement frequency calculation:
    # - {EquallyTempered12ToneScaleSystem}: Equal temperament (12-TET)
    # - Other temperaments could be added (e.g., meantone, just intonation)
    #
    # ## Intervals
    #
    # Defines standard interval names using semitone distances:
    #
    #     { P0: 0, m2: 1, M2: 2, m3: 3, M3: 4, P4: 5, TT: 6,
    #       P5: 7, m6: 8, M6: 9, m7: 10, M7: 11, P8: 12 }
    #
    # @abstract Subclasses must implement {frequency_of_pitch}
    # @see EquallyTempered12ToneScaleSystem Concrete equal temperament implementation
    class TwelveSemitonesScaleSystem < ScaleSystem
      class << self
        @@intervals = { P0: 0, m2: 1, M2: 2, m3: 3, M3: 4, P4: 5, TT: 6, P5: 7, m6: 8, M6: 9, m7: 10, M7: 11, P8: 12 }

        # System identifier.
        # @return [Symbol] :et12
        def id
          :et12
        end

        # Number of distinct notes per octave.
        # @return [Integer] 12
        def notes_in_octave
          12
        end

        # Size of smallest pitch division.
        # @return [Integer] 1 (semitone)
        def part_of_tone_size
          1
        end

        # Interval definitions.
        #
        # @return [Hash{Symbol => Integer}] interval name to semitones mapping
        #
        # @example
        #   intervals[:P5]  # => 7 (perfect fifth)
        #   intervals[:M3]  # => 4 (major third)
        def intervals
          @@intervals
        end
      end
    end

    # Equal temperament 12-tone scale system.
    #
    # EquallyTempered12ToneScaleSystem implements the standard equal temperament
    # tuning where each semitone has exactly the same frequency ratio: 2^(1/12).
    # This is the most common tuning system in modern Western music.
    #
    # ## Frequency Calculation
    #
    # Uses the equal temperament formula based on A440 concert pitch:
    #
    #     frequency = a_frequency × 2^((pitch - 69) / 12)
    #
    # Where:
    # - **a_frequency**: Reference A frequency (typically 440 Hz)
    # - **pitch**: MIDI pitch number (69 = A4)
    #
    # ## Historical Pitch Standards
    #
    # Different A frequencies represent different historical standards:
    # - **440 Hz**: Modern concert pitch (ISO 16)
    # - **442 Hz**: Used by some orchestras (brighter sound)
    # - **415 Hz**: Baroque pitch (approximately A=415)
    # - **432 Hz**: Alternative tuning (some claim harmonic benefits)
    #
    # ## Registration
    #
    # This system is registered as the default scale system, accessible via:
    #
    #     Scales[:et12]                    # By ID
    #     Scales.default_system            # As default
    #
    # ## Usage
    #
    #     # Get system with standard A440 tuning
    #     system = Scales[:et12][440.0]
    #
    #     # Get system with baroque tuning
    #     baroque = Scales[:et12][415.0]
    #
    #     # Access scale kinds
    #     c_major = system[:major][60]
    #     a_minor = system[:minor][69]
    #
    # @see TwelveSemitonesScaleSystem Abstract base class
    # @see ScaleSystem#frequency_of_pitch Abstract method implemented here
    class EquallyTempered12ToneScaleSystem < TwelveSemitonesScaleSystem
      class << self
        # Calculates frequency for a pitch using equal temperament.
        #
        # Implements the equal temperament tuning formula where each semitone
        # has a frequency ratio of 2^(1/12) ≈ 1.059463.
        #
        # @param pitch [Integer] MIDI pitch number
        # @param _root_pitch [Integer] unused (required by interface)
        # @param a_frequency [Numeric] reference A4 frequency in Hz
        # @return [Float] frequency in Hz
        #
        # @example Standard A440 tuning
        #   frequency_of_pitch(69, nil, 440.0)  # => 440.0 (A4)
        #   frequency_of_pitch(60, nil, 440.0)  # => 261.63 (C4, middle C)
        #
        # @example Baroque tuning
        #   frequency_of_pitch(69, nil, 415.0)  # => 415.0 (A4)
        def frequency_of_pitch(pitch, _root_pitch, a_frequency)
          (a_frequency * Rational(2)**Rational(pitch - 69, 12)).to_f
        end
      end

      Scales.register EquallyTempered12ToneScaleSystem, default: true
    end


    # Chromatic scale kind (all 12 semitones).
    #
    # ChromaticScaleKind defines the chromatic scale containing all 12 semitones
    # of the octave. It's used as a fallback for chromatic (non-diatonic) notes
    # and for atonal or twelve-tone compositions.
    #
    # ## Pitch Structure
    #
    # Contains 12 pitch classes, one for each semitone:
    # - Degrees: _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12
    # - Pitches: 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 (semitones from root)
    #
    # ## Special Properties
    #
    # - **chromatic?**: Returns true (only scale kind with this property)
    # - Used automatically when accessing non-diatonic notes in diatonic scales
    #
    # ## Usage
    #
    #     chromatic = Scales[:et12][440.0][:chromatic][60]
    #     chromatic._1   # C
    #     chromatic._2   # C#/Db
    #     chromatic._3   # D
    #     # ... all 12 semitones
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale (7 notes)
    # @see MinorNaturalScaleKind Minor scale (7 notes)
    class ChromaticScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: [:_1], pitch: 0 },
             { functions: [:_2], pitch: 1 },
             { functions: [:_3], pitch: 2 },
             { functions: [:_4], pitch: 3 },
             { functions: [:_5], pitch: 4 },
             { functions: [:_6], pitch: 5 },
             { functions: [:_7], pitch: 6 },
             { functions: [:_8], pitch: 7 },
             { functions: [:_9], pitch: 8 },
             { functions: [:_10], pitch: 9 },
             { functions: [:_11], pitch: 10 },
             { functions: [:_12], pitch: 11 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Scale kind identifier.
        # @return [Symbol] :chromatic
        def id
          :chromatic
        end

        # Indicates if this is a chromatic scale.
        # @return [Boolean] true
        def chromatic?
          true
        end
      end

      EquallyTempered12ToneScaleSystem.register ChromaticScaleKind
    end

    # Major scale kind (Ionian mode).
    #
    # MajorScaleKind defines the major scale, the fundamental scale of Western
    # tonal music. It follows the pattern: W-W-H-W-W-W-H (whole-half steps)
    # or intervals: M2-M2-m2-M2-M2-M2-m2 from the root.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, uppercase for major):
    # - **I** (tonic): Root (0 semitones)
    # - **II** (supertonic): Major second (2 semitones)
    # - **III** (mediant): Major third (4 semitones)
    # - **IV** (subdominant): Perfect fourth (5 semitones)
    # - **V** (dominant): Perfect fifth (7 semitones)
    # - **VI** (submediant): Major sixth (9 semitones, relative minor)
    # - **VII** (leading): Major seventh (11 semitones)
    #
    # **Extended degrees** (for extended harmony):
    # - VIII-XIII: Compound intervals (8th, 9th, 10th, 11th, 12th, 13th)
    #
    # ## Function Aliases
    #
    # Each degree has multiple function names:
    # - **Numeric**: _1, _2, _3, _4, _5, _6, _7 (ordinal)
    # - **Roman**: I, II, III, IV, V, VI, VII (harmonic analysis)
    # - **Function**: tonic, supertonic, mediant, subdominant, dominant,
    #                 submediant, leading
    # - **Ordinal**: first, second, third, fourth, fifth, sixth, seventh
    # - **Special**: relative/relative_minor for VI (relative minor root)
    #
    # ## Usage
    #
    #     c_major = Scales[:et12][440.0][:major][60]
    #     c_major.tonic      # C (60)
    #     c_major.dominant   # G (67)
    #     c_major.VI         # A (69) - relative minor root
    #     c_major.relative_minor.scale(:minor)  # A minor scale
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor scale
    # @see ChromaticScaleKind Chromatic scale
    class MajorScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[I _1 tonic first],
               pitch: 0 },
             { functions: %i[II _2 supertonic second],
               pitch: 2 },
             { functions: %i[III _3 mediant third],
               pitch: 4 },
             { functions: %i[IV _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[V _5 dominant fifth],
               pitch: 7 },
             { functions: %i[VI _6 submediant relative relative_minor sixth],
               pitch: 9 },
             { functions: %i[VII _7 leading seventh],
               pitch: 11 },
             { functions: %i[VIII _8 eighth],
               pitch: 12 },
             { functions: %i[IX _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[X _10 tenth],
               pitch: 12 + 4 },
             { functions: %i[XI _11 eleventh],
               pitch: 12 + 5 },
             { functions: %i[XII _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[XIII _13 thirteenth],
               pitch: 12 + 9 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Number of diatonic degrees.
        # @return [Integer] 7
        def grades
          7
        end

        # Scale kind identifier.
        # @return [Symbol] :major
        def id
          :major
        end
      end

      EquallyTempered12ToneScaleSystem.register MajorScaleKind
    end

    # Natural minor scale kind (Aeolian mode).
    #
    # MinorNaturalScaleKind defines the natural minor scale, parallel to the
    # major scale but with a darker, melancholic character. It follows the
    # pattern: W-H-W-W-H-W-W or intervals: M2-m2-M2-M2-m2-M2-M2 from the root.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for minor):
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones, relative major)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (subtonic): Minor seventh (10 semitones, NOT leading tone)
    #
    # **Extended degrees**: viii-xiii (compound intervals)
    #
    # ## Differences from Major
    #
    # Compared to major scale (same tonic):
    # - **iii**: Flatted third (minor third instead of major)
    # - **vi**: Flatted sixth (minor sixth instead of major)
    # - **vii**: Flatted seventh (minor seventh instead of major)
    #
    # ## Relative Major
    #
    # The **iii** degree is the root of the relative major scale (shares same
    # notes but different tonic). For example:
    # - A minor (natural) relative major: C major
    # - C major relative minor: A minor
    #
    # ## Function Aliases
    #
    # Similar to major but with lowercase Roman numerals:
    # - **Numeric**: _1, _2, _3, _4, _5, _6, _7
    # - **Roman**: i, ii, iii, iv, v, vi, vii
    # - **Function**: tonic, supertonic, mediant, subdominant, dominant, submediant
    # - **Ordinal**: first, second, third, fourth, fifth, sixth, seventh
    # - **Special**: relative/relative_major for iii
    #
    # ## Usage
    #
    #     a_minor = Scales[:et12][440.0][:minor][69]
    #     a_minor.tonic        # A (69)
    #     a_minor.dominant     # E (76)
    #     a_minor.iii          # C (72) - relative major root
    #     a_minor.relative_major.scale(:major)  # C major scale
    #
    # @see ScaleKind Abstract base class
    # @see MajorScaleKind Major scale
    # @see MinorHarmonicScaleKind Harmonic minor (with raised 7th)
    class MinorNaturalScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic first],
               pitch: 0 },
             { functions: %i[ii _2 supertonic second],
               pitch: 2 },
             { functions: %i[iii _3 mediant relative relative_major third],
               pitch: 3 },
             { functions: %i[iv _4 subdominant fourth],
               pitch: 5 },
             { functions: %i[v _5 dominant fifth],
               pitch: 7 },
             { functions: %i[vi _6 submediant sixth],
               pitch: 8 },
             { functions: %i[vii _7 seventh],
               pitch: 10 },
             { functions: %i[viii _8 eighth],
               pitch: 12 },
             { functions: %i[ix _9 ninth],
               pitch: 12 + 2 },
             { functions: %i[x _10 tenth],
               pitch: 12 + 3 },
             { functions: %i[xi _11 eleventh],
               pitch: 12 + 5 },
             { functions: %i[xii _12 twelfth],
               pitch: 12 + 7 },
             { functions: %i[xiii _13 thirteenth],
               pitch: 12 + 8 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Number of diatonic degrees.
        # @return [Integer] 7
        def grades
          7
        end

        # Scale kind identifier.
        # @return [Symbol] :minor
        def id
          :minor
        end
      end

      EquallyTempered12ToneScaleSystem.register MinorNaturalScaleKind
    end

    # Harmonic minor scale kind.
    #
    # MinorHarmonicScaleKind defines the harmonic minor scale, a variation of
    # the natural minor with a raised seventh degree. This creates a leading
    # tone (major seventh) that resolves strongly to the tonic, giving the
    # scale a more directed, dramatic character.
    #
    # ## Pitch Structure
    #
    # 7 diatonic degrees plus extended harmony (8th-13th):
    #
    # **Scale Degrees** (Roman numerals, lowercase for minor):
    # - **i** (tonic): Root (0 semitones)
    # - **ii** (supertonic): Major second (2 semitones)
    # - **iii** (mediant): Minor third (3 semitones, relative major)
    # - **iv** (subdominant): Perfect fourth (5 semitones)
    # - **v** (dominant): Perfect fifth (7 semitones)
    # - **vi** (submediant): Minor sixth (8 semitones)
    # - **vii** (leading): **Major seventh** (11 semitones) ← RAISED from natural minor
    #
    # **Extended degrees**: viii-xiii (compound intervals)
    #
    # ## Key Difference from Natural Minor
    #
    # The **vii** degree is raised from 10 semitones (minor seventh) to
    # 11 semitones (major seventh), creating:
    # - A **leading tone** that resolves strongly upward to the tonic
    # - An **augmented second** interval between vi and vii (3 semitones)
    # - A **dominant seventh chord** (v7) with strong resolution to i
    #
    # ## Musical Character
    #
    # The harmonic minor scale:
    # - Maintains minor quality (minor third)
    # - Provides strong dominant-to-tonic resolution
    # - Creates exotic sound due to augmented second (vi-vii)
    # - Common in classical, jazz, and Middle Eastern music
    #
    # ## Function Aliases
    #
    # Same as natural minor:
    # - **Numeric**: _1, _2, _3, _4, _5, _6, _7
    # - **Roman**: i, ii, iii, iv, v, vi, vii
    # - **Function**: tonic, supertonic, mediant, subdominant, dominant,
    #                 submediant, leading
    # - **Special**: relative/relative_major for iii
    #
    # ## Usage
    #
    #     a_harmonic_minor = Scales[:et12][440.0][:minor_harmonic][69]
    #     a_harmonic_minor.vii  # G# (80) - raised 7th, not G (79)
    #     a_harmonic_minor.vi   # F (77)
    #     # Augmented second: F to G# = 3 semitones
    #
    # @see ScaleKind Abstract base class
    # @see MinorNaturalScaleKind Natural minor (with minor 7th)
    # @see MajorScaleKind Major scale
    class MinorHarmonicScaleKind < ScaleKind
      class << self
        @@pitches =
            [{ functions: %i[i _1 tonic],
               pitch: 0 },
             { functions: %i[ii _2 supertonic],
               pitch: 2 },
             { functions: %i[iii _3 mediant relative relative_major],
               pitch: 3 },
             { functions: %i[iv _4 subdominant],
               pitch: 5 },
             { functions: %i[v _5 dominant],
               pitch: 7 },
             { functions: %i[vi _6 submediant],
               pitch: 8 },
             { functions: %i[vii _7 leading],
               pitch: 11 },
             { functions: %i[viii _8],
               pitch: 12 },
             { functions: %i[ix _9],
               pitch: 12 + 2 },
             { functions: %i[x _10],
               pitch: 12 + 3 },
             { functions: %i[xi _11],
               pitch: 12 + 5 },
             { functions: %i[xii _12],
               pitch: 12 + 7 },
             { functions: %i[xiii _13],
               pitch: 12 + 8 }].freeze

        # Pitch structure.
        # @return [Array<Hash>] pitch definitions with functions and offsets
        def pitches
          @@pitches
        end

        # Number of diatonic degrees.
        # @return [Integer] 7
        def grades
          7
        end

        # Scale kind identifier.
        # @return [Symbol] :minor_harmonic
        def id
          :minor_harmonic
        end
      end

      EquallyTempered12ToneScaleSystem.register MinorHarmonicScaleKind
    end
  end
end
