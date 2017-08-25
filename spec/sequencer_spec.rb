require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Sequencer do

	context "Basic sequencing" do

		it "Basic at sequencing" do

			s = Musa::Sequencer.new 4, 4

			c = 0

			s.at 1 do
				c += 1
			end

			s.at 2 do
				c += 1
			end

			expect(c).to eq(0)

			s.tick

			expect(c).to eq(1)

			s.tick

			expect(c).to eq(1)

			14.times do
				s.tick
			end

			expect(c).to eq(1)

			s.tick

			expect(c).to eq(2)

			s.tick

			expect(c).to eq(2)
		end

		it "Basic every sequencing" do

			s = Musa::Sequencer.new 4, 4

			c = 0

			s.at 1 do
				s.every 1 do
					c += 1
				end
			end

			expect(c).to eq(0)

			s.tick

			expect(c).to eq(1)

			s.tick

			expect(c).to eq(1)

			14.times do
				s.tick
			end

			expect(c).to eq(1)

			s.tick

			expect(c).to eq(2)

			s.tick

			expect(c).to eq(2)

			15.times do
				s.tick
			end

			expect(c).to eq(3)
		end

		it "Basic move sequencing" do

			s = Musa::Sequencer.new 4, 4

			c = 0

			s.at 1 do
				s.move from: 1, to: 5, duration: 4 + Rational(1,16) do |value|
					c = value
				end
			end

			#100.times do
			#	puts "position = #{s.position} c = #{c}"
			#	s.tick
			#end

			expect(c).to eq(0)

			s.tick

			expect(c).to eq(1)

			s.tick

			expect(c).to eq(1 + Rational(1,16))

			14.times do
				s.tick
			end

			expect(c).to eq(1 + Rational(15,16))

			s.tick

			expect(c).to eq(Rational(2))

			s.tick

			15.times do
				s.tick
			end

			expect(c).to eq(Rational(3))
		end

		it "Basic theme sequencing" do
			# TODO
		end

		it "Basic play sequencing" do
			# TODO
		end

	end

	context "Advanced sequencing" do

	end	

	context "DSL Sequencing" do

		it "Basic at sequencing" do

			s = Musa::Sequencer.new 4, 4 do 
				at 1 do
					every 1 do
						c += 1
					end
				end
			end

			s.with do
				at 3 do
					move from: 1, to: 5, duration: 4 + Rational(1,16) do |value|
						c = value
					end
				end
			end
		end
	end
end
