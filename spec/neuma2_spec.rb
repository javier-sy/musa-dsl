require 'spec_helper'
require 'pp'
require 'musa-dsl'

RSpec.describe Musa::Neuma do

	context "Neuma advanced parsing" do

		it "Basic bracketed neuma inline parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 [ 9.8.7 6.5.4 ] :evento # comentario 1')).to eq(
				[ 	{ neuma: ["2", "3", "4"] }, 
					{ neuma: ["5", "6", "7"] }, 
					{ serie: [ { neuma: ["9", "8", "7"] }, { neuma: [ "6", "5", "4" ] } ] },
					{ event: :evento } ] )

			expect(Musa::Neuma.parse('(2 3 4) [9.8.7 6.5.4] (7 8 9) { esto es un comando complejo { con { xxx } subcomando  }  { y otro } } # comentario 2')).to eq(
				[	{ neuma: ["2", "3", "4"] }, 
					{ serie: [ { neuma: ["9", "8", "7"] }, { neuma: [ "6", "5", "4" ] } ] },
					{ neuma: ["7", "8", "9"] }, 
					{ command: "esto es un comando complejo { con { xxx } subcomando  }  { y otro }" } ] )
		end

		it "Basic bracketed neuma inline recursive parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 [ 9.8.7 [5.4.5 6.5.6] 6.5.4 [ 5.4.3]] :evento # comentario 1')).to eq(
				[ 	{ neuma: ["2", "3", "4"] }, 
					{ neuma: ["5", "6", "7"] }, 
					{ serie: [ 
						{ neuma: ["9", "8", "7"] }, 
						{ serie: [ { neuma: ["5", "4", "5"] }, { neuma: ["6", "5", "6"] } ] },
						{ neuma: [ "6", "5", "4" ] }, 
						{ serie: [ { neuma: ["5", "4", "3"] } ] } ] },
					{ event: :evento } ] )
		end

		it "" do
			result = Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma2_spec.neu"), debug: true

			pp result
		end
	end
end
