require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Neuma do

	context "Dataset transformations" do

		it "GDV to PDVE" do
			
			scale = Musa::Scales.get(:major).based_on_pitch 60

			expect({ grade: 3, duration: 1, velocity: 4 }.extend(Musa::Dataset::GDV).to_pdve(scale)).to eq({ pitch: 60+5, duration: 1, velocity: 127})
			expect({ grade: 8, duration: 1, velocity: -3 }.extend(Musa::Dataset::GDV).to_pdve(scale)).to eq({ pitch: 60+12+2, duration: 1, velocity: 16})
			expect({ duration: 0, event: :evento }.extend(Musa::Dataset::GDV).to_pdve(scale)).to eq({ duration: 0, event: :evento})
		end

		it "GDV to PDVE (with module alias)" do
			
			GDV = Musa::Dataset::GDV

			scale = Musa::Scales.get(:major).based_on_pitch 60

			expect({ grade: 3, duration: 1, velocity: 4 }.extend(GDV).to_pdve(scale)).to eq({ pitch: 60+5, duration: 1, velocity: 127})
			expect({ grade: 8, duration: 1, velocity: -3 }.extend(GDV).to_pdve(scale)).to eq({ pitch: 60+12+2, duration: 1, velocity: 16})
			
			h = { duration: 0, event: :evento }.extend GDV
			expect(h.to_pdve(scale)).to eq({ duration: 0, event: :evento })
		end
	end
end
