require_relative 'chord-definition'

# Standard chord definitions registry.
#
# This file registers common chord types used in Western music theory.
# Each definition specifies:
# - **Name**: Chord symbol (:maj, :min7, :dom9, etc.)
# - **Quality**: Harmonic character (:major, :minor, :diminished, :augmented, :dominant)
# - **Size**: Number of chord tones (:triad, :seventh, :ninth, :eleventh, :thirteenth)
# - **Offsets**: Semitone intervals from root
#
# ## Triads
#
# Basic three-note chords:
# - **:maj** - Major triad (1-3-5): root, major third, perfect fifth
# - **:min** - Minor triad (1-♭3-5): root, minor third, perfect fifth
# - **:dim** - Diminished triad (1-♭3-♭5): root, minor third, diminished fifth
# - **:aug** - Augmented triad (1-3-♯5): root, major third, augmented fifth
#
# ## Seventh Chords
#
# Four-note chords with added seventh:
# - **:maj7** - Major seventh (1-3-5-7): major triad + major seventh
# - **:min7** - Minor seventh (1-♭3-5-♭7): minor triad + minor seventh
# - **:dom7** - Dominant seventh (1-3-5-♭7): major triad + minor seventh
#
# ## Extended Chords
#
# Chords with ninths, elevenths, and thirteenths:
# - **:maj9, :min9, :dom9** - Ninth chords
# - **:maj11, :min11** - Eleventh chords
# - **:maj13, :min13** - Thirteenth chords
#
# ## Usage
#
# Chord definitions are accessed automatically when creating chords:
#
#     scale = Scales::Scales.default_system.default_tuning.major[60]
#     chord = scale.tonic.chord               # Uses :maj definition
#     chord = scale.tonic.chord :seventh      # Finds seventh chord matching scale
#
# @see ChordDefinition Chord definition class
# @see Chord Chord instantiation

# TODO trasladar los acordes de https://en.wikipedia.org/wiki/Chord_notation

# TRIADS
# Major triad: C-E-G (0-4-7 semitones)
Musa::Chords::ChordDefinition.register :maj, quality: :major, size: :triad, offsets: { root: 0, third: 4, fifth: 7 }

# Minor triad: C-Eb-G (0-3-7 semitones)
Musa::Chords::ChordDefinition.register :min, quality: :minor, size: :triad, offsets: { root: 0, third: 3, fifth: 7 }

# Diminished triad: C-Eb-Gb (0-3-6 semitones)
Musa::Chords::ChordDefinition.register :dim, quality: :diminished, size: :triad, offsets: { root: 0, third: 3, fifth: 6 }

# Augmented triad: C-E-G# (0-4-8 semitones)
Musa::Chords::ChordDefinition.register :aug, quality: :augmented, size: :triad, offsets: { root: 0, third: 4, fifth: 8 }

# SEVENTH CHORDS
# Major seventh: C-E-G-B (0-4-7-11 semitones)
Musa::Chords::ChordDefinition.register :maj7, quality: :major, size: :seventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11 }

# Minor seventh: C-Eb-G-Bb (0-3-7-10 semitones) - NOTE: Changed from 11 to 10 for correct minor seventh
Musa::Chords::ChordDefinition.register :min7, quality: :minor, size: :seventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 10 }

# Dominant seventh: C-E-G-Bb (0-4-7-10 semitones)
Musa::Chords::ChordDefinition.register :dom7, quality: :dominant, size: :seventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 10 }

# NINTH CHORDS
# Major ninth: C-E-G-B-D (0-4-7-11-14 semitones)
Musa::Chords::ChordDefinition.register :maj9, quality: :major, size: :ninth, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14 }

# Minor ninth: C-Eb-G-Bb-D (0-3-7-10-14 semitones) - NOTE: Changed seventh from 11 to 10
Musa::Chords::ChordDefinition.register :min9, quality: :minor, size: :ninth, offsets: { root: 0, third: 3, fifth: 7, seventh: 10, ninth: 14 }

# Dominant ninth: C-E-G-Bb-D (0-4-7-10-14 semitones)
Musa::Chords::ChordDefinition.register :dom9, quality: :dominant, size: :ninth, offsets: { root: 0, third: 4, fifth: 7, seventh: 10, ninth: 14 }

# ELEVENTH CHORDS
# Major eleventh: C-E-G-B-D-F (0-4-7-11-14-17 semitones)
Musa::Chords::ChordDefinition.register :maj11, quality: :major, size: :eleventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }

# Minor eleventh: C-Eb-G-Bb-D-F (0-3-7-10-14-17 semitones) - NOTE: Changed seventh from 11 to 10
Musa::Chords::ChordDefinition.register :min11, quality: :minor, size: :eleventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 10, ninth: 14, eleventh: 17 }

# THIRTEENTH CHORDS
# Major thirteenth: C-E-G-B-D-F-A (0-4-7-11-14-17-21 semitones)
Musa::Chords::ChordDefinition.register :maj13, quality: :major, size: :thirteenth, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14, eleventh: 17, thirteenth: 21 }

# Minor thirteenth: C-Eb-G-Bb-D-F-A (0-3-7-10-14-17-21 semitones) - NOTE: Changed seventh from 11 to 10
Musa::Chords::ChordDefinition.register :min13, quality: :minor, size: :thirteenth, offsets: { root: 0, third: 3, fifth: 7, seventh: 10, ninth: 14, eleventh: 17, thirteenth: 21 }
