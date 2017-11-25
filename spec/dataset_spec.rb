require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Neuma do

	context "Dataset transformations" do

		GDV = Musa::Dataset::GDV

		it "GDV to PDVE" do
			
			scale = Musa::Scales.get(:major).based_on_pitch 60

			expect({ grade: 3, duration: 1, velocity: 4 }.extend(Musa::Dataset::GDV).to_pdve(scale)).to eq({ pitch: 60+5, duration: 1, velocity: 127})
			expect({ grade: 8, duration: 1, velocity: -3 }.extend(Musa::Dataset::GDV).to_pdve(scale)).to eq({ pitch: 60+12+2, duration: 1, velocity: 16})
			expect({ duration: 0, event: :evento }.extend(Musa::Dataset::GDV).to_pdve(scale)).to eq({ duration: 0, event: :evento})
		end

		it "GDV to PDVE (with module alias)" do
			

			scale = Musa::Scales.get(:major).based_on_pitch 60

			expect({ grade: 3, duration: 1, velocity: 4 }.extend(GDV).to_pdve(scale)).to eq({ pitch: 60+5, duration: 1, velocity: 127})
			expect({ grade: 8, duration: 1, velocity: -3 }.extend(GDV).to_pdve(scale)).to eq({ pitch: 60+12+2, duration: 1, velocity: 16})
			
			h = { duration: 0, event: :evento }.extend GDV
			expect(h.to_pdve(scale)).to eq({ duration: 0, event: :evento })
		end

		it "GDV neuma to PDVE and back to neuma" do
			
			gdv_neumas = '0 . +1 2.p 2.1/2.p'

			scale = Musa::Scales.get(:major).based_on_pitch 60

			decoder = GDV::NeumaDifferentialDecoder.new scale

			result_gdve = Musa::Neuma.parse gdv_neumas, decode_with: decoder

			result_pdve = result_gdve.collect { |g| g.to_pdve(scale) }

			result_gdve2 = result_pdve.collect { |p| p.to_gdve(scale) }

			result_neuma = result_gdve2.collect { |g| g.to_neuma }

			result = result_neuma.join ' '

			expect(result).to eq(gdv_neumas)
		end

	end
end
