require 'musa-dsl'

RSpec.describe Musa::Chord2 do

	context "basic chord creation" do

		scale = Musa::Scales.get(:major)

		it "create a grade I major triad based on C4" do
			chord = Musa::Chord2 :I, scale: scale.based_on_pitch(60)

			expect(chord.pitches).to eq [60, 64, 67]
		end

		it "create a C3 major chord with C note in bass" do
			chord = Musa::Chord2 :I, scale: scale.based_on_pitch(60)

			chord.duplicate 0, octave: -1, to_voice: 0

			expect(chord.pitches).to eq [48, 60, 64, 67]
		end

		it "create a C3 major chord with E note in higher voice" do
			chord = Musa::Chord2 :I, scale: scale.based_on_pitch(60)

			chord.duplicate 1, octave: 1

			expect(chord.pitches).to eq [60, 64, 67, 76]
		end

		it "create a C3 major chord with C note in bass, adding it as last voice and reordering it to get it in lower voice" do
			chord = Musa::Chord2 :I, scale: scale.based_on_pitch(60)

			chord.duplicate 0, octave: -1

			expect(chord.pitches).to eq [60, 64, 67, 48]

			chord.sort_voices!

			expect(chord.pitches).to eq [48, 60, 64, 67]
		end
	end

	context "basic chord querying" do

		scale = Musa::Scales.get(:major)
		chord = Musa::Chord2 :I, scale: scale.based_on_pitch(60)

		chord.duplicate 0, octave: -1, to_voice: 0

		it "getting chord grades pitches via grade position number" do
			expect(chord.grade(0).get(:pitch)).to eq [48, 60]
			expect(chord.grade(1).get(:pitch)).to eq [64]
			expect(chord.grade(2).get(:pitch)).to eq [67]
		end

		it "getting chord grades pitches via grade symbol" do
			expect(chord.grade(:I).get(:pitch)).to eq [48, 60]
			expect(chord.grade(:III).get(:pitch)).to eq [64]
			expect(chord.grade(:V).get(:pitch)).to eq [67]
		end
	end

	context "basic chord manipulation" do

		scale = Musa::Scales.get(:major)
		chord = Musa::Chord2 :I, scale: scale.based_on_pitch(60)

		chord.duplicate 0, octave: -1, to_voice: 0

		chord.grade(1)[0].octave = 3

		it "changing note octave 3 octaves up maintains pitch and voice number correct" do

			expect(chord.grade(0).get(:pitch)).to eq [48, 60]
			expect(chord.grade(1).get(:pitch)).to eq [64 + 3*12]
			expect(chord.grade(2).get(:pitch)).to eq [67]

			expect(chord.grade(0).get(:voice)).to eq [0, 1]
			expect(chord.grade(1).get(:voice)).to eq [2]
			expect(chord.grade(2).get(:voice)).to eq [3]
		end

		it "after changing note 3 octaves up and sorting it, pitch and voice number are correct" do

			chord.sort_voices!

			expect(chord.grade(0).get(:pitch)).to eq [48, 60]
			expect(chord.grade(1).get(:pitch)).to eq [64 + 3*12]
			expect(chord.grade(2).get(:pitch)).to eq [67]

			expect(chord.pitches).to eq [48, 60, 67, 64 + 3*12]

			expect(chord.grade(0).get(:voice)).to eq [0, 1]
			expect(chord.grade(1).get(:voice)).to eq [3]
			expect(chord.grade(2).get(:voice)).to eq [2]
		end
	end

end
