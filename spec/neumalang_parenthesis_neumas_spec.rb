require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Neumalang do
  context "Neumalang dotted neuma between parenthesis parsing" do

    it "Neuma: '(2)'" do
      a = Musa::Neumalang::Neumalang.parse('(2)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2 } }]
    end

    it "Neuma: '(2 1)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 1)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 1 } }]
    end

    it "Neuma: '(2 1/5)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 1/5)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 1/5r } }]
    end

    it "Neuma: '(2 1/5·)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 1/5·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 1/5r + 1/10r } }]
    end

    it "Neuma: '(2 /)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 /)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 1/2r } }]
    end

    it "Neuma: '(2 /·)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 /·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3/4r } }]
    end

    it "Neuma: '(2 o3 /·)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 o3 /·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_octave: 3, abs_duration: 3/4r } }]
    end

    it "Neuma: '(2 o-3 /·)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 o-3 /·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_octave: -3, abs_duration: 3/4r } }]
    end

    it "Neuma: '(2 +o3 /·)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 +o3 /·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, delta_octave: 3, abs_duration: 3/4r } }]
    end

    it "Neuma: '(2 -o3 /·)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 -o3 /·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, delta_octave: -3, abs_duration: 3/4r } }]
    end

    it "Neuma: '(2#)'" do
      a = Musa::Neumalang::Neumalang.parse('(2#)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_sharps: 1 } }]
    end

    it "Neuma: '(2# 1)'" do
      a = Musa::Neumalang::Neumalang.parse('(2# 1)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_sharps: 1, abs_duration: 1 } }]
    end

    it "Neuma: '(III# 1)'" do
      a = Musa::Neumalang::Neumalang.parse('(III# 1)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: :III, abs_sharps: 1, abs_duration: 1 } }]
    end

    it "Neuma: '(III# o5)'" do
      a = Musa::Neumalang::Neumalang.parse('(III# o5)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: :III, abs_sharps: 1, abs_octave: 5 } }]
    end

    it "Neuma: '(1 ppp)'" do
      a = Musa::Neumalang::Neumalang.parse('(1 ppp)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_velocity: -3 } }]
    end

    it "Neuma: '(1 o5 1 ppp)'" do
      a = Musa::Neumalang::Neumalang.parse('(1 o5 1 ppp)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: -3 } }]
    end

    it "Neuma: '(1 o5 1 mp)'" do
      a = Musa::Neumalang::Neumalang.parse('(1 o5 1 mp)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: 0 } }]
    end

    it "Neuma: '(1 o5 1 mf)'" do
      a = Musa::Neumalang::Neumalang.parse('(1 o5 1 mf)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: 1 } }]
    end

    it "Neuma: '(1 o5 1 ff)'" do
      a = Musa::Neumalang::Neumalang.parse('(1 o5 1 ff)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_octave: 5, abs_duration: 1, abs_velocity: 3 } }]
    end

    it "Neuma: '(III# o5 1 ppp)'" do
      a = Musa::Neumalang::Neumalang.parse('(III# o5 1 ppp)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: :III, abs_sharps: 1, abs_octave: 5, abs_duration: 1, abs_velocity: -3 } }]
    end

    it "Neuma: '(1 tr)" do
      a = Musa::Neumalang::Neumalang.parse('(1 tr)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, modifiers: { tr: true } } }]
    end

    it "Neuma: '(1 gl(100))" do
      a = Musa::Neumalang::Neumalang.parse('(1 gl(100))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, modifiers: { gl: 100 } } }]
    end

    it "Neuma: '(1 gl(abc))" do
      a = Musa::Neumalang::Neumalang.parse('(1 gl(abc))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, modifiers: { gl: :abc } } }]
    end

    it "Neuma: '(1 gl(100, \"cosa\"))" do
      a = Musa::Neumalang::Neumalang.parse('(1 gl(100, "cosa"))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '(1 o4 2 ff gl(100, \"cosa\"))" do
      a = Musa::Neumalang::Neumalang.parse('(1 o4 2 ff gl(100, "cosa"))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '(1 o4 2 ff gl(100, \"cosa\") tr xf(55))" do
      a = Musa::Neumalang::Neumalang.parse('(1 o4 2 ff gl(100, "cosa") tr xf(55))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 1, abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"], tr: true, xf: 55 } } }]
    end

    it "Neuma: '(+2 -o3 -/ -ff)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 -/ -ff)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: -2 } }]
    end

    it "Neuma: '(+2 -o3 -/ +f)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 -/ +f)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: 1 } }]
    end

    it "Neuma: '(+2 -o3 -/ +p)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 -/ +p)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: -1 } }]
    end

    it "Neuma: '(+2 -o3 /·)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 /·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, abs_duration: 3/4r } }]
    end

    it "Neuma: '(+2 -o3 *1/7)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 *1/7)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, factor_duration: 1/7r } }]
    end

    it "Neuma: '(+2 -o3 /7)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 /7)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, factor_duration: 1/7r } }]
    end

    it "Neuma: '(+2 -o3 +/)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 +/)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: 1/2r } }]
    end

    it "Neuma: '(+2 -o3 +/·)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 +/·)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: 3/4r } }]
    end

    it "Neuma: '(+2 -o3 -/)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 -/)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r } }]
    end

    it "Neuma: '(+2 -o3 -/ -ff)'" do
      a = Musa::Neumalang::Neumalang.parse('(+2 -o3 -/ -ff)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 2, delta_octave: -3, delta_duration: -1/2r, delta_velocity: -2 } }]
    end

    it "Neuma: '(. o4)'" do
      a = Musa::Neumalang::Neumalang.parse('(. o4)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_octave: 4 } }]
    end

    it "Neuma: '(. 1)'" do
      a = Musa::Neumalang::Neumalang.parse('(. 1)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_duration: 1 } }]
    end

    it "Neuma: '(. //)'" do
      a = Musa::Neumalang::Neumalang.parse('(. //)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_duration: 1/4r } }]
    end

    it "Neuma: '(//)'" do
      a = Musa::Neumalang::Neumalang.parse('(//)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_duration: 1/4r } }]
    end

    it "Neuma: '(. fff)'" do
      a = Musa::Neumalang::Neumalang.parse('(. fff)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_velocity: 4 } }]
    end

    it "Neuma: '(. +f)'" do
      a = Musa::Neumalang::Neumalang.parse('(. +f)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_velocity: 1 } }]
    end

    it "Neuma: '(. -ff)'" do
      a = Musa::Neumalang::Neumalang.parse('(. -ff)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_velocity: -2 } }]
    end

    it "Neuma: '(. o4 // fff)'" do
      a = Musa::Neumalang::Neumalang.parse('(. o4 // fff)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_octave: 4, abs_duration: 1/4r, abs_velocity: 4 } }]
    end

    it "Neuma: '(. o4 // +pp)'" do
      a = Musa::Neumalang::Neumalang.parse('(. o4 // +pp)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_octave: 4, abs_duration: 1/4r, delta_velocity: -2 } }]
    end

    it "Neuma: '(.)'" do
      a = Musa::Neumalang::Neumalang.parse('(.)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: {} }]
    end

    it "Neuma: '()'" do
      a = Musa::Neumalang::Neumalang.parse('()').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: {} }]
    end

    it "Neuma: '(. tr)" do
      a = Musa::Neumalang::Neumalang.parse('(. tr)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { modifiers: { tr: true } } }]
    end

    it "Neuma: '(tr())" do
      a = Musa::Neumalang::Neumalang.parse('(tr())').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { modifiers: { tr: true } } }]
    end

    it "Neuma: '(. gl(100))" do
      a = Musa::Neumalang::Neumalang.parse('(. gl(100))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { modifiers: { gl: 100 } } }]
    end

    it "Neuma: '(. gl(100, \"cosa\"))" do
      a = Musa::Neumalang::Neumalang.parse('(. gl(100, "cosa"))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '(gl(100, \"cosa\"))" do
      a = Musa::Neumalang::Neumalang.parse('(gl(100, "cosa"))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '(. o4 2 ff gl(100, \"cosa\"))" do
      a = Musa::Neumalang::Neumalang.parse('(. o4 2 ff gl(100, "cosa"))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"] } } }]
    end

    it "Neuma: '(. o4 2 ff gl(100, \"cosa\") tr xf(55))" do
      a = Musa::Neumalang::Neumalang.parse('(. o4 2 ff gl(100, "cosa") tr xf(55))').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_octave: 4, abs_duration: 2, abs_velocity: 3, modifiers: { gl: [100, "cosa"], tr: true, xf: 55 } } }]
    end

    it "Neuma: '(+3# 1)'" do
      a = Musa::Neumalang::Neumalang.parse('(+3# 1)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_grade: 3, delta_sharps: 1, abs_duration: 1 } }]
    end

    it "Neuma: '(-#)'" do
      a = Musa::Neumalang::Neumalang.parse('(-#)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_sharps: -1 } }]
    end

    it "Neuma: '(#)'" do
      a = Musa::Neumalang::Neumalang.parse('(#)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_sharps: 1 } }]
    end

    it "Neuma: '(_)'" do
      a = Musa::Neumalang::Neumalang.parse('(_)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { delta_sharps: -1 } }]
    end

    it "Unambiguous parenthesis neuma because has 2 elements: '(2 3)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 3)').to_a(recursive: true)
      expect(a).to eq [{ kind: :gdvd, gdvd: { abs_grade: 2, abs_duration: 3 } }]
    end

    it "Unambiguous vector neuma because has 3 elements: '(2 3 4)'" do
      a = Musa::Neumalang::Neumalang.parse('(2 3 4)').to_a(recursive: true)
      expect(a).to eq [{ kind: :v, v: [2, 3, 4] }]
    end

    it "Neuma with undefined previous duration and incremental duration: '(+2 -o3 +·)'" do
      expect {
        Musa::Neumalang::Neumalang.parse('(+2 -o3 +·)')
      }.to raise_error(Citrus::ParseError)
    end
  end
end
