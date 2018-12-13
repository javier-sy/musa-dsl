require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Neumalang do

  context "Neuma advanced parsing" do

    it "Basic bracketed neuma inline parsing" do
      expect(Musa::Neumalang.parse('2.3.4 5.6.7 [ 9.8.7 6.5.4 ] ::evento # comentario 1').to_a(recursive: true)).to eq(
        [   { kind: :neuma, neuma: ["2", "3", "4"] },
          { kind: :neuma, neuma: ["5", "6", "7"] },
          { kind: :serie, serie: [ { kind: :neuma, neuma: ["9", "8", "7"] }, { kind: :neuma, neuma: [ "6", "5", "4" ] } ] },
          { kind: :event, event: :evento } ] )
    end

    it "Basic bracketed neuma inline parsing with simple braced command" do
      parsed = Musa::Neumalang.parse('<2 3 4> [9.8.7 6.5.4] <7 8 9> { 100 + 10 } # comentario 2').to_a(recursive: true)
      expect(parsed[0]).to eq({ kind: :neuma, neuma: ["2", "3", "4"] })
      expect(parsed[1]).to eq({ kind: :serie, serie: [ { kind: :neuma, neuma: ["9", "8", "7"] }, { kind: :neuma, neuma: [ "6", "5", "4" ] } ] })
      expect(parsed[2]).to eq({ kind: :neuma, neuma: ["7", "8", "9"] })
      expect(parsed[3][:command].call).to eq(110)
    end

    it "Basic bracketed neuma inline parsing with complex braced command" do
      parsed = Musa::Neumalang.parse('<2 3 4> [9.8.7 6.5.4] <7 8 9> { 100 + 10 + { a: 1000, b: 2000 }[:b] } # comentario 2').to_a(recursive: true)
      expect(parsed[0]).to eq({ kind: :neuma, neuma: ["2", "3", "4"] })
      expect(parsed[1]).to eq({ kind: :serie, serie: [ { kind: :neuma, neuma: ["9", "8", "7"] }, { kind: :neuma, neuma: [ "6", "5", "4" ] } ] })
      expect(parsed[2]).to eq({ kind: :neuma, neuma: ["7", "8", "9"] })
      expect(parsed[3][:command].call).to eq(2110)
    end

    it "Basic bracketed neuma inline parsing with complex braced command" do
      parsed = Musa::Neumalang.parse('<2 3 4> [9.8.7 6.5.4] <7 8 9> { 100 + 10 + { a: 1000, b: 2000 }[:b] + { a: 10000, b: 20000 }[:a] } # comentario 2').to_a(recursive: true)
      expect(parsed[0]).to eq({ kind: :neuma, neuma: ["2", "3", "4"] })
      expect(parsed[1]).to eq({ kind: :serie, serie: [ { kind: :neuma, neuma: ["9", "8", "7"] }, { kind: :neuma, neuma: [ "6", "5", "4" ] } ] })
      expect(parsed[2]).to eq({ kind: :neuma, neuma: ["7", "8", "9"] })
      expect(parsed[3][:command].call).to eq(12110)
    end

    it "Basic bracketed neuma inline recursive parsing" do
      expect(Musa::Neumalang.parse('2.3.4 5.6.7 [ 9.8.7 [5.4.5 6.5.6] 6.5.4 [ 5.4.3]] ::evento # comentario 1').to_a(recursive: true)).to eq(
        [   { kind: :neuma, neuma: ["2", "3", "4"] },
          { kind: :neuma, neuma: ["5", "6", "7"] },
          { kind: :serie, serie: [
            { kind: :neuma, neuma: ["9", "8", "7"] },
            { kind: :serie, serie: [ { kind: :neuma, neuma: ["5", "4", "5"] }, { kind: :neuma, neuma: ["6", "5", "6"] } ] },
            { kind: :neuma, neuma: [ "6", "5", "4" ] },
            { kind: :serie, serie: [ { kind: :neuma, neuma: ["5", "4", "3"] } ] } ] },
          { kind: :event, event: :evento } ] )
    end

    it "Complex file neuma parsing" do
      result = Musa::Neumalang.parse_file(File.join(File.dirname(__FILE__), "neuma2_spec.neu")).to_a(recursive: true)

      expect(result).to eq(
        [{kind: :assign_to, :assign_to=>[:@b, :@a],
          :assign_value=>
           {kind: :serie, :serie=>
             [{kind: :neuma, :neuma=>["I", "1", "ff"]},
              {kind: :neuma, :neuma=>[]},
              {kind: :neuma, :neuma=>[nil, "*1/2"]},
              {kind: :neuma, :neuma=>[]},
              {kind: :neuma, :neuma=>["2"]}]}},
         {kind: :assign_to, :assign_to=>[:@c],
          :assign_value=>
           {kind: :parallel, :parallel=>
             [{kind: :serie, serie:[{kind: :event, :event=>:event1,
                :value_parameters=>
                 [{kind: :serie, :serie=>[{kind: :neuma, :neuma=>["100"]}]}, {kind: :use_variable, :use_variable=>:@b}]}]},
              {kind: :serie, serie: [{kind: :event, :event=>:event2}, {kind: :neuma, :neuma=>["100", "200", "300"]}]},
              {kind: :serie, serie: [{kind: :event, :event=>:event3,
                :value_parameters=>
                 [{kind: :value, :value=>100}, {kind: :neuma, :neuma=>["I", "2", "ff"]}, {kind: :value, :value=>300}]}]},
              {kind: :serie, serie: [{kind: :event, :event=>:event4, :value_parameters=>[{kind: :value, :value=>:simbolo}]}] } ]}},
         {kind: :use_variable, :use_variable=>:@a},
         {kind: :serie, :serie=>
           [{kind: :use_variable, :use_variable=>:@a}, {kind: :neuma, :neuma=>["silence", "2"]}, {kind: :use_variable, :use_variable=>:@a}]},
         {kind: :parallel, :parallel=>
           [{kind: :serie, serie: [{kind: :use_variable, :use_variable=>:@a1}, {kind: :use_variable, :use_variable=>:@a2}, {kind: :use_variable, :use_variable=>:@a3}] },
            {kind: :serie, serie: [{kind: :use_variable, :use_variable=>:@b1}, {kind: :use_variable, :use_variable=>:@b2}] },
            {kind: :serie, serie: [{kind: :use_variable, :use_variable=>:@c}] } ]},

         {kind: :parallel, :parallel=>[ {kind: :serie, serie: [{kind: :use_variable, :use_variable=>:@a}]}, { kind: :serie, serie: [{kind: :use_variable, :use_variable=>:@b}] } ]},
         {kind: :parallel, :parallel=>[ {kind: :serie, serie: [{kind: :neuma, :neuma=>["a"]}] }, { kind: :serie, serie: [{kind: :neuma, :neuma=>["b"]}] }, {kind: :serie, serie: [{kind: :neuma, :neuma=>["c"]}] } ]},
         {kind: :parallel, :parallel=>
           [{ kind: :serie, serie: [{kind: :assign_to, :assign_to=>[:@b],
              :assign_value=>
               {kind: :serie, :serie=>
                 [{kind: :neuma, :neuma=>["1", "2", "p"]},
                  {kind: :neuma, :neuma=>["2"]},
                  {kind: :neuma, :neuma=>["1"]},
                  {kind: :neuma, :neuma=>["2"]}]}},
             {kind: :use_variable, :use_variable=>:@b}] },
            { kind: :serie, serie: [{kind: :neuma, :neuma=>["silence", "4"]},
             {kind: :call_methods, :call_methods=>
               [{:method=>:reverse, :value_parameters=>[{kind: :value, :value=>199}]},
                {:method=>:other_operation,
                 :value_parameters=>[{kind: :use_variable, :use_variable=>:@xxx}]},
                {:method=>:another_more,
                 :value_parameters=>
                  [{kind: :value, :value=>"esto es un texto string"}]}],
                  on: { kind: :use_variable, :use_variable=>:@b }},
             {kind: :call_methods, :call_methods=>[{:method=>:inverse}], on: { kind: :use_variable, :use_variable=>:@b } }] } ]},
         {kind: :event, :event=>:event_with_key_parameters,
          :key_parameters=>
           {:a=>{kind: :value, :value=>100.25},
            :b=>{kind: :value, :value=>200},
            :c=>{kind: :serie, :serie=>[{kind: :neuma, :neuma=>["1", "2", "f"]}, {kind: :neuma, :neuma=>["3", "2", "p"]}]}}},
         {kind: :event, :event=>:event_with_value_and_key_parameters,
          :value_parameters=>
           [{kind: :value, :value=>1100}, {kind: :value, :value=>250}, {kind: :value, :value=>"texto"}, {kind: :value, :value=>:simbolo}],
          :key_parameters=>
           {:a=>{kind: :value, :value=>100},
            :b=>{kind: :value, :value=>200},
            :c=>{kind: :serie, :serie=>[{kind: :neuma, :neuma=>["1", "2", "f"]}, {kind: :neuma, :neuma=>["3", "2", "p"]}]}}},
         {kind: :call_methods, :call_methods=>
           [{:method=>:haz_algo,
             :value_parameters=>
              [{kind: :value, :value=>1100}, {kind: :value, :value=>250}, {kind: :value, :value=>"texto"}, {kind: :value, :value=>:simbolo}],
             :key_parameters=>
              {:a=>{kind: :value, :value=>100},
               :b=>{kind: :value, :value=>200},
               :c=>
                {kind: :serie, :serie=>[{kind: :neuma, :neuma=>["1", "2", "f"]}, {kind: :neuma, :neuma=>["3", "2", "p"]}]}}}], on: { kind: :use_variable, :use_variable=>:@b } }]) unless true
    end
  end
end
