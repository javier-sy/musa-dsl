require 'musa-dsl'
require 'pp'

RSpec.describe Musa::Variatio do

	context "Structure" do

		v = Musa::Variatio.new :chord, parameters: [:scale] do 

			field :grade, [:I, :III, :V]
			field :duplicate_index, (0..2)
			
			constructor do |grade:, scale:|
				Musa::Chord2.new grade, scale: scale
			end

			with_attributes do |chord:, duplicate_index:|
				chord.duplicate duplicate_index
			end

			fieldset :voice, (0..2) do
				field :octave, (-2..2)

				with_attributes do |chord:, voice:, octave:|
					chord.voices[voice].octave = octave
				end	
			end

			finalize do |chord:|
				chord.sort_voices!
			end
		end

		scale = Musa::Scales.get(:major)

		it "Create all variations of all fields and fieldsets" do

			chords = v.on scale: scale.based_on(60)

			expect(chords.get :pitches).to.eq [ [], [] ] # TODO completar valores

		end

		it "Create a subset of variations allowing, for some fields and part of the fieldsets, only some variations; for the rest of fields and fieldsets all variations are allowed" do

			chords = v.on scale: scale, root_grade: :I, duplicate_note: [0, 2], octave_of_note: { 0 => [-1, 0], 2 => [0, 1, 2], rest: :all }

			expect(chords.get :pitches).to.eq [ [], [] ] # TODO completar valores

		end

		it "Create a subset of variations allowing only some fields and fieldsets variations; the rest of variations are not allowed" do

			chords = v.on scale: scale, root_grade: :I, duplicate_note: [0, 2], octave_of_note: { 0 => [-1, 0], 2 => [0, 1, 2], rest: :none }

			expect(chords.get :pitches).to.eq [ [], [] ] # TODO completar valores

		end
=end
	end
end
