require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Datasets Inline Documentation Examples' do
  include Musa::All

  context 'Dataset base (dataset.rb)' do
    it 'example from line 43 - Basic PackedV to V conversion' do
      pv = { a: 1, b: 2, c: 3 }.extend(Musa::Datasets::PackedV)

      v = pv.to_V([:c, :b, :a])

      expect(v).to eq([3, 2, 1])
    end

    it 'example from line 49 - Point series structure' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      expect(p[0]).to eq(60)     # First pitch
      expect(p[1]).to eq(4)      # First duration
      expect(p[2]).to eq(64)     # Second pitch
      expect(p[3]).to eq(8)      # Second duration
      expect(p[4]).to eq(67)     # Third pitch
    end

    it 'example from line 54 - Convert P to timed series' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      timed = p.to_timed_serie(base_duration: 1/4r, time_start: 0r).instance

      event1 = timed.next_value
      expect(event1[:time]).to eq(0r)
      expect(event1[:value]).to eq(60)

      event2 = timed.next_value
      expect(event2[:time]).to eq(1r)  # 4 * 1/4r
      expect(event2[:value]).to eq(64)

      event3 = timed.next_value
      expect(event3[:time]).to eq(3r)  # 1r + 8 * 1/4r
      expect(event3[:value]).to eq(67)
    end

    it 'example from line 66 - MIDI-style PDV' do
      pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
      pdv.base_duration = 1/4r

      expect(pdv[:pitch]).to eq(60)
      expect(pdv[:duration]).to eq(1.0)
      expect(pdv[:velocity]).to eq(64)

      # Convert to score notation using scale
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      gdv = pdv.to_gdv(scale)

      expect(gdv).to be_a(Musa::Datasets::GDV)
      expect(gdv[:grade]).to eq(0)
    end

    it 'example from line 74 - Score-style GDV' do
      gdv = { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:duration]).to eq(1.0)
      expect(gdv[:velocity]).to eq(0)

      # Convert to MIDI using scale
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      pdv = gdv.to_pdv(scale)

      expect(pdv).to be_a(Musa::Datasets::PDV)
      expect(pdv[:pitch]).to eq(60)
    end

    it 'example from line 82 - Delta encoding for compression' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      gdv1 = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv1.base_duration = 1/4r
      gdv2 = { grade: 2, octave: 0, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv2.base_duration = 1/4r

      gdvd = gdv2.to_gdvd(scale, previous: gdv1)

      expect(gdvd[:delta_grade]).to eq(2)
      expect(gdvd[:delta_velocity]).to eq(1)
      # Duration unchanged, so omitted
      expect(gdvd).not_to have_key(:delta_duration)
    end

    it 'example from line 90 - Score container' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(1r, add: { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV))

      expect(score.size).to eq(2)
      expect(score.at(0r).size).to eq(1)
      expect(score.at(1r).size).to eq(1)
    end
  end

  context 'Event types (e.rb)' do
    it 'example from line 22 - Basic validation' do
      event = { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::E)

      expect(event.valid?).to be true
      expect { event.validate! }.not_to raise_error
    end

    it 'example from line 84 - Delta vs Absolute encoding' do
      # Absolute encoding (3 events)
      abs1 = { pitch: 60, duration: 1.0 }
      abs2 = { pitch: 62, duration: 1.0 }
      abs3 = { pitch: 64, duration: 1.0 }

      expect(abs1[:pitch]).to eq(60)
      expect(abs2[:pitch]).to eq(62)
      expect(abs3[:pitch]).to eq(64)

      # Delta encoding conceptually would be:
      # { abs_pitch: 60, abs_duration: 1.0 }  # First event absolute
      # { delta_pitch: +2 }                    # Duration unchanged
      # { delta_pitch: +2 }                    # Duration unchanged
    end

    it 'example from line 122 - AbsTimed event' do
      event1 = { time: 0.0, value: { pitch: 60 } }.extend(Musa::Datasets::AbsTimed)
      event2 = { time: 1.0, value: { pitch: 64 } }.extend(Musa::Datasets::AbsTimed)

      expect(event1[:time]).to eq(0.0)
      expect(event1[:value][:pitch]).to eq(60)
      expect(event2[:time]).to eq(1.0)
      expect(event2[:value][:pitch]).to eq(64)
    end

    it 'example from line 169 - Basic duration' do
      event = { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::AbsD)

      expect(event.duration).to eq(1.0)
      expect(event.note_duration).to eq(1.0)      # Defaults to duration
      expect(event.forward_duration).to eq(1.0)   # Defaults to duration
    end

    it 'example from line 175 - Staccato note' do
      event = { pitch: 60, duration: 1.0, note_duration: 0.5 }.extend(Musa::Datasets::AbsD)

      expect(event.duration).to eq(1.0)
      expect(event.note_duration).to eq(0.5)
      # Note sounds for 0.5, but next event waits 1.0
    end

    it 'example from line 179 - Simultaneous events' do
      event = { pitch: 60, duration: 1.0, forward_duration: 0 }.extend(Musa::Datasets::AbsD)

      expect(event.forward_duration).to eq(0)
      # Next event starts immediately (chord)
    end

    it 'example from line 237 - AbsD compatibility check' do
      expect(Musa::Datasets::AbsD.is_compatible?({ duration: 1.0 })).to be true
      expect(Musa::Datasets::AbsD.is_compatible?({ pitch: 60 })).to be false
    end

    it 'example from line 250 - Convert to AbsD' do
      result = Musa::Datasets::AbsD.to_AbsD({ duration: 1.0 })

      expect(result).to be_a(Musa::Datasets::AbsD)
      expect(result[:duration]).to eq(1.0)
    end
  end

  context 'PDV (pdv.rb)' do
    it 'example from line 65 - Basic MIDI event' do
      pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
      pdv.base_duration = 1/4r

      expect(pdv[:pitch]).to eq(60)
      expect(pdv[:duration]).to eq(1.0)
      expect(pdv[:velocity]).to eq(64)
      # C4 (middle C) for 1 beat at mf dynamics
    end

    it 'example from line 70 - Silence (rest)' do
      pdv = { pitch: :silence, duration: 1.0 }.extend(Musa::Datasets::PDV)

      expect(pdv[:pitch]).to eq(:silence)
      expect(pdv[:duration]).to eq(1.0)
      # Rest for 1 beat
    end

    it 'example from line 74 - With articulation' do
      pdv = {
        pitch: 64,
        duration: 1.0,
        note_duration: 0.5,  # Staccato
        velocity: 80
      }.extend(Musa::Datasets::PDV)

      expect(pdv[:pitch]).to eq(64)
      expect(pdv[:note_duration]).to eq(0.5)
      expect(pdv[:velocity]).to eq(80)
    end

    it 'example from line 82 - Convert to score notation' do
      pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
      pdv.base_duration = 1/4r
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = pdv.to_gdv(scale)

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:duration]).to eq(1.0)
      expect(gdv[:velocity]).to eq(0)
    end

    it 'example from line 89 - Chromatic pitch' do
      pdv = { pitch: 61, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = pdv.to_gdv(scale)

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:sharps]).to eq(1)
      expect(gdv[:duration]).to eq(1.0)
      expect(gdv[:velocity]).to eq(0)
      # C# represented as C (grade 0) + 1 sharp
    end

    it 'example from line 96 - Preserve additional keys' do
      pdv = {
        pitch: 60,
        duration: 1.0,
        velocity: 64,
        custom_key: :value
      }.extend(Musa::Datasets::PDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = pdv.to_gdv(scale)

      expect(gdv[:custom_key]).to eq(:value)
      # custom_key copied to GDV (not a natural key)
    end

    it 'example from line 135 - Basic conversion' do
      pdv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = pdv.to_gdv(scale)

      expect(gdv).to be_a(Musa::Datasets::GDV)
    end

    it 'example from line 140 - Chromatic note' do
      pdv = { pitch: 61, duration: 1.0 }.extend(Musa::Datasets::PDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = pdv.to_gdv(scale)

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:sharps]).to eq(1)
      expect(gdv[:duration]).to eq(1.0)
    end

    it 'example from line 146 - Silence' do
      pdv = { pitch: :silence, duration: 1.0 }.extend(Musa::Datasets::PDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = pdv.to_gdv(scale)

      expect(gdv[:grade]).to eq(:silence)
      expect(gdv[:duration]).to eq(1.0)
    end
  end

  context 'GDV (gdv.rb)' do
    it 'example from line 101 - Basic score event' do
      gdv = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:duration]).to eq(1.0)
      expect(gdv[:velocity]).to eq(0)
      # First scale degree, base octave, 1 beat, mp dynamics
    end

    it 'example from line 106 - Chromatic alteration' do
      gdv = { grade: 0, octave: 0, sharps: 1, duration: 1.0 }.extend(Musa::Datasets::GDV)

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:sharps]).to eq(1)
      # First scale degree sharp (C# in C major)
    end

    it 'example from line 110 - Silence (rest)' do
      gdv = { grade: :silence, duration: 1.0 }.extend(Musa::Datasets::GDV)

      expect(gdv[:grade]).to eq(:silence)
      expect(gdv[:duration]).to eq(1.0)
      # Rest for 1 beat
    end

    it 'example from line 114 - Convert to MIDI' do
      gdv = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      pdv = gdv.to_pdv(scale)

      expect(pdv[:pitch]).to eq(60)
      expect(pdv[:duration]).to eq(1.0)
      expect(pdv[:velocity]).to eq(64)
    end

    it 'example from line 120 - Convert to delta encoding' do
      gdv1 = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv1.base_duration = 1/4r
      gdv2 = { grade: 2, octave: 0, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv2.base_duration = 1/4r
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdvd = gdv2.to_gdvd(scale, previous: gdv1)

      expect(gdvd[:delta_grade]).to eq(2)
      expect(gdvd[:delta_velocity]).to eq(1)
    end

    it 'example from line 127 - Convert to Neuma notation' do
      gdv = { grade: 0, octave: 1, duration: 1r, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(0 o1 4 mf)")
    end

    it 'example from line 174 - Basic conversion' do
      gdv = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      pdv = gdv.to_pdv(scale)

      expect(pdv[:pitch]).to eq(60)
      expect(pdv[:duration]).to eq(1.0)
      expect(pdv[:velocity]).to eq(64)
    end

    it 'example from line 180 - Chromatic note' do
      gdv = { grade: 0, octave: 0, sharps: 1, duration: 1.0 }.extend(Musa::Datasets::GDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      pdv = gdv.to_pdv(scale)

      expect(pdv[:pitch]).to eq(61)
      expect(pdv[:duration]).to eq(1.0)
    end

    it 'example from line 186 - Silence' do
      gdv = { grade: :silence, silence: true, duration: 1.0 }.extend(Musa::Datasets::GDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      pdv = gdv.to_pdv(scale)

      expect(pdv[:pitch]).to eq(:silence)
      expect(pdv[:duration]).to eq(1.0)
    end

    it 'example from line 192 - Dynamics interpolation' do
      gdv = { grade: 0, velocity: 0.5 }.extend(Musa::Datasets::GDV)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      pdv = gdv.to_pdv(scale)

      # velocity 0.5 interpolates between mp (64) and mf (80)
      expect(pdv[:velocity]).to be_between(64, 80)
    end

    it 'example from line 257 - Basic note' do
      gdv = { grade: 0, duration: 1r, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(0 4 mf)")
      # grade 0, duration 4 quarters, mf dynamics
    end

    it 'example from line 263 - With octave' do
      gdv = { grade: 2, octave: 1, duration: 1/2r, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(2 o1 2 mf)")
    end

    it 'example from line 268 - Sharp note' do
      gdv = { grade: 0, sharps: 1, duration: 1r }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(0# 4)")
    end

    it 'example from line 273 - Flat note' do
      gdv = { grade: 1, sharps: -1, duration: 1r }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(1_ 4)")
    end

    it 'example from line 278 - Silence' do
      gdv = { silence: true, duration: 1r }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(silence 4)")
    end

    it 'example from line 283 - With modifiers' do
      gdv = { grade: 0, duration: 1r, staccato: true }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(0 4 staccato)")
    end

    it 'example from line 327 - Velocity to dynamics conversion' do
      gdv = { grade: 0 }.extend(Musa::Datasets::GDV)

      expect(gdv.send(:velocity_of, -3)).to eq("ppp")
      expect(gdv.send(:velocity_of, 0)).to eq("mp")
      expect(gdv.send(:velocity_of, 1)).to eq("mf")
      expect(gdv.send(:velocity_of, 4)).to eq("fff")
    end

    it 'example from line 358 - First event (no previous)' do
      gdv = { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdvd = gdv.to_gdvd(scale)

      expect(gdvd[:abs_grade]).to eq(0)
      expect(gdvd[:abs_duration]).to eq(1.0)
      expect(gdvd[:abs_velocity]).to eq(0)
    end

    it 'example from line 364 - Changed values' do
      gdv1 = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv1.base_duration = 1/4r
      gdv2 = { grade: 2, octave: 0, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv2.base_duration = 1/4r
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdvd = gdv2.to_gdvd(scale, previous: gdv1)

      expect(gdvd[:delta_grade]).to eq(2)
      expect(gdvd[:delta_velocity]).to eq(1)
      # duration unchanged, so omitted
      expect(gdvd).not_to have_key(:delta_duration)
    end

    it 'example from line 370 - Unchanged values' do
      gdv1 = { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv1.base_duration = 1/4r
      gdv2 = { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv2.base_duration = 1/4r
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdvd = gdv2.to_gdvd(scale, previous: gdv1)

      # Everything unchanged
      expect(gdvd.keys & Musa::Datasets::GDVd::NaturalKeys).to be_empty
    end

    it 'example from line 377 - Chromatic alteration' do
      gdv1 = { grade: 0, octave: 0 }.extend(Musa::Datasets::GDV)
      gdv1.base_duration = 1/4r
      gdv2 = { grade: 0, octave: 0, sharps: 1 }.extend(Musa::Datasets::GDV)
      gdv2.base_duration = 1/4r
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdvd = gdv2.to_gdvd(scale, previous: gdv1)

      expect(gdvd[:delta_sharps]).to eq(1)
    end
  end

  context 'GDVd (gdvd.rb)' do
    it 'example from line 79 - First event (absolute encoding)' do
      gdvd = { abs_grade: 0, abs_duration: 1/4r, abs_velocity: 0 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(0 1/4 mp)")
    end

    it 'example from line 84 - Delta encoding (unchanged duration)' do
      gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(+2 +f)")
      # Grade +2 semitones, velocity +1 (one f louder)
    end

    it 'example from line 90 - Chromatic change' do
      gdvd = { delta_sharps: 1 }.extend(Musa::Datasets::GDVd)

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(+#)")
      # Add one sharp
    end

    it 'example from line 95 - Duration multiplication' do
      gdvd = { factor_duration: 2 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(. *2)")
      # Double duration
    end

    it 'example from line 101 - Reconstruction from delta' do
      previous = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(Musa::Datasets::GDVd)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = gdvd.to_gdv(scale, previous: previous)

      expect(gdv[:grade]).to eq(2)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:duration]).to eq(1.0)
      expect(gdv[:velocity]).to eq(1)
    end

    it 'example from line 108 - Octave change' do
      gdvd = { delta_grade: -2, delta_octave: 1 }.extend(Musa::Datasets::GDVd)

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(-2 +o1)")
      # Down 2 semitones, up one octave
    end

    it 'example from line 144 - Base duration adjustment' do
      gdvd = {}.extend(Musa::Datasets::GDVd)
      gdvd[:abs_duration] = 1.0
      gdvd.base_duration = 1/4r

      # abs_duration scaled by factor
      expect(gdvd[:abs_duration]).to be_a(Numeric)
    end

    it 'example from line 166 - Basic delta reconstruction' do
      previous = { grade: 0, octave: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdvd = { delta_grade: 2, delta_velocity: 1 }.extend(Musa::Datasets::GDVd)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = gdvd.to_gdv(scale, previous: previous)

      expect(gdv[:grade]).to eq(2)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:duration]).to eq(1.0)
      expect(gdv[:velocity]).to eq(1)
    end

    it 'example from line 171 - Absolute override' do
      previous = { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV)
      gdvd = { abs_grade: 5, abs_duration: 2.0 }.extend(Musa::Datasets::GDVd)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = gdvd.to_gdv(scale, previous: previous)

      expect(gdv[:grade]).to eq(5)
      expect(gdv[:duration]).to eq(2.0)
    end

    it 'example from line 177 - Duration factor' do
      previous = { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV)
      gdvd = { factor_duration: 2 }.extend(Musa::Datasets::GDVd)
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      gdv = gdvd.to_gdv(scale, previous: previous)

      expect(gdv[:grade]).to eq(0)
      expect(gdv[:duration]).to eq(2.0)
    end

    it 'example from line 299 - Delta grade' do
      gdvd = { delta_grade: 2 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(+2)")
    end

    it 'example from line 304 - Multiple deltas' do
      gdvd = { delta_grade: -2, delta_velocity: 1 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(-2 +f)")
    end

    it 'example from line 309 - Duration factor' do
      gdvd = { factor_duration: 2 }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(. *2)")
    end

    it 'example from line 314 - Chromatic change' do
      gdvd = { delta_sharps: 1 }.extend(Musa::Datasets::GDVd)

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(+#)")
    end

    it 'example from line 318 - Absolute values' do
      gdvd = { abs_grade: 0, abs_duration: 1/4r }.extend(Musa::Datasets::GDVd)
      gdvd.base_duration = 1/4r

      neuma = gdvd.to_neuma

      expect(neuma).to eq("(0 1/4)")
    end
  end

  context 'V (v.rb)' do
    it 'example from line 48 - Basic array to hash conversion' do
      v = [60, 1.0, 64].extend(Musa::Datasets::V)

      pv = v.to_packed_V([:pitch, :duration, :velocity])

      expect(pv[:pitch]).to eq(60)
      expect(pv[:duration]).to eq(1.0)
      expect(pv[:velocity]).to eq(64)
    end

    it 'example from line 53 - With nil mapper (skip position)' do
      v = [3, 2, 1].extend(Musa::Datasets::V)

      pv = v.to_packed_V([:c, nil, :a])

      expect(pv[:c]).to eq(3)
      expect(pv[:a]).to eq(1)
      # Position 1 (value 2) skipped
      expect(pv).not_to have_key(:b)
    end

    it 'example from line 59 - With nil value (skip position)' do
      v = [3, nil, 1].extend(Musa::Datasets::V)

      pv = v.to_packed_V([:c, :b, :a])

      expect(pv[:c]).to eq(3)
      expect(pv[:a]).to eq(1)
      # Position 1 (nil value) skipped
      expect(pv).not_to have_key(:b)
    end

    it 'example from line 65 - Hash mapper with defaults (compression)' do
      v = [3, 2, 1, 400].extend(Musa::Datasets::V)

      pv = v.to_packed_V({ c: 100, b: 200, a: 300, d: 400 })

      expect(pv[:c]).to eq(3)
      expect(pv[:b]).to eq(2)
      expect(pv[:a]).to eq(1)
      # d omitted because value 400 equals default 400
      expect(pv).not_to have_key(:d)
    end

    it 'example from line 71 - Partial mapper (fewer keys than values)' do
      v = [3, 2, 1].extend(Musa::Datasets::V)

      pv = v.to_packed_V([:c, :b])

      expect(pv[:c]).to eq(3)
      expect(pv[:b]).to eq(2)
      # Position 2 (value 1) skipped - no mapper
      expect(pv.size).to eq(2)
    end
  end

  context 'PackedV (packed-v.rb)' do
    it 'example from line 51 - Basic hash to array conversion' do
      pv = { pitch: 60, duration: 1.0, velocity: 64 }.extend(Musa::Datasets::PackedV)

      v = pv.to_V([:pitch, :duration, :velocity])

      expect(v).to eq([60, 1.0, 64])
    end

    it 'example from line 56 - Missing keys become nil (array mapper)' do
      pv = { a: 1, c: 3 }.extend(Musa::Datasets::PackedV)

      v = pv.to_V([:c, :b, :a])

      expect(v).to eq([3, nil, 1])
      # b missing, becomes nil
    end

    it 'example from line 62 - Hash mapper with defaults' do
      pv = { a: 1, b: nil, c: 3 }.extend(Musa::Datasets::PackedV)

      v = pv.to_V({ c: 100, b: 200, a: 300, d: 400 })

      expect(v).to eq([3, 200, 1, 400])
      # b nil -> uses default 200
      # d missing -> uses default 400
    end

    it 'example from line 69 - Partial mapper (fewer keys in mapper)' do
      pv = { a: 1, b: 2, c: 3 }.extend(Musa::Datasets::PackedV)

      v = pv.to_V([:c, :b])

      expect(v).to eq([3, 2])
      # Only c and b extracted
    end

    it 'example from line 75 - Key order matters' do
      pv = { a: 1, b: 2, c: 3 }.extend(Musa::Datasets::PackedV)

      v = pv.to_V([:c, :b, :a])

      expect(v).to eq([3, 2, 1])
    end
  end

  context 'P (p.rb)' do
    it 'example from line 64 - Basic point series (MIDI pitches)' do
      # MIDI pitches with durations in quarter notes
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      expect(p[0]).to eq(60)  # C4
      expect(p[1]).to eq(4)   # for 4 quarters
      expect(p[2]).to eq(64)  # E4
      expect(p[3]).to eq(8)   # for 8 quarters
      expect(p[4]).to eq(67)  # G4
    end

    it 'example from line 68 - Hash points (complex data structures)' do
      p = [
        { pitch: 60, velocity: 64 }, 4,
        { pitch: 64, velocity: 80 }, 8,
        { pitch: 67, velocity: 64 }
      ].extend(Musa::Datasets::P)

      expect(p[0]).to eq({ pitch: 60, velocity: 64 })
      expect(p[1]).to eq(4)
      expect(p[2]).to eq({ pitch: 64, velocity: 80 })
    end

    it 'example from line 75 - Convert to timed serie' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      serie = p.to_timed_serie(base_duration: 1/4r)

      expect(serie).to be_a(Musa::Datasets::P::PtoTimedSerie)
      # base_duration: quarter note = 1/4 beat
    end

    it 'example from line 80 - Start at specific time' do
      p = [60, 4, 64].extend(Musa::Datasets::P)

      serie = p.to_timed_serie(base_duration: 1/4r, time_start: 10r).instance

      event1 = serie.next_value
      expect(event1[:time]).to eq(10r)
      # First event at time 10
    end

    it 'example from line 84 - Start time from component' do
      p = [{ time: 100, pitch: 60 }, 4, { time: 200, pitch: 64 }].extend(Musa::Datasets::P)

      serie = p.to_timed_serie(base_duration: 1/4r, time_start: 0r, time_start_component: :time).instance

      event1 = serie.next_value
      expect(event1[:time]).to eq(100r)
      # First event at time 100 (from first point's :time)
    end

    it 'example from line 89 - Transform points' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      p2 = p.map { |point| point + 12 }

      expect(p2).to eq([72, 4, 76, 8, 79])
      # Transform each point (e.g., transpose pitches up one octave)
    end

    it 'example from line 111 - Create parameter segments' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      serie = p.to_ps_serie(base_duration: 1/4r).instance
      segment1 = serie.next_value

      expect(segment1[:from]).to eq(60)
      expect(segment1[:to]).to eq(64)
      expect(segment1[:duration]).to eq(1.0)
      expect(segment1[:right_open]).to be true
    end

    it 'example from line 142 - Basic timed serie' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      serie = p.to_timed_serie(base_duration: 1/4r).instance

      event1 = serie.next_value
      expect(event1[:time]).to eq(0r)
      expect(event1[:value]).to eq(60)

      event2 = serie.next_value
      expect(event2[:time]).to eq(1.0)
      expect(event2[:value]).to eq(64)

      event3 = serie.next_value
      expect(event3[:time]).to eq(3.0)
      expect(event3[:value]).to eq(67)
    end

    it 'example from line 149 - Custom start time' do
      p = [60, 4, 64].extend(Musa::Datasets::P)

      serie = p.to_timed_serie(base_duration: 1/4r, time_start: 10r).instance

      event1 = serie.next_value
      expect(event1[:time]).to eq(10r)
      # First event at time 10
    end

    it 'example from line 153 - Start time from component' do
      p = [{ time: 100, pitch: 60 }, 4, { pitch: 64 }].extend(Musa::Datasets::P)

      serie = p.to_timed_serie(base_duration: 1/4r, time_start: 0r, time_start_component: :time).instance

      event1 = serie.next_value
      expect(event1[:time]).to eq(100r)
      # First event at time 100
    end

    it 'example from line 176 - Transform points (e.g., transpose pitches)' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      p2 = p.map { |point| point + 12 }

      expect(p2).to eq([72, 4, 76, 8, 79])
    end

    it 'example from line 181 - Transform hash points' do
      p = [{ pitch: 60 }, 4, { pitch: 64 }].extend(Musa::Datasets::P)

      p2 = p.map { |point| point.merge(velocity: 80) }

      expect(p2[0][:velocity]).to eq(80)
      expect(p2[2][:velocity]).to eq(80)
      # Adds velocity to each point
    end
  end

  context 'PS (ps.rb)' do
    it 'example from line 62 - Basic parameter segment (pitch glissando)' do
      ps = { from: 60, to: 72, duration: 2.0 }.extend(Musa::Datasets::PS)

      expect(ps[:from]).to eq(60)
      expect(ps[:to]).to eq(72)
      expect(ps[:duration]).to eq(2.0)
      # Continuous slide from C4 to C5 over 2 beats
    end

    it 'example from line 66 - Parallel interpolation (multidimensional)' do
      ps = {
        from: [60, 64],  # C4 and E4
        to: [72, 76],    # C5 and E5
        duration: 1.0
      }.extend(Musa::Datasets::PS)

      expect(ps[:from]).to eq([60, 64])
      expect(ps[:to]).to eq([72, 76])
      # Both parameters move in parallel
    end

    it 'example from line 74 - Multiple parameters (sonic gesture)' do
      ps = {
        from: { pitch: 60, velocity: 64, pan: -1.0 },
        to: { pitch: 72, velocity: 80, pan: 1.0 },
        duration: 2.0
      }.extend(Musa::Datasets::PS)

      expect(ps[:from]).to eq({ pitch: 60, velocity: 64, pan: -1.0 })
      expect(ps[:to]).to eq({ pitch: 72, velocity: 80, pan: 1.0 })
      # Pitch, velocity, and pan all change smoothly
    end

    it 'example from line 82 - Right open interval' do
      ps1 = { from: 60, to: 64, duration: 1.0, right_open: true }.extend(Musa::Datasets::PS)
      ps2 = { from: 64, to: 67, duration: 1.0, right_open: false }.extend(Musa::Datasets::PS)

      expect(ps1[:right_open]).to be true
      expect(ps2[:right_open]).to be false
      # ps1 stops just before 64, ps2 starts at 64 - no discontinuity
    end

    it 'example from line 87 - Created from P point series' do
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      serie = p.to_ps_serie(base_duration: 1/4r).instance
      ps1 = serie.next_value

      expect(ps1[:from]).to eq(60)
      expect(ps1[:to]).to eq(64)
      expect(ps1[:duration]).to eq(1.0)
      expect(ps1[:right_open]).to be true
    end

    it 'example from line 151 - Valid array segment' do
      ps = { from: [60, 64], to: [72, 76], duration: 1.0 }.extend(Musa::Datasets::PS)

      expect(ps.valid?).to be true
    end

    it 'example from line 155 - Invalid - mismatched array sizes' do
      ps = { from: [60, 64], to: [72], duration: 1.0 }.extend(Musa::Datasets::PS)

      expect(ps.valid?).to be false
    end

    it 'example from line 159 - Invalid - mismatched hash keys' do
      ps = { from: { a: 1 }, to: { b: 2 }, duration: 1.0 }.extend(Musa::Datasets::PS)

      expect(ps.valid?).to be false
    end
  end

  context 'DeltaD (delta-d.rb)' do
    it 'example from line 49 - Different duration encoding modes' do
      previous = { duration: 1.0 }

      # Absolute: set to specific value
      delta1 = { abs_duration: 2.0 }.extend(Musa::Datasets::DeltaD)
      expect(delta1[:abs_duration]).to eq(2.0)
      # Result: duration becomes 2.0

      # Delta: add to previous
      delta2 = { delta_duration: 0.5 }.extend(Musa::Datasets::DeltaD)
      expect(delta2[:delta_duration]).to eq(0.5)
      # Result: duration becomes 1.5 (was 1.0)

      # Factor: multiply previous
      delta3 = { factor_duration: 2 }.extend(Musa::Datasets::DeltaD)
      expect(delta3[:factor_duration]).to eq(2)
      # Result: duration becomes 2.0 (was 1.0)
    end
  end

  context 'Helper (helper.rb)' do
    it 'example from line 24 - positive_sign_of' do
      helper = Object.new.extend(Musa::Datasets::Helper)

      expect(helper.send(:positive_sign_of, 5)).to eq('+')
      expect(helper.send(:positive_sign_of, -3)).to eq('')
    end

    it 'example from line 38 - sign_of' do
      helper = Object.new.extend(Musa::Datasets::Helper)

      expect(helper.send(:sign_of, 5)).to eq('+')
      expect(helper.send(:sign_of, 0)).to eq('+')
      expect(helper.send(:sign_of, -3)).to eq('-')
    end

    it 'example from line 56 - velocity_of' do
      helper = Object.new.extend(Musa::Datasets::Helper)

      expect(helper.send(:velocity_of, -3)).to eq('ppp')
      expect(helper.send(:velocity_of, 1)).to eq('mf')
      expect(helper.send(:velocity_of, 4)).to eq('fff')
    end

    it 'example from line 74 - Boolean modifier (flag)' do
      helper = Object.new.extend(Musa::Datasets::Helper)

      result = helper.send(:modificator_string, :staccato, true)

      expect(result).to eq('staccato')
    end

    it 'example from line 77 - Single parameter' do
      helper = Object.new.extend(Musa::Datasets::Helper)

      result = helper.send(:modificator_string, :pedal, 'down')

      expect(result).to eq('pedal("down")')
    end

    it 'example from line 80 - Multiple parameters' do
      helper = Object.new.extend(Musa::Datasets::Helper)

      result = helper.send(:modificator_string, :bend, [2, 'up'])

      expect(result).to eq('bend(2, "up")')
    end
  end

  context 'Score (score.rb)' do
    it 'example from line 46 - Create empty score' do
      score = Musa::Datasets::Score.new

      expect(score).to be_a(Musa::Datasets::Score)
      expect(score.size).to eq(0)
    end

    it 'example from line 49 - Create from hash' do
      score = Musa::Datasets::Score.new({
        0r => [{ pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV)],
        1r => [{ pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV)]
      })

      expect(score.size).to eq(2)
      expect(score.at(0r).size).to eq(1)
      expect(score.at(1r).size).to eq(1)
    end

    it 'example from line 55 - Add events' do
      score = Musa::Datasets::Score.new
      gdv1 = { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV)
      gdv2 = { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV)

      score.at(0r, add: gdv1)
      score.at(1r, add: gdv2)

      expect(score.size).to eq(2)
    end

    it 'example from line 62 - Query time interval' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.between(0r, 2r)

      expect(events.size).to eq(2)
      # Returns all events starting in [0, 2) or overlapping interval
    end

    it 'example from line 66 - Filter events' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 72, duration: 1.0 }.extend(Musa::Datasets::PDV))

      high_notes = score.subset { |event| event[:pitch] > 60 }

      expect(high_notes.size).to eq(1)
      expect(high_notes.at(1r).first[:pitch]).to eq(72)
    end

    it 'example from line 69 - Get all positions' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))

      positions = score.positions

      expect(positions).to eq([0r, 1r, 2r])
    end

    it 'example from line 72 - Get duration' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 3.0 }.extend(Musa::Datasets::PDV))

      expect(score.duration).to eq(2r)
      # Latest finish time (3r) - 1r
    end

    it 'example from line 99 - Empty score' do
      score = Musa::Datasets::Score.new

      expect(score.size).to eq(0)
    end

    it 'example from line 102 - With initial events' do
      score = Musa::Datasets::Score.new({
        0r => [{ pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV)],
        1r => [{ pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV)]
      })

      expect(score.size).to eq(2)
    end

    it 'example from line 128 - Reset score' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))

      score.reset

      expect(score.size).to eq(0)
    end

    it 'example from line 154 - Finish time' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { duration: 2.0 }.extend(Musa::Datasets::AbsD))

      expect(score.finish).to eq(2r)
    end

    it 'example from line 167 - Duration calculation' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { duration: 2.0 }.extend(Musa::Datasets::AbsD))

      expect(score.duration).to eq(1r)  # finish 2r - 1r
    end

    it 'example from line 187 - Add event' do
      gdv = { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV)
      score = Musa::Datasets::Score.new

      score.at(0r, add: gdv)

      expect(score.at(0r).size).to eq(1)
    end

    it 'example from line 190 - Get time slot' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)

      expect(events).to be_an(Array)
      expect(events.size).to eq(1)
    end

    it 'example from line 193 - Multiple events at same time (chord)' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      expect(score.at(0r).size).to eq(2)
    end

    it 'example from line 221 - Size counting' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))  # Same time
      score.at(1r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))  # Different time

      expect(score.size).to eq(2)  # two time positions
    end

    it 'example from line 234 - Positions sorted' do
      score = Musa::Datasets::Score.new
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))

      expect(score.positions).to eq([0r, 1r])
    end

    it 'example from line 252 - Iterate over time slots' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      positions = []
      counts = []
      score.each do |time, events|
        positions << time
        counts << events.size
      end

      expect(positions).to eq([0r, 1r])
      expect(counts).to eq([1, 1])
    end

    it 'example from line 264 - Convert to hash' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      hash = score.to_h

      expect(hash.keys).to eq([0r, 1r])
      expect(hash[0r]).to be_an(Array)
    end

    it 'example from line 290 - Query bar' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(3r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.between(0r, 4r)

      expect(events.size).to eq(3)
      # Returns all events overlapping [0, 4)
    end

    it 'example from line 294 - Long note spans interval' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { duration: 10.0 }.extend(Musa::Datasets::AbsD))

      events = score.between(2r, 4r)

      expect(events.size).to eq(1)
      # Event included (started before 4, finishes after 2)
      expect(events[0][:start_in_interval]).to eq(2r)
      expect(events[0][:finish_in_interval]).to eq(4r)
    end

    it 'example from line 336 - Get all changes in bar' do
      score = Musa::Datasets::Score.new
      score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      changes = score.changes_between(0r, 4r)

      starts = changes.select { |c| c[:change] == :start }
      finishes = changes.select { |c| c[:change] == :finish }

      expect(starts.size).to eq(2)
      expect(finishes.size).to eq(2)
    end

    it 'example from line 408 - Get all pitches' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))

      pitches = score.values_of(:pitch)

      expect(pitches).to be_a(Set)
      expect(pitches).to include(60, 64, 67)
    end

    it 'example from line 412 - Get all grades' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(1r, add: { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(2r, add: { grade: 4, duration: 1.0 }.extend(Musa::Datasets::GDV))

      grades = score.values_of(:grade)

      expect(grades).to be_a(Set)
      expect(grades).to include(0, 2, 4)
    end

    it 'example from line 434 - Filter by pitch' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 72, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      high_notes = score.subset { |event| event[:pitch] > 60 }

      expect(high_notes.at(1r).size).to eq(1)
      expect(high_notes.at(2r).size).to eq(1)
      expect(high_notes.at(0r)).to be_empty
    end

    it 'example from line 437 - Filter by attribute presence' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0, staccato: true }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      staccato_notes = score.subset { |event| event[:staccato] }

      expect(staccato_notes.size).to eq(1)
    end

    it 'example from line 440 - Filter by grade' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(1r, add: { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(2r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))

      tonic_notes = score.subset { |event| event[:grade] == 0 }

      expect(tonic_notes.size).to eq(2)
    end
  end

  context 'Score::Queriable (score/queriable.rb)' do
    it 'example from line 25 - Group events by pitch' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)
      by_pitch = events.group_by_attribute(:pitch)

      expect(by_pitch[60].size).to eq(2)
      expect(by_pitch[64].size).to eq(1)
    end

    it 'example from line 30 - Select events with attribute' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0, staccato: true }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)
      staccato = events.select_by_attribute(:staccato)

      expect(staccato.size).to eq(1)
      # Returns events where :staccato is not nil
    end

    it 'example from line 34 - Select by value' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)
      forte = events.select_by_attribute(:velocity, 1)

      expect(forte.size).to eq(1)
      # Returns events where velocity == 1
    end

    it 'example from line 46 - Group by grade' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(0r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(0r, add: { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV))

      events = score.at(0r)
      by_grade = events.group_by_attribute(:grade)

      expect(by_grade[0].size).to eq(2)
      expect(by_grade[2].size).to eq(1)
    end

    it 'example from line 63 - Select with attribute present' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0, staccato: true }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)
      result = events.select_by_attribute(:staccato)

      expect(result.size).to eq(1)
      # Events where :staccato is not nil
    end

    it 'example from line 67 - Select by specific value' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)
      result = events.select_by_attribute(:pitch, 60)

      expect(result.size).to eq(1)
      # Events where pitch == 60
    end

    it 'example from line 86 - Sort by pitch' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(0r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      events = score.at(0r)
      sorted = events.sort_by_attribute(:pitch)

      expect(sorted.map { |e| e[:pitch] }).to eq([60, 64, 67])
      # Events sorted by ascending pitch
    end

    it 'example from line 108 - Group by pitch (interval queries)' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      results = score.between(0r, 3r)
      by_pitch = results.group_by_attribute(:pitch)

      expect(by_pitch[60].size).to eq(2)
      # Groups by event[:dataset][:pitch]
    end

    it 'example from line 112 - Select with custom condition' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 72, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      results = score.between(0r, 3r)
      high = results.subset { |event| event[:pitch] > 60 }

      expect(high.size).to eq(2)
    end

    it 'example from line 125 - Group by velocity' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 67, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::PDV))

      results = score.between(0r, 3r)
      by_velocity = results.group_by_attribute(:velocity)

      expect(by_velocity[0].size).to eq(2)
      expect(by_velocity[1].size).to eq(1)
    end

    it 'example from line 140 - Select with attribute' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0, staccato: true }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      results = score.between(0r, 2r)
      filtered = results.select_by_attribute(:staccato)

      expect(filtered.size).to eq(1)
      # Where dataset[:staccato] is not nil
    end

    it 'example from line 145 - Select by value' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(1r, add: { grade: 2, duration: 1.0 }.extend(Musa::Datasets::GDV))
      score.at(2r, add: { grade: 0, duration: 1.0 }.extend(Musa::Datasets::GDV))

      results = score.between(0r, 3r)
      filtered = results.select_by_attribute(:grade, 0)

      expect(filtered.size).to eq(2)
      # Where dataset[:grade] == 0
    end

    it 'example from line 164 - Filter by pitch range' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 72, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      results = score.between(0r, 3r)
      filtered = results.subset { |event| event[:pitch] > 60 && event[:pitch] < 72 }

      expect(filtered.size).to eq(1)
    end

    it 'example from line 167 - Filter by multiple conditions' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { grade: 0, duration: 1.0, velocity: 0 }.extend(Musa::Datasets::GDV))
      score.at(1r, add: { grade: 0, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::GDV))
      score.at(2r, add: { grade: 2, duration: 1.0, velocity: 1 }.extend(Musa::Datasets::GDV))

      results = score.between(0r, 3r)
      filtered = results.subset { |event| event[:grade] == 0 && event[:velocity] > 0 }

      expect(filtered.size).to eq(1)
    end

    it 'example from line 182 - Sort by start time within interval' do
      score = Musa::Datasets::Score.new
      score.at(0r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      results = score.between(0r, 3r)
      sorted = results.sort_by_attribute(:pitch)

      expect(sorted.map { |r| r[:dataset][:pitch] }).to eq([60, 64, 67])
      # Results sorted by ascending pitch
    end
  end

  context 'Score::Render (score/render.rb)' do
    it 'example from line 28 - Basic rendering' do
      score = Musa::Datasets::Score.new
      score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1.0 }.extend(Musa::Datasets::PDV))

      seq = Musa::Sequencer::Sequencer.new(4, 24)

      played = []
      score.render(on: seq) do |event|
        played << { pitch: event[:pitch], position: seq.position }
      end

      seq.run

      expect(played.size).to eq(2)
      expect(played[0][:pitch]).to eq(60)
      expect(played[1][:pitch]).to eq(64)
    end

    it 'example from line 38 - Nested scores' do
      inner = Musa::Datasets::Score.new
      inner.at(1r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))
      inner.at(2r, add: { pitch: 69, duration: 1.0 }.extend(Musa::Datasets::PDV))

      outer = Musa::Datasets::Score.new
      outer.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      outer.at(2r, add: inner)  # Nested score

      seq = Musa::Sequencer::Sequencer.new(4, 24)

      played = []
      outer.render(on: seq) do |event|
        played << event[:pitch]
      end

      seq.run

      expect(played).to include(60, 67, 69)
      # inner plays at sequencer time 2r
    end

    it 'example from line 89 - Console output' do
      score = Musa::Datasets::Score.new
      score.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))

      seq = Musa::Sequencer::Sequencer.new(4, 24)

      output = []
      score.render(on: seq) do |event|
        output << "Time #{seq.position}: #{event[:pitch]}"
      end

      seq.run

      expect(output.first).to match(/Time .+: 60/)
    end

    it 'example from line 99 - Nested score rendering' do
      inner = Musa::Datasets::Score.new
      inner.at(1r, add: { pitch: 67, duration: 1.0 }.extend(Musa::Datasets::PDV))

      outer = Musa::Datasets::Score.new
      outer.at(1r, add: { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::PDV))
      outer.at(2r, add: inner)

      seq = Musa::Sequencer::Sequencer.new(4, 24)

      events = []
      outer.render(on: seq) do |event|
        events << event[:pitch]
      end

      seq.run

      expect(events).to include(60, 67)
      # Inner scores automatically rendered at their scheduled times
    end
  end
end
