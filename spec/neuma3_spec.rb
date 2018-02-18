require 'spec_helper'

require 'pp'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Neuma do

	context "Neuma advanced parsing" do

		scale = Musa::Scales.get(:major).based_on_pitch 60
		gdv_decoder = Musa::Dataset::GDV::NeumaDecoder.new scale

		it "Complex file neuma parsing" do
			serie = S *(Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma3_spec.neu"))
			
			puts
			puts "SERIE"
			puts "-----"
			pp serie.to_a
			puts

			played = {}

			sequencer = Musa::Sequencer.new 4, 4 do
				at 1 do
					handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
						played[position] ||= []
						played[position] << gdv #.to_pdv(scale)
					end

					handler.on :evento_raro do |a, b, c, d, kpar1:, kpar2:, kpar3:|
						played[position] ||= []
						played[position] << [ "EVENTO RARO", a, b, c, d, "KPAR1", kpar1, "KPAR2", kpar2, "KPAR3", kpar3.call(10, 20) ]
					end
				end
			end

			while sequencer.size > 0
				sequencer.tick
			end


			puts
			puts "PLAYED"
			puts "------"
			pp played

			expect(1).to eq(1)
		end
	end
end
