require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Neumalang do

	context "Neuma simple parsing" do

		it "Basic neuma inline parsing (only a comment)" do
			expect(Musa::Neumalang.parse('/* comentario 1 */')).to eq([])
		end

		it "Basic neuma inline parsing (two comments)" do
			expect(Musa::Neumalang.parse('/* comentario 1 */ /* bla bla */')).to eq([])
		end

		it "Basic neuma inline parsing (two comments with subcomments)" do
			expect(Musa::Neumalang.parse('/* comentario  /* otro comentario */ 1 */ /* bla bla */')).to eq([])
		end

		it "Basic neuma inline parsing (1)" do
			expect(Musa::Neumalang.parse('2.3.4 5.6.7 /* comentario 1 */ ::evento')).to eq(
				[{ kind: :neuma, neuma: ["2", "3", "4"] }, { kind: :neuma, neuma: ["5", "6", "7"] }, { kind: :event, event: :evento }])
		end

		it "Basic neuma inline parsing (2)" do
			expect(Musa::Neumalang.parse('2.3.4 5.6.7 ::evento /* comentario 1 */')).to eq(
				[{ kind: :neuma, neuma: ["2", "3", "4"] }, { kind: :neuma, neuma: ["5", "6", "7"] }, { kind: :event, event: :evento }])
		end

		it "Basic neuma inline parsing with octaves" do
			expect(Musa::Neumalang.parse('2.o-1.3.4 5.o2.6.7 ::evento')).to eq(
				[{ kind: :neuma, neuma: ["2", "o-1", "3", "4"] }, { kind: :neuma, neuma: ["5", "o2", "6", "7"] }, { kind: :event, event: :evento }])
		end

		it "Basic neuma inline parsing with comment" do
			expect(Musa::Neuma.parse("/* comentario (con parentesis) \n*/ 2.3.4")).to eq([{ kind: :neuma, neuma: ["2", "3", "4"] }])
		end	

		it "Basic neuma inline parsing only duration" do

			result = Musa::Neumalang.parse '0 .1/2'

			expect(result[0]).to eq({ kind: :neuma, neuma: ["0"] })
			expect(result[1]).to eq({ kind: :neuma, neuma: [nil, "1/2"] })
		end

		differential_decoder = Musa::Dataset::GDV::NeumaDifferentialDecoder.new 

		it "Basic neuma inline parsing with differential decoder" do

			result = Musa::Neumalang.parse '0 . +1 2.p 2.1/2.p /*comentario 1*/', decode_with: differential_decoder

			expect(result[0]).to eq({ abs_grade: 0 })
			expect(result[1]).to eq({ })
			expect(result[2]).to eq({ delta_grade: 1 })
			expect(result[3]).to eq({ abs_grade: 2, abs_velocity: -1 })
			expect(result[4]).to eq({ abs_grade: 2, abs_duration: Rational(1,2), abs_velocity: -1 })
		end

		it "Basic neuma file parsing with GDV differential decoder" do

			result = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma_spec.neu"), decode_with: differential_decoder

			c = -1

			expect(result[c+=1]).to eq({ })
			expect(result[c+=1]).to eq({ abs_grade: :II })
			expect(result[c+=1]).to eq({ abs_grade: :I, abs_duration: Rational(2) })
			expect(result[c+=1]).to eq({ abs_grade: :I, abs_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ abs_grade: :I, abs_velocity: -1 })
			
			expect(result[c+=1]).to eq({ abs_grade: 0 })
			expect(result[c+=1]).to eq({ abs_grade: 0, abs_duration: Rational(1) })
			expect(result[c+=1]).to eq({ abs_grade: 0, abs_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ abs_grade: 0, abs_velocity: 4 })

			expect(result[c+=1]).to eq({ abs_grade: 0 })
			expect(result[c+=1]).to eq({ abs_grade: 1 })
			expect(result[c+=1]).to eq({ abs_grade: 2, abs_velocity: -1 })
			expect(result[c+=1]).to eq({ abs_grade: 2, abs_duration: Rational(1,2), abs_velocity: 3 })

			expect(result[c+=1][:command].call).to eq(11110)

			expect(result[c+=1]).to eq({ abs_grade: 0 })
			expect(result[c+=1]).to eq({ })
			expect(result[c+=1]).to eq({ delta_grade: 1 })
			expect(result[c+=1]).to eq({ delta_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ factor_duration: Rational(1,2) })
			expect(result[c+=1]).to eq({ abs_velocity: -1 })
			expect(result[c+=1]).to eq({ delta_velocity: 1 })

			expect(result[c+=1]).to eq({ event: :evento })

			expect(result[c+=1]).to eq({ delta_grade: -1 })
		end

		it "Basic neuma file parsing with GDV decoder" do

			scale = Musa::Scales.get :major

			decoder = Musa::Dataset::GDV::NeumaDecoder.new scale, { grade: 0, duration: 1, velocity: 1 }

			result = Musa::Neumalang.parse_file File.join(File.dirname(__FILE__), "neuma_spec.neu"), decode_with: decoder

			c = -1

			expect(result[c+=1]).to eq({ grade: 0, duration: 1, velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 1, duration: 1, velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: 2, velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: -1 })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 4 })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 4 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 4 })
			expect(result[c+=1]).to eq({ grade: 2, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 2, duration: Rational(1,2), velocity: 3 })

			expect(result[c+=1][:command].call).to eq(11110)

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 3 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: -1 })
			expect(result[c+=1]).to eq({ grade: 1, duration: Rational(1,2), velocity: 0 })
			
			expect(result[c+=1]).to eq({ duration: 0, event: :evento })

			expect(result[c+=1]).to eq({ grade: 0, duration: Rational(1,2), velocity: 0 })
		end
	end
end
