require 'spec_helper'

require 'musa-dsl'

include Musa::Neumalang

RSpec.describe Musa::Neumalang do

  context "Neuma advanced parsing" do

    it "Basic bracketed neumas inline parsing" do
      expect(Neumalang.parse('2.3 5.6 [ 9.8 6.5 ] ::evento /* comentario 1 */').to_a(recursive: true)).to eq(
        [   { kind: :neuma, neuma: { abs_grade: 2, abs_duration: 3 } },
          { kind: :neuma, neuma: { abs_grade: 5, abs_duration: 6 } },
          { kind: :serie, serie: [ { kind: :neuma, neuma: { abs_grade: 9, abs_duration: 8 } },
                                   { kind: :neuma, neuma: { abs_grade: 6, abs_duration: 5 } } ] },
          { kind: :event, event: :evento } ] )
    end

    it "Basic bracketed neumas inline parsing with simple braced command" do
      parsed = Neumalang.parse('(2 3) [9.8 6.5] (7 8) { 100 + 10 } /* comentario 2 */').to_a(recursive: true)
      expect(parsed[0]).to eq({ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 3 } })
      expect(parsed[1]).to eq({ kind: :serie, serie: [ { kind: :neuma, neuma: { abs_grade: 9, abs_duration: 8 } },
                                                       { kind: :neuma, neuma: { abs_grade: 6, abs_duration: 5 } } ] })
      expect(parsed[2]).to eq({ kind: :neuma, neuma: { abs_grade: 7, abs_duration: 8 } })
      expect(parsed[3][:command].call).to eq(110)
    end

    it "Basic bracketed neumas inline parsing with complex braced command" do
      parsed = Neumalang.parse('(2 3) [9.8 6.5] (7 8) { 100 + 10 + { a: 1000, b: 2000 }[:b] } /* comentario 2 */').to_a(recursive: true)
      expect(parsed[0]).to eq({ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 3 } })
      expect(parsed[1]).to eq({ kind: :serie, serie: [ { kind: :neuma, neuma: { abs_grade: 9, abs_duration: 8 } },
                                                       { kind: :neuma, neuma: { abs_grade: 6, abs_duration: 5 } } ] })
      expect(parsed[2]).to eq({ kind: :neuma, neuma: { abs_grade: 7, abs_duration: 8 } })
      expect(parsed[3][:command].call).to eq(2110)
    end

    it "Basic bracketed neumas inline parsing with complex braced command" do
      parsed = Neumalang.parse('(2 3) [9.8 6.5] (7 8) { 100 + 10 + { a: 1000, b: 2000 }[:b] + { a: 10000, b: 20000 }[:a] } /* comentario 2 */').to_a(recursive: true)
      expect(parsed[0]).to eq({ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 3 } })
      expect(parsed[1]).to eq({ kind: :serie, serie: [ { kind: :neuma, neuma: { abs_grade: 9, abs_duration: 8 } },
                                                       { kind: :neuma, neuma: { abs_grade: 6, abs_duration: 5 } } ] })
      expect(parsed[2]).to eq({ kind: :neuma, neuma: { abs_grade: 7, abs_duration: 8 } })
      expect(parsed[3][:command].call).to eq(12110)
    end

    it "Basic bracketed neumas inline recursive parsing" do
      expect(Neumalang.parse('2.3 5.6 [ 9.8 [5.4 6.5] 6.5 [ 5.4]] ::evento /* comentario 1 */').to_a(recursive: true)).to eq(
        [   { kind: :neuma, neuma: { abs_grade: 2, abs_duration: 3 } },
          { kind: :neuma, neuma: { abs_grade: 5, abs_duration: 6 } },
          { kind: :serie, serie: [
            { kind: :neuma, neuma: { abs_grade: 9, abs_duration: 8 } },
            { kind: :serie, serie: [ { kind: :neuma, neuma: { abs_grade: 5, abs_duration: 4 } },
                                     { kind: :neuma, neuma: { abs_grade: 6, abs_duration: 5 } } ] },
            { kind: :neuma, neuma: { abs_grade: 6, abs_duration: 5 } },
            { kind: :serie, serie: [ { kind: :neuma, neuma: { abs_grade: 5, abs_duration: 4 } } ] } ] },
          { kind: :event, event: :evento } ] )
    end

    it "Complex file neumas parsing" do
      result = Neumalang.parse_file(File.join(File.dirname(__FILE__), "neuma2_spec.neu")).to_a(recursive: true)
      expect(result).to eq(
        [{:kind=>:assign_to,
          :assign_to=>[:@b, :@a],
          :assign_value=>
              {:kind=>:serie,
               :serie=>
                   [{:kind=>:neuma,
                     :neuma=>{:abs_grade=>:I, :abs_duration=>1, :abs_velocity=>3}},
                    {:kind=>:neuma, :neuma=>{}},
                    {:kind=>:neuma, :neuma=>{:factor_duration=>1/2r}},
                    {:kind=>:neuma, :neuma=>{}},
                    {:kind=>:neuma, :neuma=>{:abs_grade=>2}}]}},
         {:kind=>:assign_to,
          :assign_to=>[:@c],
          :assign_value=>
              {:kind=>:parallel,
               :parallel=>
                   [{:kind=>:serie,
                     :serie=>
                         [{:kind=>:event,
                           :event=>:event1,
                           :value_parameters=>
                               [{:kind=>:serie,
                                 :serie=>[{:kind=>:neuma, :neuma=>{:abs_grade=>100}}]},
                                {:kind=>:use_variable, :use_variable=>:@b}]}]},
                    {:kind=>:serie,
                     :serie=>
                         [{:kind=>:event, :event=>:event2},
                          {:kind=>:neuma,
                           :neuma=>{:abs_grade=>100, :abs_duration=>200, :abs_velocity=>4}}]},
                    {:kind=>:serie,
                     :serie=>
                         [{:kind=>:event,
                           :event=>:event3,
                           :value_parameters=>
                               [{:kind=>:value, :value=>100},
                                {:kind=>:neuma,
                                 :neuma=>{:abs_grade=>:I, :abs_duration=>2, :abs_velocity=>3}},
                                {:kind=>:value, :value=>300}]}]},
                    {:kind=>:serie,
                     :serie=>
                         [{:kind=>:event,
                           :event=>:event4,
                           :value_parameters=>[{:kind=>:value, :value=>:simbolo}]}]}]}},
         {:kind=>:use_variable, :use_variable=>:@a},
         {:kind=>:serie,
          :serie=>
              [{:kind=>:use_variable, :use_variable=>:@a},
               {:kind=>:neuma, :neuma=>{:abs_grade=>:silence, :abs_duration=>2}},
               {:kind=>:use_variable, :use_variable=>:@a}]},
         {:kind=>:parallel,
          :parallel=>
              [{:kind=>:serie,
                :serie=>
                    [{:kind=>:use_variable, :use_variable=>:@a1},
                     {:kind=>:use_variable, :use_variable=>:@a2},
                     {:kind=>:use_variable, :use_variable=>:@a3}]},
               {:kind=>:serie,
                :serie=>
                    [{:kind=>:use_variable, :use_variable=>:@b1},
                     {:kind=>:use_variable, :use_variable=>:@b2}]},
               {:kind=>:serie, :serie=>[{:kind=>:use_variable, :use_variable=>:@c}]}]},
         {:kind=>:parallel,
          :parallel=>
              [{:kind=>:serie, :serie=>[{:kind=>:use_variable, :use_variable=>:@a}]},
               {:kind=>:serie, :serie=>[{:kind=>:use_variable, :use_variable=>:@b}]}]},
         {:kind=>:parallel,
          :parallel=>
              [{:kind=>:serie, :serie=>[{:kind=>:neuma, :neuma=>{:abs_grade=>:a}}]},
               {:kind=>:serie, :serie=>[{:kind=>:neuma, :neuma=>{:abs_grade=>:b}}]},
               {:kind=>:serie, :serie=>[{:kind=>:neuma, :neuma=>{:abs_grade=>:c}}]}]},
         {:kind=>:parallel,
          :parallel=>
              [{:kind=>:serie,
                :serie=>
                    [{:kind=>:assign_to,
                      :assign_to=>[:@b],
                      :assign_value=>
                          {:kind=>:serie,
                           :serie=>
                               [{:kind=>:neuma,
                                 :neuma=>{:abs_grade=>1, :abs_duration=>2, :abs_velocity=>-1}},
                                {:kind=>:neuma, :neuma=>{:abs_grade=>2}},
                                {:kind=>:neuma, :neuma=>{:abs_grade=>1}},
                                {:kind=>:neuma, :neuma=>{:abs_grade=>2}}]}},
                     {:kind=>:use_variable, :use_variable=>:@b}]},
               {:kind=>:serie,
                :serie=>
                    [{:kind=>:neuma, :neuma=>{:abs_grade=>:silence, :abs_duration=>4}},
                     {:kind=>:call_methods,
                      :call_methods=>
                          [{:method=>:reverse,
                            :value_parameters=>[{:kind=>:value, :value=>199}]},
                           {:method=>:other_operation,
                            :value_parameters=>[{:kind=>:use_variable, :use_variable=>:@xxx}]},
                           {:method=>:another_more,
                            :value_parameters=>
                                [{:kind=>:value, :value=>"esto es un texto string"}]}],
                      :on=>{:kind=>:use_variable, :use_variable=>:@b}},
                     {:kind=>:call_methods,
                      :call_methods=>[{:method=>:inverse}],
                      :on=>{:kind=>:use_variable, :use_variable=>:@b}}]}]},
         {:kind=>:event,
          :event=>:event_with_key_parameters,
          :key_parameters=>
              {:a=>{:kind=>:value, :value=>100.25},
               :b=>{:kind=>:value, :value=>200},
               :c=>
                   {:kind=>:serie,
                    :serie=>
                        [{:kind=>:neuma,
                          :neuma=>{:abs_grade=>1, :abs_duration=>2, :abs_velocity=>2}},
                         {:kind=>:neuma,
                          :neuma=>{:abs_grade=>3, :abs_duration=>2, :abs_velocity=>-1}}]}}},
         {:kind=>:event,
          :event=>:event_with_value_and_key_parameters,
          :value_parameters=>
              [{:kind=>:value, :value=>1100},
               {:kind=>:value, :value=>250},
               {:kind=>:value, :value=>"texto"},
               {:kind=>:value, :value=>:simbolo}],
          :key_parameters=>
              {:a=>{:kind=>:value, :value=>100},
               :b=>{:kind=>:value, :value=>200},
               :c=>
                   {:kind=>:serie,
                    :serie=>
                        [{:kind=>:neuma,
                          :neuma=>{:abs_grade=>1, :abs_duration=>2, :abs_velocity=>2}},
                         {:kind=>:neuma,
                          :neuma=>{:abs_grade=>3, :abs_duration=>2, :abs_velocity=>-1}}]}}},
         {:kind=>:call_methods,
          :call_methods=>
              [{:method=>:haz_algo,
                :value_parameters=>
                    [{:kind=>:value, :value=>1100},
                     {:kind=>:value, :value=>250},
                     {:kind=>:value, :value=>"texto"},
                     {:kind=>:value, :value=>:simbolo}],
                :key_parameters=>
                    {:a=>{:kind=>:value, :value=>100},
                     :b=>{:kind=>:value, :value=>200},
                     :c=>
                         {:kind=>:serie,
                          :serie=>
                              [{:kind=>:neuma,
                                :neuma=>{:abs_grade=>1, :abs_duration=>2, :abs_velocity=>2}},
                               {:kind=>:neuma,
                                :neuma=>{:abs_grade=>3, :abs_duration=>2, :abs_velocity=>-1}}]}}}],
          :on=>{:kind=>:use_variable, :use_variable=>:@b}}])

    end
  end
end
