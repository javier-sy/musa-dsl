require 'spec_helper'
require 'pp'
require 'musa-dsl'

RSpec.describe Musa::Neuma do

	context "Neuma advanced parsing" do

		it "Basic bracketed neuma inline parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 [ 9.8.7 6.5.4 ] ::evento # comentario 1')).to eq(
				[ 	{ neuma: ["2", "3", "4"] }, 
					{ neuma: ["5", "6", "7"] }, 
					{ serie: [ { neuma: ["9", "8", "7"] }, { neuma: [ "6", "5", "4" ] } ] },
					{ event: :evento } ] )
		end

		it "Basic bracketed neuma inline parsing with simple braced command" do
			parsed = Musa::Neuma.parse('(2 3 4) [9.8.7 6.5.4] (7 8 9) { 100 + 10 } # comentario 2')
			expect(parsed[0]).to eq({ neuma: ["2", "3", "4"] }) 
			expect(parsed[1]).to eq({ serie: [ { neuma: ["9", "8", "7"] }, { neuma: [ "6", "5", "4" ] } ] })
			expect(parsed[2]).to eq({ neuma: ["7", "8", "9"] })
			expect(parsed[3][:command].call).to eq(110)
		end

		it "Basic bracketed neuma inline parsing with complex braced command" do
			parsed = Musa::Neuma.parse('(2 3 4) [9.8.7 6.5.4] (7 8 9) { 100 + 10 + { a: 1000, b: 2000 }[:b] } # comentario 2')
			expect(parsed[0]).to eq({ neuma: ["2", "3", "4"] }) 
			expect(parsed[1]).to eq({ serie: [ { neuma: ["9", "8", "7"] }, { neuma: [ "6", "5", "4" ] } ] })
			expect(parsed[2]).to eq({ neuma: ["7", "8", "9"] })
			expect(parsed[3][:command].call).to eq(2110)
		end

		it "Basic bracketed neuma inline parsing with complex braced command" do
			parsed = Musa::Neuma.parse('(2 3 4) [9.8.7 6.5.4] (7 8 9) { 100 + 10 + { a: 1000, b: 2000 }[:b] + { a: 10000, b: 20000 }[:a] } # comentario 2')
			expect(parsed[0]).to eq({ neuma: ["2", "3", "4"] }) 
			expect(parsed[1]).to eq({ serie: [ { neuma: ["9", "8", "7"] }, { neuma: [ "6", "5", "4" ] } ] })
			expect(parsed[2]).to eq({ neuma: ["7", "8", "9"] })
			expect(parsed[3][:command].call).to eq(12110)
		end

		it "Basic bracketed neuma inline recursive parsing" do
			expect(Musa::Neuma.parse('2.3.4 5.6.7 [ 9.8.7 [5.4.5 6.5.6] 6.5.4 [ 5.4.3]] ::evento # comentario 1')).to eq(
				[ 	{ neuma: ["2", "3", "4"] }, 
					{ neuma: ["5", "6", "7"] }, 
					{ serie: [ 
						{ neuma: ["9", "8", "7"] }, 
						{ serie: [ { neuma: ["5", "4", "5"] }, { neuma: ["6", "5", "6"] } ] },
						{ neuma: [ "6", "5", "4" ] }, 
						{ serie: [ { neuma: ["5", "4", "3"] } ] } ] },
					{ event: :evento } ] )
		end

		it "Complex file neuma parsing" do
			result = Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma2_spec.neu"), debug: true

			pp result
		end
	end
end
