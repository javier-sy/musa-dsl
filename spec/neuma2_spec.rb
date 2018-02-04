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
			result = Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma2_spec.neu")

			expect(result).to eq(
				[{:assign_to=>[:b, :a],
				  :value=>
				   {:serie=>
				     [{:neuma=>["I", "1", "ff"]},
				      {:neuma=>[]},
				      {:neuma=>[nil, "*1/2"]},
				      {:neuma=>[]},
				      {:neuma=>["2"]}]}},
				 {:assign_to=>[:c],
				  :value=>
				   {:parallel=>
				     [[{:event=>:event1,
				        :value_parameters=>
				         [{:serie=>[{:neuma=>["100"]}]}, {:use_variable=>:b}]}],
				      [{:event=>:event2}, {:neuma=>["100", "200", "300"]}],
				      [{:event=>:event3,
				        :value_parameters=>
				         [{:value=>100}, {:neuma=>["I", "2", "ff"]}, {:value=>300}]}],
				      [{:event=>:event4, :value_parameters=>[{:value=>:simbolo}]}]]}},
				 {:use_variable=>:a},
				 {:serie=>
				   [{:use_variable=>:a}, {:neuma=>["silence", "2"]}, {:use_variable=>:a}]},
				 {:parallel=>
				   [[{:use_variable=>:a1}, {:use_variable=>:a2}, {:use_variable=>:a3}],
				    [{:use_variable=>:b1}, {:use_variable=>:b2}],
				    [{:use_variable=>:c}]]},
				 {:parallel=>[[{:use_variable=>:a}], [{:use_variable=>:b}]]},
				 {:parallel=>[[{:neuma=>["a"]}], [{:neuma=>["b"]}], [{:neuma=>["c"]}]]},
				 {:parallel=>
				   [[{:assign_to=>[:b],
				      :value=>
				       {:serie=>
				         [{:neuma=>["1", "2", "p"]},
				          {:neuma=>["2"]},
				          {:neuma=>["1"]},
				          {:neuma=>["2"]}]}},
				     {:use_variable=>:b}],
				    [{:neuma=>["silence", "4"]},
				     {:use_variable=>:b,
				      :call_method=>
				       [{:method=>:reverse, :value_parameters=>[{:value=>199}]},
				        {:method=>:other_operation,
				         :value_parameters=>[{:use_variable=>:xxx}]},
				        {:method=>:another_more,
				         :value_parameters=>
				          [{:value=>"esto es un texto string"}]}]},
				     {:use_variable=>:b, :call_method=>[{:method=>:inverse}]}]]},
				 {:event=>:event_with_key_parameters,
				  :key_parameters=>
				   {:a=>{:value=>100},
				    :b=>{:value=>200},
				    :c=>{:serie=>[{:neuma=>["1", "2", "f"]}, {:neuma=>["3", "2", "p"]}]}}},
				 {:event=>:event_with_value_and_key_parameters,
				  :value_parameters=>
				   [{:value=>1100}, {:value=>250}, {:value=>"texto"}, {:value=>:simbolo}],
				  :key_parameters=>
				   {:a=>{:value=>100},
				    :b=>{:value=>200},
				    :c=>{:serie=>[{:neuma=>["1", "2", "f"]}, {:neuma=>["3", "2", "p"]}]}}},
				 {:use_variable=>:b,
				  :call_method=>
				   [{:method=>:haz_algo,
				     :value_parameters=>
				      [{:value=>1100}, {:value=>250}, {:value=>"texto"}, {:value=>:simbolo}],
				     :key_parameters=>
				      {:a=>{:value=>100},
				       :b=>{:value=>200},
				       :c=>
				        {:serie=>[{:neuma=>["1", "2", "f"]}, {:neuma=>["3", "2", "p"]}]}}}]}])
		end
	end
end
