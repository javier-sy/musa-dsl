require 'spec_helper'

require 'pp'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Neumalang do

	context "Neuma with neumalang advanced parsing" do

		scale = Musa::Scales.get(:major).based_on_pitch 60
		gdv_decoder = Musa::Dataset::GDV::NeumaDecoder.new scale
=begin
		it "Simple file neuma parsing" do
			debug = false
			#debug = true

			serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma3a_spec.neu")
			
			if debug
				puts
				puts "SERIE"
				puts "-----"
				pp serie.to_a(true)
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
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>2},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>3},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>4},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>5},
				 {:grade=>4, :octave=>0, :duration=>4, :velocity=>1},
				 {:position=>9},
				 {:grade=>5, :octave=>0, :duration=>4, :velocity=>1},
				 {:position=>13},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>14},
				 {:grade=>4, :octave=>0, :duration=>4, :velocity=>1},
				 {:position=>18},
				 {:grade=>3, :octave=>0, :duration=>4, :velocity=>1},
				 {:position=>22},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>23},
				 {:grade=>7, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>24},
				 {:grade=>8, :octave=>0, :duration=>1, :velocity=>1}]) unless debug
 		end

		it "Simple file neuma parsing with parallel series and call methods" do

			debug = false
			#debug = true

			serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma3b_spec.neu")
			
			if debug
				puts
				puts "SERIE"
				puts "-----"
				pp serie.to_a(true)
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

					handler.on :event do
						played[position] ||= [] if debug
						played[position] << [ :event ] if debug

						played << { position: position } unless debug
						played << [ :event ] unless debug
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
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>1},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>2},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>2},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>3},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>3},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>1}]) unless debug
 		end
=end
		it "Simple file neuma parsing with call_methods on simple serie" do

			debug = false
			debug = true

			serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma3c_spec.neu")
			
			if debug
				puts
				puts "SERIE"
				puts "-----"
				pp serie.to_a(true)
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

					handler.on :event do
						played[position] ||= [] if debug
						played[position] << [ :event ] if debug

						played << { position: position } unless debug
						played << [ :event ] unless debug
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
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>2},
				 [:event],
				 {:position=>2},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>3},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>4},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>5},
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>6},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>7},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>8},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>9},
				 [:event],
				 {:position=>9},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>10},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>11},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>12},
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>13},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>1},
				 {:position=>14},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>1}]) unless debug
 		end

=begin
		it "Advanced neumalang indirection features" do

			debug = true

			serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma3d_spec.neu")
			
			if debug
				puts
				puts "SERIE"
				puts "-----"
				pp serie.to_a(true)
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

					handler.on :event do
						played[position] ||= [] if debug
						played[position] << [ :event ] if debug

						played << { position: position } unless debug
						played << [ :event ] unless debug
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
				[]) unless debug
 		end

		it "Complex file neuma parsing" do
			debug = false
			debug = true

			serie = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma3z_spec.neu")
			
			if debug
				puts
				puts "SERIE"
				puts "-----"
				pp serie.to_a(true)
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
						played[position] << [ :evento, a.to_a, b.to_a, c, d, :kpar1, kpar1.to_a, :kpar2, kpar2, :kpar3, kpar3.call(10, 20) ] if debug

						played << { position: position } unless debug
						played << [ :evento, a.to_a, b.to_a, c, d, :kpar1, kpar1.to_a, :kpar2, kpar2, :kpar3, kpar3.call(10, 20) ] unless debug
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
				  [{:grade=>6, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>4, :octave=>0, :duration=>4, :velocity=>3},
				   {:grade=>3, :octave=>0, :duration=>4, :velocity=>3},
				   {:grade=>2, :octave=>0, :duration=>4, :velocity=>3},
				   {:grade=>1, :octave=>0, :duration=>2, :velocity=>-1}],
				  123,
				  100,
				  :kpar1,
				  [{:grade=>4, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>6, :octave=>0, :duration=>1, :velocity=>3}],
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
				  [{:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>2, :octave=>0, :duration=>1, :velocity=>3}],
				  3,
				  4,
				  :kpar1,
				  [{:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				   {:grade=>2, :octave=>0, :duration=>1, :velocity=>3}],
				  :kpar2,
				  10000,
				  :kpar3,
				  123456],
				 {:position=>156},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>157},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>158},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>159},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>160},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>161},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>162},
				 {:grade=>4, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>162},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>163},
				 {:grade=>2, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>163},
				 {:grade=>3, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>164},
				 {:grade=>0, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>164},
				 {:grade=>1, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>165},
				 {:grade=>6, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>166},
				 {:grade=>5, :octave=>0, :duration=>1, :velocity=>3},
				 {:position=>167},
				 {:grade=>4, :octave=>0, :duration=>4, :velocity=>3},
				 {:position=>171},
				 {:grade=>3, :octave=>0, :duration=>4, :velocity=>3},
				 {:position=>175},
				 {:grade=>2, :octave=>0, :duration=>4, :velocity=>3},
				 {:position=>179},
				 {:grade=>1, :octave=>0, :duration=>2, :velocity=>-1}]) unless debug
 		end
=end
	end
end
