require 'spec_helper'

require 'musa-dsl'

include Musa::Series

module Test
	@c = nil
	def self.c= value
		@c = value
	end

	def self.c
		@c
	end
end

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

		it "At sequencing with events" do

			s = Musa::BaseSequencer.new 4, 4

			c = 0
			d = 0

			handler = s.at 1 do |control:|
				c += 1
				control.launch :evento, 100
			end

			handler.on :evento do |param|
				d = param
			end


			expect(c).to eq(0)
			expect(d).to eq(0)

			s.tick

			expect(c).to eq(1)
			expect(d).to eq(100)

			15.times do
				s.tick
			end

			expect(c).to eq(1)
			expect(d).to eq(100)
		end

		it "At sequencing with events (indented 1)" do

			s = Musa::BaseSequencer.new 4, 4

			c = 0
			d = 0

			handler = s.at 1 do
				s.at 2 do |control:|
					c += 1
					control.launch :evento, 100
				end
			end

			handler.on :evento do |param|
				d = param
			end

			expect(c).to eq(0)
			expect(d).to eq(0)

			s.tick

			expect(c).to eq(0)
			expect(d).to eq(0)

			16.times do
				s.tick
			end

			expect(c).to eq(1)
			expect(d).to eq(100)

			16.times do
				s.tick
			end

			expect(c).to eq(1)
			expect(d).to eq(100)
		end

		it "At sequencing with events (indented 2)" do

			s = Musa::BaseSequencer.new 4, 4

			c = 0
			d = 0
			e = 0

			handler = s.at 1 do
				handler2 = s.at 2 do |control:|
					c += 1
					control.launch :evento, 100
				end
				handler2.on :evento do |param|
					d = param
				end
			end

			handler.on :evento do |param|
				e = param
			end

			expect(c).to eq(0)
			expect(d).to eq(0)
			expect(e).to eq(0)

			s.tick

			expect(c).to eq(0)
			expect(d).to eq(0)
			expect(e).to eq(0)

			16.times do
				s.tick
			end

			expect(c).to eq(1)
			expect(d).to eq(100)
			expect(e).to eq(0)

			16.times do
				s.tick
			end

			expect(c).to eq(1)
			expect(d).to eq(100)
			expect(e).to eq(0)
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

		it "Basic play sequencing (II)" do

			s = Musa::BaseSequencer.new 4, 4

			serie = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat

			c = -1
			d = 0

			p = s.play serie, after: proc { d = 1 } do |element, control:|
				c = element[:value]
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

		it "Play sequencing with events handled on at control" do

			s = Musa::BaseSequencer.new 4, 4

			t = FOR(from: 0, to: 3)

			serie1 = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat
			serie2 = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat

			c = 0
			d = 0
			e = 0
			f = 0

			
			handler = s.at 1 do
				s.play serie1 do |element, control:|
					c += 1
					if element[:value] == 3
						s.play serie2 do |element2, control:|
							d += 1
							if element2[:value] == 3
								control.launch :evento, 100
							end
						end
					end
				end
			end

			handler.on :evento do |value|
				e = value
				f += 1
			end

			expect(c).to eq(0)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(2)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(3)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(1)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(2)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(3)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(4)
			expect(e).to eq(100)
			expect(f).to eq(1)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(4)
			expect(e).to eq(100)
			expect(f).to eq(1)
		end

		it "Play sequencing with events handled on sequencer" do

			s = Musa::BaseSequencer.new 4, 4

			t = FOR(from: 0, to: 3)

			serie1 = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat
			serie2 = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat

			c = 0
			d = 0
			e = 0
			f = 0

			
			s.at 1 do
				s.play serie1 do |element, control:|
					c += 1
					if element[:value] == 3
						s.play serie2 do |element2, control:|
							d += 1
							if element2[:value] == 3
								control.launch :evento, 100
							end
						end
					end
				end
			end

			s.on :evento do |value|
				e = value
				f += 1
			end

			expect(c).to eq(0)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(2)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(3)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(1)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(2)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(3)
			expect(e).to eq(0)
			expect(f).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(4)
			expect(e).to eq(100)
			expect(f).to eq(1)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(4)
			expect(e).to eq(100)
			expect(f).to eq(1)
		end

		it "Play sequencing with events (II)" do

			s = Musa::BaseSequencer.new 4, 4

			t = FOR(from: 0, to: 3)

			serie1 = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat
			serie2 = H value: FOR(from: 0, to: 3), duration: S(Rational(1,16)).repeat

			c = 0
			d = 0
			e = 0
			f = 0
			g = 0
			
			handler = s.at 1 do
				handler2 = s.play serie1 do |element, control:|
					c += 1
					if element[:value] == 3
						s.play serie2 do |element2, control:|
							d += 1
							if element2[:value] == 3
								control.launch :evento, 100
							end
						end
					end
				end

				handler2.on :evento do |value|
					e = value
					f += 1
				end
			end

			handler.on :evento do |value|
				g = value
			end

			expect(c).to eq(0)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(1)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(2)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(3)
			expect(d).to eq(0)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(1)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(2)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(3)
			expect(e).to eq(0)
			expect(f).to eq(0)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(4)
			expect(e).to eq(100)
			expect(f).to eq(1)
			expect(g).to eq(0)

			s.tick
			expect(c).to eq(4)
			expect(d).to eq(4)
			expect(e).to eq(100)
			expect(f).to eq(1)
			expect(g).to eq(0)
		end

		it "Basic theme sequencing" do

			Test.c = 0

			class Theme1
				include Musa::BaseTheme
				
				def initialize(parameter1:, parameter2:)
					@parameter1 = parameter1
					@parameter2 = parameter2
				end

				def run(parameter3:)
					Test.c = @parameter1 + @parameter2 + parameter3
				end
			end

			s = Musa::BaseSequencer.new 4, 4

			s.theme Theme1, at: S(1, 2, 3), parameter1: 1000, parameter2: 200, parameter3: S(10, 20, 30) 

			expect(Test.c).to eq(0)

			s.tick

			expect(Test.c).to eq(1210)

			16.times { || s.tick }

			expect(Test.c).to eq(1220)

			15.times { || s.tick }

			expect(Test.c).to eq(1220)

			s.tick

			expect(Test.c).to eq(1230)
		end
	end
end
