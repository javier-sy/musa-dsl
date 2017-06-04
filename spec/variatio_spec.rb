require 'musa-dsl'
require 'pp'

RSpec.describe Musa::Variatio do


	context "Create several kind of variations" do

=begin
		it "With 2 fields + fieldset (2 inner fields), test with only 1 option each, constructor and finalize" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0]
				field :c, [2]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				finalize do |object:|
					object[:finalized] = true
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [100] do

					field :e, [4]
					field :f, [6]

					with_attributes do |object:, d:, e:, f:|
						object[:d][d] = {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end
				end
			end

			variations = v.on a: 1000

			expect(variations.size).to eq 1

			expect(variations[0]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 } }, finalized: true })
		end
=end


		it "With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, test with only 1 option each, constructor and finalize" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0]
				field :c, [2]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				finalize do |object:|
					object[:finalized] = true
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [100] do

					field :e, [4]
					field :f, [6]

					with_attributes do |object:, d:, e:, f:|

						object[:d][d] ||= {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end

					fieldset :g, [200] do
						
						field :h, [8]
						field :i, [10]

						with_attributes do |object:, d:, g:, h:, i:|
							object[:d][d][:g] ||= {}
							object[:d][d][:g][g] ||= {}

							object[:d][d][:g][g][:h] = h
							object[:d][d][:g][g][:i] = i
						end
					end

					fieldset :j, [300] do
						
						field :k, [12]

						with_attributes do |object:, d:, j:, k:|
							object[:d][d][:j] ||= {}
							object[:d][d][:j][j] ||= {}

							object[:d][d][:j][j][:k] = k
						end
					end
				end
			end

			variations = v.on a: 1000

			expect(variations[0]).to eq({ 
				a: 1000, 
				b: 0, 
				c: 2, 
				d: { 
					100 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10}, 201 => { h: 8, i: 10 } }, j: { 300 => { k: 12 }, 301 => { k: 12 } } }, 
					101 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10}, 201 => { h: 8, i: 10 } }, j: { 300 => { k: 12 }, 301 => { k: 12 } } } }, 
				finalized: true })

			expect(variations.size).to eq 2 * 2 * ((2 * 2) ** 2) * ((2 * 2) ** 4) * (2 ** 4)


		end



=begin
		it "With 2 fields + fieldset (2 inner fields), constructor and finalize" do

			puts
			puts
			puts
			puts

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0, 1]
				field :c, [2, 3]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				finalize do |object:|
					object[:finalized] = true
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [100, 101] do

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

			expect(variations[0]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 4, f: 6 } }, finalized: true })
			expect(variations[1]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 4, f: 7 } }, finalized: true })
			expect(variations[2]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 5, f: 6 } }, finalized: true })
			expect(variations[3]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 }, 101 => { e: 5, f: 7 } }, finalized: true })
			expect(variations[4]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 7 }, 101 => { e: 4, f: 6 } }, finalized: true })
			expect(variations[5]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 7 }, 101 => { e: 4, f: 7 } }, finalized: true })
			expect(variations[6]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 7 }, 101 => { e: 5, f: 6 } }, finalized: true })
			expect(variations[7]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 7 }, 101 => { e: 5, f: 7 } }, finalized: true })

			expect(variations.last).to eq({ a: 1000, b: 1, c: 3, d: { 100 => { e: 5, f: 7 }, 101 => { e: 5, f: 7 } }, finalized: true })

			expect(variations.size).to eq 2 * 2 * (2 * 2) ** 2
		end

=end

=begin
		it "With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields), constructor and finalize" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0, 1]
				field :c, [2, 3]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				finalize do |object:|
					object[:finalized] = true
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [100, 101] do

					field :e, [4, 5]
					field :f, [6, 7]

					with_attributes do |object:, d:, e:, f:|

						object[:d][d] ||= {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end

					fieldset :g, [200, 201] do
						
						field :h, [8, 9]
						field :i, [10, 11]

						with_attributes do |object:, d:, g:, h:, i:|
							object[:d][d][:g] ||= {}
							object[:d][d][:g][g] ||= {}

							object[:d][d][:g][g][:h] = h
							object[:d][d][:g][g][:i] = i
						end
					end
				end
			end

			variations = v.on a: 1000

			expect(variations[0]).to eq({ 
				a: 1000, 
				b: 0, 
				c: 2, 
				d: { 
					100 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10 }, 201 => { h: 8, i: 10 } } }, 
					101 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10 }, 201 => { h: 8, i: 10 } } } }, 
				finalized: true })


			expect(variations[1]).to eq({ 
				a: 1000, 
				b: 0, 
				c: 2, 
				d: { 
					100 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10 }, 201 => { h: 8, i: 10 } } }, 
					101 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10 }, 201 => { h: 8, i: 11 } } } }, 
				finalized: true })

			expect(variations.size).to eq 2 * 2 * ((2 * 2) ** 2) * ((2 * 2) ** 4)
		end
=end

=begin
		it "With 2 fields + fieldset (2 inner fields + fieldset with 2 inner fields) + fieldset with 1 inner field, constructor and finalize" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0, 1]
				field :c, [2, 3]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				finalize do |object:|
					object[:finalized] = true
				end

				with_attributes do |object:, c:|
					object[:c] = c
				end

				fieldset :d, [100, 101] do

					field :e, [4, 5]
					field :f, [6, 7]

					with_attributes do |object:, d:, e:, f:|

						object[:d][d] ||= {}
						object[:d][d][:e] = e
						object[:d][d][:f] = f
					end

					fieldset :g, [200, 201] do
						
						field :h, [8, 9]
						field :i, [10, 11]

						with_attributes do |object:, d:, g:, h:, i:|
							object[:d][d][:g] ||= {}
							object[:d][d][:g][g] ||= {}

							object[:d][d][:g][g][:h] = h
							object[:d][d][:g][g][:i] = i
						end
					end

					fieldset :j, [300, 301] do
						
						field :k, [12, 13]

						with_attributes do |object:, d:, j:, k:|
							object[:d][d][:j] ||= {}
							object[:d][d][:j][j] ||= {}

							object[:d][d][:j][j][:k] = k
						end
					end
				end
			end

			variations = v.on a: 1000

			expect(variations[0]).to eq({ 
				a: 1000, 
				b: 0, 
				c: 2, 
				d: { 
					100 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10}, 201 => { h: 8, i: 10 } }, j: { 300 => { k: 12 }, 301 => { k: 12 } } }, 
					101 => { e: 4, f: 6, g: { 200 => { h: 8, i: 10}, 201 => { h: 8, i: 10 } }, j: { 300 => { k: 12 }, 301 => { k: 12 } } } }, 
				finalized: true })

			expect(variations.size).to eq 2 * 2 * ((2 * 2) ** 2) * ((2 * 2) ** 4) * (2 ** 4)
		end

=end


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



	end
end
