require 'musa-dsl'

RSpec.describe Musa::Variatio do
	context "Create several kind of variations" do

		
		it "With 2 fields and constructor, without external parameters" do

			v = Musa::Variatio.new :object do
				field :a, 1..10
				field :b, [:alfa, :beta, :gamma, :delta]

				constructor do |a:, b:|
					{ a: a, b: b }
				end
			end

			variations = v.run

			expect(variations.size).to eq 10*4

			expect(variations[0]).to eq( {a: 1, b: :alfa} )
			expect(variations[1]).to eq( {a: 1, b: :beta} )

			expect(variations[40]).to eq( {a: 4, b: :delta} )
		end

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

		it "With 1 field + 2 fieldset (1 inner fields + 2 fieldset with 1 inner fields), test with only 1 option each, constructor and finalize" do

			v = Musa::Variatio.new :object, parameters: [:a] do

				field :b, [0]

				constructor do |a:, b:|
					{ a: a, b: b, d: {} }
				end

				finalize do |object:|
					object[:finalized] = true
				end

				fieldset :d, [100] do

					field :e, [4]

					fieldset :f, [200] do
						field :g, [8]

						with_attributes do |object:, d:, f:, g:|
							object[:d][d][:f] ||= {}
							object[:d][d][:f][f] ||= {}

							object[:d][d][:f][f][:g] = g
						end

					end

					fieldset :i, [300] do
						
						field :j, [12]

						with_attributes do |object:, d:, i:, j:|
							object[:d][d][:i] ||= {}
							object[:d][d][:i][i] ||= {}

							object[:d][d][:i][i][:j] = j
						end

					end

					with_attributes do |object:, d:, e:|
						object[:d][d] ||= {}
						object[:d][d][:e] = e
					end

				end
			end

			variations = v.on a: 1000

			expect(variations[0]).to eq({ 
				a: 1000, 
				b: 0, 
				d: { 100 => { e: 4, f: { 200 => { g: 8 } }, i: { 300 => { j: 12 } } } },
				finalized: true })

			expect(variations.size).to eq 1

		end

		it "With 2 fields + fieldset (2 inner fields), constructor and finalize" do

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
	end
end
