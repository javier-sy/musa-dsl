require 'spec_helper'

require 'musa-dsl'


include Musa::Series

RSpec.describe Musa::Sequencer do

	context "Basic sequencing" do

		it "Basic at sequencing" do

			s = Musa::BaseSequencer.new 4, 4

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

			s = Musa::BaseSequencer.new 4, 4

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

		it "Basic every sequencing with control" do

			s = Musa::BaseSequencer.new 4, 4

			c = 0
			d = 0

			s.at 1 do
				s.every 1 do |control:|
					c += 1

					if c == 2
						control.after do 
							d = 1
						end
					end

					if c == 3
						control.stop
					end
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
			expect(d).to eq(0)

			s.tick

			expect(c).to eq(3)
			expect(d).to eq(0)

			15.times do
				s.tick
			end

			expect(c).to eq(3)
			expect(d).to eq(1)
		end

		it "Basic move sequencing" do

			s = Musa::BaseSequencer.new 4, 4

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

		it "Basic play sequencing" do

			s = Musa::BaseSequencer.new 4, 4

			t = FOR(from: 0, to: 3)

			serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat

			c = -1
			d = 0

			p = s.play serie do |element, control:|
				c = element[:value]
			end

			p.after do
				d = 1
			end

			expect(c).to eq(0)
			expect(d).to eq(0)

			s.tick
			expect(c).to eq(1)

			s.tick
			expect(c).to eq(2)

			s.tick
			expect(c).to eq(3)
			expect(d).to eq(0)

			s.tick
			expect(c).to eq(3)
			expect(d).to eq(1)
		end

		#it "Basic theme sequencing" do
			# TODO
		#end
	end

	context "Advanced sequencing" do

		it "Event passing on at" do
			s = Musa::BaseSequencer.new 4, 4

			c = 0
			d = 0

			control = s.at 1 do |control:|
				c += 1
				control.launch :event, 100
			end

			control.on :event do |param|
				d += param
			end

			expect(c).to eq(0)
			expect(d).to eq(0)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(100)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(100)
		end

		it "Event passing on at with inner at" do
			s = Musa::BaseSequencer.new 4, 4

			c = 0
			d = 0
			e = 0

			control0 = s.at 1 do |control:|

				c += 1
				
				control1 = s.at 2, control: control do |control:| 
					control.launch :event, 100
				end

				control2 = s.at 2, control: control.make_subhandler do |control:|
					control.launch :event, 100
				end

				control2.on :event do |param|
					e += param
				end

			end

			control0.on :event do |param|
				d += param
			end

			expect(c).to eq(0)
			expect(d).to eq(0)
			expect(e).to eq(0)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(0)
			expect(d).to eq(0)

			95.times { || s.tick }

			expect(c).to eq(1)
			expect(d).to eq(200)
			expect(e).to eq(100)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(200)
			expect(e).to eq(100)
		end

	end	
end
