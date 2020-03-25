require 'spec_helper'

require 'musa-dsl'

include Musa::Neumalang
include Musa::Scales
include Musa::Neumas

RSpec.describe Musa::Neumalang do

  context "Neumalang dotted neuma parsing" do

    it "Neuma: '2'" do
      a = Neumalang.parse('2').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2 } }]
    end

    it "Neuma: '2.1'" do
      a = Neumalang.parse('2.1').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 1 } }]
    end

    it "Neuma: '2.1/5'" do
      a = Neumalang.parse('2.1/5').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 1/5r } }]
    end

    it "Neuma: '2.1/5·'" do
      a = Neumalang.parse('2.1/5·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 1/5r + 1/10r } }]
    end

    it "Neuma: '2./'" do
      a = Neumalang.parse('2./').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 1/2r } }]
    end

    it "Neuma: '2./·'" do
      a = Neumalang.parse('2./·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_duration: 3/4r } }]
    end

    it "Neuma: '2.o3./·'" do
      a = Neumalang.parse('2.o3./·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_octave: 3, abs_duration: 3/4r } }]
    end

    it "Neuma: '2.o-3./·'" do
      a = Neumalang.parse('2.o-3./·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_octave: -3, abs_duration: 3/4r } }]
    end

    it "Neuma: '2.+o3./·'" do
      a = Neumalang.parse('2.+o3./·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, delta_octave: 3, abs_duration: 3/4r } }]
    end

    it "Neuma: '2.-o3./·'" do
      a = Neumalang.parse('2.-o3./·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, delta_octave: -3, abs_duration: 3/4r } }]
    end

    it "Neuma: '2#'" do
      a = Neumalang.parse('2#').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_sharps: 1 } }]
    end

    it "Neuma: '2#.1'" do
      a = Neumalang.parse('2#.1').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 2, abs_sharps: 1, abs_duration: 1 } }]
    end

    it "Neuma: 'III#.1'" do
      a = Neumalang.parse('III#.1').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: :III, abs_sharps: 1, abs_duration: 1 } }]
    end

    it "Neuma: 'III#.o5'" do
      a = Neumalang.parse('III#.o5').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: :III, abs_sharps: 1, abs_octave: 5 } }]
    end

    it "Neuma: '1.ppp'" do
      a = Neumalang.parse('1.ppp').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_velocity: -3 } }]
    end

    it "Neuma: '1.o5.1.ppp'" do
      a = Neumalang.parse('1.o5.1.ppp').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: -3 } }]
    end

    it "Neuma: '1.o5.1.mp'" do
      a = Neumalang.parse('1.o5.1.mp').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: 0 } }]
    end

    it "Neuma: '1.o5.1.mf'" do
      a = Neumalang.parse('1.o5.1.mf').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: 1 } }]
    end

    it "Neuma: '1.o5.1.ff'" do
      a = Neumalang.parse('1.o5.1.ff').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: 3 } }]
    end

    it "Neuma: 'III#.o5.1.ppp'" do
      a = Neumalang.parse('III#.o5.1.ppp').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: :III, abs_sharps: 1, abs_octave: 5, abs_duration: 1, abs_velocity: -3 } }]
    end

    it "Neuma: '1.tr" do
      a = Neumalang.parse('1.tr').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, modifiers: { tr: true } } }]
    end

    it "Neuma: '1.gl(100)" do
      a = Neumalang.parse('1.gl(100)').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, modifiers: { gl: 100 } } }]
    end

    it "Neuma: '1.gl(abc)" do
      a = Neumalang.parse('1.gl(abc)').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, modifiers: { gl: :abc } } }]
    end

    it "Neuma: '1.gl(100, \"cosa\")" do
      a = Neumalang.parse('1.gl(100, "cosa")').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '1.o4.2.ff.gl(100, \"cosa\")" do
      a = Neumalang.parse('1.o4.2.ff.gl(100, "cosa")').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '1.o4.2.ff.gl(100, \"cosa\").tr.xf(55)" do
      a = Neumalang.parse('1.o4.2.ff.gl(100, "cosa").tr.xf(55)').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_grade: 1, abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"], tr: true, xf: 55 } } }]
    end

    it "Neuma: '+2.-o3.-/.-ff'" do
      a = Neumalang.parse('+2.-o3.-/.-ff').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: -2 } }]
    end

    it "Neuma: '+2.-o3.-/.+f'" do
      a = Neumalang.parse('+2.-o3.-/.+f').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: 1 } }]
    end

    it "Neuma: '+2.-o3.-/.+p'" do
      a = Neumalang.parse('+2.-o3.-/.+p').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: -1 } }]
    end

    it "Neuma: '+2.-o3./·'" do
      a = Neumalang.parse('+2.-o3./·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, abs_duration: 3/4r } }]
    end

    it "Neuma: '+2.-o3.*1/7'" do
      a = Neumalang.parse('+2.-o3.*1/7').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, factor_duration: 1/7r } }]
    end

    it "Neuma: '+2.-o3./7'" do
      a = Neumalang.parse('+2.-o3./7').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, factor_duration: 1/7r } }]
    end

    it "Neuma: '+2.-o3.+/'" do
      a = Neumalang.parse('+2.-o3.+/').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: 1/2r } }]
    end

    it "Neuma: '+2.-o3.+/·'" do
      a = Neumalang.parse('+2.-o3.+/·').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: 3/4r } }]
    end

    it "Neuma: '+2.-o3.-/'" do
      a = Neumalang.parse('+2.-o3.-/').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r } }]
    end

    it "Neuma: '+2.-o3.-/.-ff'" do
      a = Neumalang.parse('+2.-o3.-/.-ff').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: -2 } }]
    end

    it "Neuma: '.o4'" do
      a = Neumalang.parse('.o4').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_octave: 4 } }]
    end

    it "Neuma: '.1'" do
      a = Neumalang.parse('.1').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_duration: 1 } }]
    end

    it "Neuma: './/'" do
      a = Neumalang.parse('.//').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_duration: 1/4r } }]
    end

    it "Neuma: '.fff'" do
      a = Neumalang.parse('.fff').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_velocity: 4 } }]
    end

    it "Neuma: '.+f'" do
      a = Neumalang.parse('.+f').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_velocity: 1 } }]
    end

    it "Neuma: '.-ff'" do
      a = Neumalang.parse('.-ff').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_velocity: -2 } }]
    end

    it "Neuma: '.o4.//.fff'" do
      a = Neumalang.parse('.o4.//.fff').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_octave: 4, abs_duration: 1/4r, abs_velocity: 4 } }]
    end

    it "Neuma: '.o4.//.+pp'" do
      a = Neumalang.parse('.o4.//.+pp').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_octave: 4, abs_duration: 1/4r, delta_velocity: -2 } }]
    end

    it "Neuma: '." do
      a = Neumalang.parse('.').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: {} }]
    end

    it "Neuma: '.tr" do
      a = Neumalang.parse('.tr').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { modifiers: { tr: true } } }]
    end

    it "Neuma: '.gl(100)" do
      a = Neumalang.parse('.gl(100)').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { modifiers: { gl: 100 } } }]
    end

    it "Neuma: '.gl(100, \"cosa\")" do
      a = Neumalang.parse('.gl(100, "cosa")').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '.o4.2.ff.gl(100, \"cosa\")" do
      a = Neumalang.parse('.o4.2.ff.gl(100, "cosa")').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '.o4.2.ff.gl(100, \"cosa\").tr.xf(55)" do
      a = Neumalang.parse('.o4.2.ff.gl(100, "cosa").tr.xf(55)').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"], tr: true, xf: 55 } } }]
    end

    it "Neuma: '+3#.1'" do
      a = Neumalang.parse('+3#.1').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_grade: 3, delta_sharps: 1, abs_duration: 1 } }]
    end

    it "Neuma: '-#'" do
      a = Neumalang.parse('-#').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_sharps: -1 } }]
    end

    it "Neuma: '#'" do
      a = Neumalang.parse('#').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_sharps: 1 } }]
    end

    it "Neuma: '_'" do
      a = Neumalang.parse('_').to_a(recursive: true)
      expect(a).to eq [{ kind: :neuma, neuma: { delta_sharps: -1 } }]
    end

    it "Bad formatted neumas: '2.3.4'" do
      expect {
        Neumalang.parse('2.3.4')
      }.to raise_error(Citrus::ParseError)
    end

    it "Neuma: '+2.-o3.+·'" do
      expect {
        Neumalang.parse('+2.-o3.+·')
      }.to raise_error(Citrus::ParseError)
    end

  end
end
