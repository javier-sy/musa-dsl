Musa::Chord.register Musa::ChordDefinition.new do |scale, root, size|
  # para acordes por defecto, que deberán tener en cuenta la scale, length, etc
end

Musa::Chord.register Musa::ChordDefinition.new(:maj, root: 0, third: 4, fifth: 7)
Musa::Chord.register Musa::ChordDefinition.new(:min, root: 0, third: 3, fifth: 7)
Musa::Chord.register Musa::ChordDefinition.new(:maj7, root: 0, third: 4, fifth: 7, seventh: 11)
Musa::Chord.register Musa::ChordDefinition.new(:min7, root: 0, third: 3, fifth: 7, seventh: 11) # 11 ???
