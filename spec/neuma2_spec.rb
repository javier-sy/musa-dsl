require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Neuma do

	context "Neuma advanced parsing" do

		it "Basic neuma inline parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 [ 9.8.7 6.5.4 ] :evento # comentario 1')).to eq(
				[ 	{ attributes: ["2", "3", "4"] }, 
					{ attributes: ["5", "6", "7"] }, 
					{ neumas: [ { attributes: ["9", "8", "7"] }, { attributes: [ "6", "5", "4" ] } ] },
					{ event: :evento } ] )

			expect(Musa::Neuma.parse('(2 3 4) [9.8.7 6.5.4] (7 8 9) { esto es un comando complejo { con { xxx } subcomando  }  { y otro } } # comentario 2')).to eq(
				[	{ attributes: ["2", "3", "4"] }, 
					{ neumas: [ { attributes: ["9", "8", "7"] }, { attributes: [ "6", "5", "4" ] } ] },
					{ attributes: ["7", "8", "9"] }, 
					{ command: "esto es un comando complejo { con { xxx } subcomando  }  { y otro }" } ] )
		end

		it "Basic neuma inline recursive parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 [ 9.8.7 [5.4.5 6.5.6] 6.5.4 [ 5.4.3]] :evento # comentario 1')).to eq(
				[ 	{ attributes: ["2", "3", "4"] }, 
					{ attributes: ["5", "6", "7"] }, 
					{ neumas: [ 
						{ attributes: ["9", "8", "7"] }, 
						{ neumas: [ { attributes: ["5", "4", "5"] }, { attributes: ["6", "5", "6"] } ] },
						{ attributes: [ "6", "5", "4" ] }, 
						{ neumas: [ { attributes: ["5", "4", "3"] } ] } ] },
					{ event: :evento } ] )
		end
	end
end
