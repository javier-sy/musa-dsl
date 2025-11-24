require_relative 'chord-definition'

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

# Minor seventh: C-Eb-G-Bb (0-3-7-10 semitones)
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
