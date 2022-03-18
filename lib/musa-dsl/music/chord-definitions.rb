require_relative 'chord-definition'

# TODO trasladar los acordes de https://en.wikipedia.org/wiki/Chord_notation

Musa::Chords::ChordDefinition.register :maj, quality: :major, size: :triad, offsets: { root: 0, third: 4, fifth: 7 }
Musa::Chords::ChordDefinition.register :min, quality: :minor, size: :triad, offsets: { root: 0, third: 3, fifth: 7 }
Musa::Chords::ChordDefinition.register :dim, quality: :diminished, size: :triad, offsets: { root: 0, third: 3, fifth: 3 }
Musa::Chords::ChordDefinition.register :aug, quality: :augmented, size: :triad, offsets: { root: 0, third: 4, fifth: 8 }

Musa::Chords::ChordDefinition.register :maj7, quality: :major, size: :seventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11 }
Musa::Chords::ChordDefinition.register :min7, quality: :minor, size: :seventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 11 }

Musa::Chords::ChordDefinition.register :dom7, quality: :dominant, size: :seventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 10 }

Musa::Chords::ChordDefinition.register :maj9, quality: :major, size: :ninth, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14 }
Musa::Chords::ChordDefinition.register :min9, quality: :minor, size: :ninth, offsets: { root: 0, third: 3, fifth: 7, seventh: 11, ninth: 14 }
Musa::Chords::ChordDefinition.register :dom9, quality: :dominant, size: :ninth, offsets: { root: 0, third: 4, fifth: 7, seventh: 10, ninth: 14 }

Musa::Chords::ChordDefinition.register :maj11, quality: :major, size: :eleventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }
Musa::Chords::ChordDefinition.register :min11, quality: :minor, size: :eleventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }

Musa::Chords::ChordDefinition.register :maj13, quality: :major, size: :eleventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }
Musa::Chords::ChordDefinition.register :min13, quality: :minor, size: :eleventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }
