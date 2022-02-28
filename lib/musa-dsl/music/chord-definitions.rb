require_relative 'chord-definition'

Musa::Chords::ChordDefinition.register :maj, quality: :major, size: :triad, offsets: { root: 0, third: 4, fifth: 7 }
Musa::Chords::ChordDefinition.register :min, quality: :minor, size: :triad, offsets: { root: 0, third: 3, fifth: 7 }

Musa::Chords::ChordDefinition.register :maj7, quality: :major, size: :seventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11 }
Musa::Chords::ChordDefinition.register :dom7, quality: :major, size: :seventh, dominant: :dominant, offsets: { root: 0, third: 4, fifth: 7, seventh: 10 }

Musa::Chords::ChordDefinition.register :min7, quality: :minor, size: :seventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 11 }

Musa::Chords::ChordDefinition.register :maj9, quality: :major, size: :ninth, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14 }
Musa::Chords::ChordDefinition.register :min9, quality: :minor, size: :ninth, offsets: { root: 0, third: 3, fifth: 7, seventh: 11, ninth: 14 }

Musa::Chords::ChordDefinition.register :maj11, quality: :major, size: :eleventh, offsets: { root: 0, third: 4, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }
Musa::Chords::ChordDefinition.register :min11, quality: :minor, size: :eleventh, offsets: { root: 0, third: 3, fifth: 7, seventh: 11, ninth: 14, eleventh: 17 }
