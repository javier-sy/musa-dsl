require 'spec_helper'

require 'pp'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Neuma do

	context "Neuma with neumalang advanced parsing" do

		debug = false
		#debug = true

		scale = Musa::Scales.get(:major).based_on_pitch 60
		gdv_decoder = Musa::Dataset::GDV::NeumaDecoder.new scale

		it "Complex file neuma parsing" do
			serie = S *(Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma3_spec.neu"))
			
			if debug
				puts
				puts "SERIE"
				puts "-----"
				pp serie.to_a
				puts
			end

			played = {} if debug
			played = [] unless debug

			sequencer = Musa::Sequencer.new 4, 4 do
				at 1 do
					handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
						played[position] ||= [] if debug
						played[position] << gdv if debug #.to_pdv(scale)

						played << { position: position } unless debug
						played << gdv unless debug #.to_pdv(scale)
					end

					handler.on :evento do |a, b, c, d, kpar1:, kpar2:, kpar3:|
						played[position] ||= [] if debug
						played[position] << [ :evento, a.to_a, b.to_a, c, d, :kpar, kpar1.to_a, :kpar2, kpar2, :kpar3, kpar3.call(10, 20) ] if debug

						played << { position: position } unless debug
						played << [ :evento, a.to_a, b.to_a, c, d, :kpar, kpar1.to_a, :kpar2, kpar2, :kpar3, kpar3.call(10, 20) ] unless debug
					end
				end
			end

			while sequencer.size > 0
				sequencer.tick
			end

			if debug
				puts
				puts "PLAYED"
				puts "------"
				pp played
			end

			expect(played).to eq(
				[{:position=>1},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>2},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>3},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>4},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>5},
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>6},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>7},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>8},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>9},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>10},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>11},
				 {:grade=>7, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>12},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>13},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>14},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>15},
				 {:grade=>8, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>16},
				 {:grade=>9, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>17},
				 {:grade_x=>6, :octave_x=>0, :duration=>100, :velocity_x=>3},
				 {:position=>117},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>117},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>118},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>118},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>119},
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>119},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>120},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>121},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>122},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>123},
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>124},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>125},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>126},
				 {:grade=>1, :octave=>0, :duration=>2, :velocity=>-1},
				 {:position=>128},
				 {:grade=>2, :octave=>0, :duration=>2, :velocity=>-1},
				 {:position=>130},
				 {:grade=>3, :octave=>0, :duration=>2, :velocity=>-1},
				 {:position=>132},
				 {:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>140},
				 {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>148},
				 {:grade=>6, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>156},
				 [:evento,
				  [{:grade=>1, :octave=>0, :duration=>2, :velocity=>-1},
				   {:grade=>2, :octave=>0, :duration=>2, :velocity=>-1},
				   {:grade=>3, :octave=>0, :duration=>2, :velocity=>-1},
				   {:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>6, :octave=>0, :duration=>8, :velocity=>-1}],
				  [],
				  123,
				  {:grade=>100, :octave=>0, :duration=>8, :velocity=>-1},
				  :kpar,
				  [{:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>6, :octave=>0, :duration=>8, :velocity=>-1}],
				  :kpar2,
				  10000,
				  :kpar3,
				  200],
				 {:position=>156},
				 [:evento,
				  [{:grade=>1, :octave=>0, :duration=>2, :velocity=>-1},
				   {:grade=>2, :octave=>0, :duration=>2, :velocity=>-1},
				   {:grade=>3, :octave=>0, :duration=>2, :velocity=>-1},
				   {:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>6, :octave=>0, :duration=>8, :velocity=>-1}],
				  [{:grade=>0, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>1, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>2, :octave=>0, :duration=>8, :velocity=>-1}],
				  3,
				  4,
				  :kpar,
				  [{:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				   {:grade=>6, :octave=>0, :duration=>8, :velocity=>-1}],
				  :kpar2,
				  10000,
				  :kpar3,
				  123456],
				 {:position=>156},
				 {:grade=>0, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>164},
				 {:grade=>0, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>172},
				 {:grade=>0, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>180},
				 {:grade=>2, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>188},
				 {:grade=>1, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>196},
				 {:grade=>0, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>204},
				 {:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>204},
				 {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>212},
				 {:grade=>2, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>212},
				 {:grade=>3, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>220},
				 {:grade=>0, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>220},
				 {:grade=>1, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>228},
				 {:grade=>6, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>236},
				 {:grade=>5, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>244},
				 {:grade=>4, :octave=>0, :duration=>8, :velocity=>-1},
				 {:position=>252},
				 {:grade=>3, :octave=>0, :duration=>2, :velocity=>-1},
				 {:position=>254},
				 {:grade=>2, :octave=>0, :duration=>2, :velocity=>-1},
				 {:position=>256},
				 {:grade=>1, :octave=>0, :duration=>2, :velocity=>-1}]) unless debug
 		end
	end
end
