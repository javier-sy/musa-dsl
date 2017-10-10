require 'spec_helper'

require 'musa-dsl'


include Musa::Series

RSpec.describe Musa::Sequencer do

	context "DSL Sequencing" do

		it "Basic at sequencing" do

			c = 0

			s = Musa::Sequencer.new 4, 4 do
				at 1 do
					every 1 do
						c += 1
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
		end

		it "Basic every sequencing with control" do

			c = 0
			d = 0

			s = Musa::Sequencer.new 4, 4 do
				at 1 do
					every 1 do |control:|
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

		it "Basic play sequencing" do

			t = FOR(from: 0, to: 3)

			serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat

			c = -1
			d = 0

			s = Musa::Sequencer.new 4, 4 do 

				play serie do |element, control:|
					c = element[:value]

					control.after do # this will be executed 4 times
						d += 1
					end
				end
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
			expect(d).to eq(4)
		end
	end

	context "Advanced sequencing" do

		it "Event passing on at - DEPRECATED" do
			s = Musa::Sequencer.new 4, 4

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

		it "Event passing on at" do
			s = Musa::Sequencer.new 4, 4

			c = 0
			d = 0

			control = s.at 1 do
				c += 1
				launch :event, 100
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

		it "Event passing on at with inner at - DEPRECATED" do
			s = Musa::Sequencer.new 4, 4

			c = 0
			d = 0
			e = 0

			control0 = s.at 1 do |control:|

				c += 1
				
				control1 = at 2, control: control do |control:| 
					control.launch :event, 100
				end

				control2 = at 2, control: control do |control:|
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

		it "Event passing on at with inner at" do

			s = Musa::Sequencer.new 4, 4

			c = 0
			d = 0
			e = 0

			control2in = []

			control0 = s.at 1 do

				c += 1
				
				control1 = at 2 do
					launch :event, 100
				end

				control2 = at 2 do
					launch :event, 100
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
