require 'musa-dsl'
require 'pp'

RSpec.describe Musa::Variatio do

	context "Structure" do


		it "con fieldset de longitud 1" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0, 1]
				field :c, [2, 3]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [100, 101] do

					field :e, [4, 5]
					field :f, [6, 7]

					with_attributes do |object:, d:, e:, f:|

						#puts "with_attributes d: #{d} e: #{e} f: #{f}"
						object[:d][d] = {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end
=begin

					fieldset :g, [200, 201] do
						
						field :h, [8, 9]
						field :i, [10, 11]

						with_attributes do |object:, d:, g:, h:, i:|
							#puts "with_attributes d: #{d} g: #{g} h: #{h} i: #{i}"
							object[:d][d][:g] = []
							object[:d][d][:g][g] = {}

							object[:d][d][:g][g][:h] = h
							object[:d][d][:g][g][:i] = i
						end
					end

					fieldset :j, [300, 301] do
						
						field :k, [12, 13]

						with_attributes do |object:, d:, j:, k:|
							#puts "with_attributes d: #{d} j: #{j} k: #{k}"
							object[:d][d][:j] = []
							object[:d][d][:j][j] = {}

							object[:d][d][:j][j][:k] = k
						end
					end
=end

				end
			end

			variations = v.on a: 1000

			#pp variations
			
			expect(variations[0]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 4, f: 6 } } })
			expect(variations[1]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 4, f: 7 } } })
			expect(variations[2]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 5, f: 6 } } })
			expect(variations[3]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 5, f: 7 } } })

			# combinaciones del fieldset = producto_each(field.options.size) ^ fieldset.options.size

		end

=begin
		it "versión en código" do

			param = {}
			variations = []

			param[:a] ||= {}
			param[:a][nil] = 1000

			[0, 1].each do |v|

				param[:b] ||= {}
				param[:b][nil] = v

				[2, 3].each do |v|

					param[:c] ||= {}
					param[:c][nil] = v


					[4, 5].each do |v|
						
						param[:e] ||= {}
						param[:e][0] = v
						
						[6, 7].each do |v|

							param[:f] ||= {}
							param[:f][0] = v

							[4, 5].each do |v|

								param[:e] ||= {}
								param[:e][1] = v

								[6, 7].each do |v|

									param[:f] ||= {}
									param[:f][1] = v

									[8, 9].each do |v|

										param[:h] ||= {}
										param[:h][0] = v

										[10, 11].each do |v|

											param[:i] ||= {}
											param[:i][0] = v

											[8, 9].each do |v|

												param[:h] ||= {}
												param[:h][1] = v

												[10, 11].each do |v|

													param[:i] ||= {}
													param[:i][1] = v

													variations << (object = { a: param[:a], b: param[:b], d: {} })

													[nil].each do |v|

														object[:c] = param[:c][v]

														[100, 101].each do |i|
															object[:d][i] ||= {}
															object[:d][i][:e] = param[:e][i]
															object[:d][i][:f] = param[:f][i]


															[200, 201].each do |j|
																object[:d][i][:g] ||= {}
																object[:d][i][:g][j] ||= {}

																object[:d][i][:g][j][:h] = param[:h][j]
																object[:d][i][:g][j][:i] = param[:i][j]
															end
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end

			# pp variations

			expect(variations[0]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 4, f: 6 } ] })
			expect(variations[1]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 4, f: 7 } ] })
			expect(variations[2]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 5, f: 6 } ] })
			expect(variations[3]).to eq({ a: 1000, b: 0, c: 2, d: [ { e: 4, f: 6 }, { e: 5, f: 7 } ] })
		end

=end



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
