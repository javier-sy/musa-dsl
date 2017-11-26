require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Neuma do

	context "Dataset transformations" do

		GDV = Musa::Dataset::GDV

		it "GDV to PDVE" do
			
			scale = Musa::Scales.get(:major).based_on_pitch 60

			expect({ grade: 3, duration: 1, velocity: 4 }.extend(Musa::Dataset::GDV).to_pdv(scale)).to eq({ pitch: 60+5, duration: 1, velocity: 127})
			expect({ grade: 8, duration: 1, velocity: -3 }.extend(Musa::Dataset::GDV).to_pdv(scale)).to eq({ pitch: 60+12+2, duration: 1, velocity: 16})
			expect({ duration: 0, event: :evento }.extend(Musa::Dataset::GDV).to_pdv(scale)).to eq({ duration: 0, event: :evento})
		end

		it "GDV to PDVE (with module alias)" do
			

			scale = Musa::Scales.get(:major).based_on_pitch 60

			expect({ grade: 3, duration: 1, velocity: 4 }.extend(GDV).to_pdv(scale)).to eq({ pitch: 60+5, duration: 1, velocity: 127})
			expect({ grade: 8, duration: 1, velocity: -3 }.extend(GDV).to_pdv(scale)).to eq({ pitch: 60+12+2, duration: 1, velocity: 16})
			
			h = { duration: 0, event: :evento }.extend GDV
			expect(h.to_pdv(scale)).to eq({ duration: 0, event: :evento })
		end

		it "GDV neuma to PDVE and back to neuma via GDV::NeumaDecoder" do
			
			gdv_abs_neumas = '0.1.p 0.2.p 0.3.p 2.3.fff 1.2.fff 5.1/2.ppp'
			
			scale = Musa::Scales.get(:major).based_on_pitch 60

			decoder = GDV::NeumaDecoder.new scale 

			result_gdv = Musa::Neuma.parse gdv_abs_neumas, decode_with: decoder

			result_pdv = result_gdv.collect { |g| g.to_pdv(scale) }

			puts "result_pdv = #{result_pdv}"

			result_gdv2 = result_pdv.collect { |p| p.to_gdv(scale) }

			puts "result_gdv2 = #{result_gdv2}"

			result_neuma = result_gdv2.collect { |g| g.to_neuma }

			result = result_neuma.join ' '

			expect(result).to eq(gdv_abs_neumas)
		end

		it "GDV neuma to GDVd neuma via GDV::NeumaDecoder" do
			
			gdv_abs_neumas = '0.1.p 0.2.p 0.3.p 2.3.fff 1.2.fff 5.1/2.ppp'
			gdv_diff_neumas = '0.1.p .+1 .+1 +2.+fffff -1.-1 +4.-3/2.-fffffff'
			
			scale = Musa::Scales.get(:major).based_on_pitch 60

			decoder = GDV::NeumaDecoder.new scale 

			result_gdv = Musa::Neuma.parse gdv_abs_neumas, decode_with: decoder

			result_gdvd = result_gdv.each_index.collect { |i| result_gdv[i].to_gdvd scale, previous: (i>0?result_gdv[i-1]:nil) }

			result_neuma = result_gdvd.collect { |gd| gd.to_neuma }

			result = result_neuma.join ' '

			expect(result).to eq(gdv_diff_neumas)
		end


		it "GDV neuma to GDVd and back to neuma via GDV::DifferentialDecoder" do
			
			gdv_diff_neumas = '0 . +1 2.p 2.1/2.p'

			decoder = GDV::NeumaDifferentialDecoder.new 

			result_gdvd = Musa::Neuma.parse gdv_diff_neumas, decode_with: decoder

			result_neuma = result_gdvd.collect { |gd| gd.to_neuma }

			result = result_neuma.join ' '

			expect(result).to eq(gdv_diff_neumas)
		end

		it "GDV diff neuma to GDVd and back to GDV abs neuma via GDV::DifferentialDecoder" do
			
			gdv_diff_neumas = '0.1.mf . +1 2.p 2.1/2.p'
			gdv_abs_neumas = '0.1.mf 0.1.mf 1.1.mf 2.1.p 2.1/2.p'

			scale = Musa::Scales.get(:major).based_on_pitch 60

			decoder = GDV::NeumaDecoder.new scale

			result_gdv = Musa::Neuma.parse gdv_diff_neumas, decode_with: decoder

			result_neuma = result_gdv.collect { |g| g.to_neuma }

			result = result_neuma.join ' '

			expect(result).to eq(gdv_abs_neumas)
		end
	end
end
