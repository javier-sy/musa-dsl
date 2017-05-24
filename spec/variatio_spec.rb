require 'musa-dsl'
require 'pp'

RSpec.describe Musa::Variatio do

	context "Structure" do


		it "con fieldset de longitud 1" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0, 1]
				field :c, [2, 3]

				constructor do |a:, b:|
					{ a: a, b: b, d: [] }
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [0, 1] do

					field :e, [4, 5]
					field :f, [6, 7]

=begin
					fieldset :g, [8, 9] do
						field :h, [10, 11]
						field :i, [12, 13]
					end
=end
					with_attributes do |object:, d:, e:, f:|
						puts "with with_attributes #{d} #{e} #{f}"
						object[:d][d] = {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end
				end
			end

			variations = v.on a: 1000

			#pp variations
			
			expect(variations[0]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 } ] })
			expect(variations[1]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 7 } ] })
			expect(variations[2]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 6 } ] })
			expect(variations[3]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 7 } ] })

			# combinaciones del fieldset = producto_each(field.options.size) ^ fieldset.options.size

		end
=begin
	
		it "con fieldset de longitud 2" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0, 1]
				field :c, [2, 3]

				constructor do |a:, b:|
					{ a: a, b: b, d: [] }
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [0, 1] do

					field :e, [4, 5]
					field :f, [6, 7]

					with_attributes do |object:, d:, e:, f:|
						object[:d][d] = {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end
				end
			end

			variations = v.on a: 1000

			expect(variations[0]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 4, f: 6 } ] })
			expect(variations[1]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 4, f: 7 } ] })
			expect(variations[2]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 7 }, { e: 4, f: 6 } ] })
			expect(variations[3]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 7 }, { e: 4, f: 7 } ] })

			expect(variations[4]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 5, f: 6 } ] })
			expect(variations[5]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 5, f: 7 } ] })
			expect(variations[6]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 7 }, { e: 5, f: 6 } ] })
			expect(variations[7]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 7 }, { e: 5, f: 7 } ] })

			expect(variations[8]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 6 }, { e: 4, f: 6 } ] })
			expect(variations[9]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 6 }, { e: 4, f: 7 } ] })
			expect(variations[10]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 7 }, { e: 4, f: 6 } ] })
			expect(variations[11]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 7 }, { e: 4, f: 7 } ] })

			expect(variations[12]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 6 }, { e: 5, f: 6 } ] })
			expect(variations[13]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 6 }, { e: 5, f: 7 } ] })
			expect(variations[14]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 7 }, { e: 5, f: 6 } ] })
			expect(variations[15]).to.eq({ a: 1000, b: 0, c: 2, d: [ { e: 5, f: 7 }, { e: 5, f: 7 } ] })

			# combinaciones del fieldset = producto_each(field.options.size) ^ fieldset.options.size

		end

=end
=begin
		v = Musa::Variatio.new :chord, parameters: [:scale] do 

			field :grade, [:I, :III, :V]
			field :duplicate_index, (0..2)
			
			constructor do |grade:, scale:|
				#Musa::Chord2.new grade, scale: scale
			end

			with_attributes do |chord:, duplicate_index:|
				#chord.duplicate duplicate_index
			end

			fieldset :voice, (0..2) do
				field :octave, (-2..2)

				with_attributes do |chord:, voice:, octave:|
					#chord.voices[voice].octave = octave
				end	
			end

			finalize do |chord:|
				#chord.sort_voices!
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
