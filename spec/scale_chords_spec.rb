require 'musa-dsl'

require 'spec_helper'

RSpec.describe Musa::Chord do

	context "Basic chord creation" do

		scale = Musa::Scales.get(:major)

		it "Create a grade I major triad based on C4" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)

			expect(chord.pitches).to eq [60, 64, 67]
		end

		it "Create a grade I major triad based on C3 (1 octave less than scale on pitch 60)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60), octave: -1

			expect(chord.pitches).to eq [48, 52, 55]
		end

		it "Create a C3 major chord with C note in bass" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60), duplicate: { position: 0, octave: -1, to_voice: 0 }

			expect(chord.pitches).to eq [48, 60, 64, 67]
		end

		it "Create a C3 major chord with E note in higher voice (use grade position to duplicate)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60), duplicate: { position: 1, octave: 1 }

			expect(chord.pitches).to eq [60, 64, 67, 76]
		end

		it "Create a C3 major chord with E note in higher voice (use grade symbol to duplicate)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60), duplicate: { position: :III, octave: 1 }

			expect(chord.pitches).to eq [60, 64, 67, 76]
		end

		it "Create a C3 major chord with C note in bass, adding it as last voice and reordering it to get it in lower voice" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)

			chord.duplicate 0, octave: -1

			expect(chord.pitches).to eq [60, 64, 67, 48]

			chord.sort_voices!

			expect(chord.pitches).to eq [48, 60, 64, 67]
		end
	end

	context "Moving the voices" do
		scale = Musa::Scales.get(:major)

		it "Create a C3 major chord with C note in bass, adding it as last voice and moving other 2 voices" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)

			chord.duplicate 0, octave: -1
			chord.move 0, octave: -2
			chord.move 1, octave: -1

			expect(chord.pitches).to eq [36, 52, 67, 48]
		end
	end

	context "Basic chord querying" do

		scale = Musa::Scales.get(:major)
		chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)

		chord.duplicate 0, octave: -1, to_voice: 0

		it "Getting chord grades pitches via grade position number" do
			expect(chord.grade(0).get(:pitch)).to eq [48, 60]
			expect(chord.grade(1).get(:pitch)).to eq [64]
			expect(chord.grade(2).get(:pitch)).to eq [67]
		end

		it "Getting chord grades pitches via grade symbol" do
			expect(chord.grade(:I).get(:pitch)).to eq [48, 60]
			expect(chord.grade(:III).get(:pitch)).to eq [64]
			expect(chord.grade(:V).get(:pitch)).to eq [67]
		end
	end

	context "Basic chord manipulation" do

		scale = Musa::Scales.get(:major)
		chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)

		chord.duplicate 0, octave: -1, to_voice: 0
		chord.grade(1)[0].octave = 3

		it "Changing note octave 3 octaves up maintains pitch and voice number correct" do

			expect(chord.grade(0).get(:pitch)).to eq [48, 60]
			expect(chord.grade(1).get(:pitch)).to eq [64 + 3*12]
			expect(chord.grade(2).get(:pitch)).to eq [67]

			expect(chord.grade(0).get(:voice)).to eq [0, 1]
			expect(chord.grade(1).get(:voice)).to eq [2]
			expect(chord.grade(2).get(:voice)).to eq [3]
		end

		it "After changing note 3 octaves up and sorting it, pitch and voice number are correct" do

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

	context "Inversion and position querying" do

		scale = Musa::Scales.get(:major)

		it "C chord with C on bass - without inversion" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :I, octave: -1, to_voice: 0

			expect(chord.inversion).to eq 0
			expect(chord.distance).to eq 67 - 48
		end

		it "C chord with E on bass - inversion 1 (with voice sorting)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :III, octave: -1

			chord.sort_voices!

			expect(chord.inversion).to eq 1
			expect(chord.distance).to eq 67 - 52
		end

		it "C chord with E on bass - inversion 1 (bass voice in mid voice)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :III, octave: -1

			expect(chord.inversion).to eq 1
			expect(chord.distance).to eq 67 - 52
		end

		it "C chord with G on high - position 2 (based on 0)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :I, octave: -1, to_voice: 0

			expect(chord.position).to eq 2
			expect(chord.distance).to eq 67 - 48
		end

		it "C chord with E on high - position 1 (based on 0) (with voice sorting)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :III, octave: 1

			chord.sort_voices!

			expect(chord.position).to eq 1
			expect(chord.distance).to eq 76 - 60
		end

		it "C chord with E on high - position 1 (based on 0) (without voice sorting)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :III, octave: 1

			expect(chord.position).to eq 1
			expect(chord.distance).to eq 76 - 60
		end

		it "C chord with C on high - position 0 (based on 0) (without voice sorting)" do
			chord = Musa::ScaleChord.new :I, scale: scale.based_on_pitch(60)
			chord.duplicate :I, octave: 1

			expect(chord.position).to eq 0
			expect(chord.distance).to eq 72 - 60
		end

	end
end
