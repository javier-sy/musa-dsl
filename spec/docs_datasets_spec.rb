require 'docs_helper'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'Datasets Documentation Examples' do

  context 'Datasets - Sonic Data Structures' do
    it 'supports custom parameters in datasets (extensibility)' do
      include Musa::Datasets

      # GDV with standard parameters
      gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(Musa::Datasets::GDV)
      expect(gdv[:grade]).to eq(0)
      expect(gdv[:duration]).to eq(1r)

      # Extended with custom parameters
      gdv_extended = {
        grade: 0,
        duration: 1r,
        velocity: 0,
        articulation: :staccato,
        timbre: :bright,
        reverb_send: 0.3,
        custom_control: 42
      }.extend(Musa::Datasets::GDV)

      expect(gdv_extended[:articulation]).to eq(:staccato)
      expect(gdv_extended[:timbre]).to eq(:bright)
      expect(gdv_extended[:custom_control]).to eq(42)

      # Custom parameters preserved through conversions
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      pdv = gdv_extended.to_pdv(scale)

      expect(pdv[:pitch]).to eq(60)
      expect(pdv[:articulation]).to eq(:staccato)
      expect(pdv[:timbre]).to eq(:bright)
      expect(pdv[:custom_control]).to eq(42)
    end

    it 'validates datasets with valid? and validate!' do
      include Musa::Datasets

      gdv = { grade: 0, duration: 1r, velocity: 0 }.extend(Musa::Datasets::GDV)

      expect(gdv.valid?).to be true
      expect { gdv.validate! }.not_to raise_error

      # Type checking
      expect(gdv.is_a?(Musa::Datasets::GDV)).to be true
      expect(gdv.is_a?(Musa::Datasets::Abs)).to be true
      expect(gdv.is_a?(Musa::Datasets::AbsD)).to be true
    end

    it 'converts GDV to PDV (score to MIDI)' do
      include Musa::Datasets

      scale = Musa::Scales::Scales.et12[440.0].major[60]

      # Score to MIDI
      gdv = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(Musa::Datasets::GDV)
      pdv = gdv.to_pdv(scale)

      expect(pdv[:pitch]).to eq(60)
      expect(pdv[:duration]).to eq(1r)
      expect(pdv[:velocity]).to eq(64)
    end

    it 'converts PDV to GDV (MIDI to score)' do
      include Musa::Datasets

      scale = Musa::Scales::Scales.et12[440.0].major[60]

      # MIDI to Score
      pdv = { pitch: 64, duration: 1r, velocity: 80 }.extend(Musa::Datasets::PDV)
      gdv = pdv.to_gdv(scale)

      expect(gdv[:grade]).to eq(2)
      expect(gdv[:octave]).to eq(0)
      expect(gdv[:duration]).to eq(1r)
      expect(gdv[:velocity]).to eq(1)
    end

    it 'converts GDV to GDVd (absolute to delta encoding)' do
      include Musa::Datasets

      scale = Musa::Scales::Scales.et12[440.0].major[60]

      # First note (absolute)
      gdv1 = { grade: 0, octave: 0, duration: 1r, velocity: 0 }.extend(Musa::Datasets::GDV)
      gdv1.base_duration = 1/4r
      gdvd1 = gdv1.to_gdvd(scale)

      expect(gdvd1[:abs_grade]).to eq(0)
      expect(gdvd1[:abs_duration]).to eq(1r)
      expect(gdvd1[:abs_velocity]).to eq(0)

      # Second note (delta from previous)
      gdv2 = { grade: 2, octave: 0, duration: 1r, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv2.base_duration = 1/4r
      gdvd2 = gdv2.to_gdvd(scale, previous: gdv1)

      expect(gdvd2[:delta_grade]).to eq(2)
      expect(gdvd2[:delta_velocity]).to eq(1)
      # duration unchanged, omitted
      expect(gdvd2).not_to have_key(:delta_duration)
    end

    it 'converts V to PackedV (array to hash)' do
      include Musa::Datasets

      # Array to hash
      v = [60, 1r, 64].extend(Musa::Datasets::V)
      pv = v.to_packed_V([:pitch, :duration, :velocity])

      expect(pv[:pitch]).to eq(60)
      expect(pv[:duration]).to eq(1r)
      expect(pv[:velocity]).to eq(64)
    end

    it 'converts PackedV to V (hash to array)' do
      include Musa::Datasets

      # Hash to array
      pv = { pitch: 60, duration: 1r, velocity: 64 }.extend(Musa::Datasets::PackedV)
      v = pv.to_V([:pitch, :duration, :velocity])

      expect(v).to eq([60, 1r, 64])
    end

    it 'compresses with default values (V to PackedV)' do
      include Musa::Datasets

      # With default values (compression)
      v = [60, 1r, 64].extend(Musa::Datasets::V)
      pv = v.to_packed_V({ pitch: 60, duration: 1r, velocity: 64 })

      # All values match defaults, fully compressed
      expect(pv).to be_empty
    end

    it 'converts P to PS serie (point series to parameter segments)' do
      include Musa::Datasets

      # Point series to parameter segments
      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      ps_serie = p.to_ps_serie(base_duration: 1/4r).instance
      ps1 = ps_serie.next_value

      expect(ps1[:from]).to eq(60)
      expect(ps1[:to]).to eq(64)
      expect(ps1[:duration]).to eq(1r)
      expect(ps1[:right_open]).to be true

      ps2 = ps_serie.next_value
      expect(ps2[:from]).to eq(64)
      expect(ps2[:to]).to eq(67)
      expect(ps2[:duration]).to eq(2r)
      expect(ps2[:right_open]).to be false
    end

    it 'converts P to timed series (point series to timed events)' do
      include Musa::Datasets

      p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)

      timed_serie = p.to_timed_serie(base_duration: 1/4r, time_start: 0).instance

      t1 = timed_serie.next_value
      expect(t1[:time]).to eq(0r)
      expect(t1[:value]).to eq(60)

      t2 = timed_serie.next_value
      expect(t2[:time]).to eq(1r)
      expect(t2[:value]).to eq(64)

      t3 = timed_serie.next_value
      expect(t3[:time]).to eq(3r)
      expect(t3[:value]).to eq(67)
    end

    it 'converts GDV to Neuma notation string' do
      include Musa::Datasets

      gdv = { grade: 0, octave: 1, duration: 1r, velocity: 2 }.extend(Musa::Datasets::GDV)
      gdv.base_duration = 1/4r

      neuma = gdv.to_neuma

      expect(neuma).to eq("(0 o1 4 f)")
    end

    it 'uses datasets with transformations' do
      include Musa::Datasets

      # Create GDV events
      gdv1 = { grade: 0, duration: 1r }.extend(Musa::Datasets::GDV)
      gdv2 = { grade: 2, duration: 1r }.extend(Musa::Datasets::GDV)
      gdv3 = { grade: 4, duration: 1r }.extend(Musa::Datasets::GDV)

      expect(gdv1.is_a?(Musa::Datasets::GDV)).to be true
      expect(gdv1[:grade]).to eq(0)

      # Transform to PDV
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      pdv1 = gdv1.to_pdv(scale)

      expect(pdv1.is_a?(Musa::Datasets::PDV)).to be true
      expect(pdv1[:pitch]).to eq(60)
    end

    it 'creates GDV with to_neuma and validates integration' do
      include Musa::Datasets

      # Create GDV datasets for integration testing
      gdv1 = { grade: 0, duration: 1r, velocity: 1 }.extend(Musa::Datasets::GDV)
      gdv2 = { grade: 2, duration: 1r, velocity: 2 }.extend(Musa::Datasets::GDV)
      gdv3 = { grade: 4, duration: 1r, velocity: 3 }.extend(Musa::Datasets::GDV)

      gdv1.base_duration = 1/4r
      gdv2.base_duration = 1/4r
      gdv3.base_duration = 1/4r

      # Verify datasets work correctly
      expect(gdv1[:grade]).to eq(0)
      expect(gdv1[:velocity]).to eq(1)
      expect(gdv2[:grade]).to eq(2)
      expect(gdv2[:velocity]).to eq(2)
      expect(gdv3[:grade]).to eq(4)
      expect(gdv3[:velocity]).to eq(3)

      # Verify to_neuma conversion
      expect(gdv1.to_neuma).to include('0')
      expect(gdv1.to_neuma).to include('mf')
    end

    it 'parses Neuma strings to GDV datasets' do
      include Musa::All

      # Neuma strings parse to GDV datasets
      scale = Scales.default_system.default_tuning.major[60]
      decoder = Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

      neuma = "(0 4 mf) (2 4 f) (4 4 ff)"
      gdv_serie = Neumalang.parse(neuma, decode_with: decoder)

      gdv_array = gdv_serie.to_a(recursive: true)

      # Verify first GDV: (0 4 mf)
      expect(gdv_array[0][:grade]).to eq(0)
      expect(gdv_array[0][:duration]).to eq(1r)  # 4 quarters = 1 beat
      expect(gdv_array[0][:velocity]).to eq(1)    # mf (mezzo-forte)

      # Verify second GDV: (2 4 f)
      expect(gdv_array[1][:grade]).to eq(2)
      expect(gdv_array[1][:duration]).to eq(1r)
      expect(gdv_array[1][:velocity]).to eq(2)    # f (forte)

      # Verify third GDV: (4 4 ff)
      expect(gdv_array[2][:grade]).to eq(4)
      expect(gdv_array[2][:duration]).to eq(1r)
      expect(gdv_array[2][:velocity]).to eq(3)    # ff (fortissimo)
    end

    it 'integrates datasets with Sequencer' do
      include Musa::All
      include Musa::Datasets

      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Track events for verification
      events = []

      # Use GDV datasets directly in sequencer
      sequencer.at 1 do
        event = { grade: 0, duration: 1r, velocity: 0, articulation: :legato }.extend(Musa::Datasets::GDV)
        events << event
      end

      sequencer.at 2 do
        event = { grade: 2, duration: 1r, velocity: 1, articulation: :staccato }.extend(Musa::Datasets::GDV)
        events << event
      end

      # Execute sequencer
      sequencer.run

      # Verify events were created with custom parameters
      expect(events.size).to eq(2)
      expect(events[0][:grade]).to eq(0)
      expect(events[0][:articulation]).to eq(:legato)
      expect(events[1][:grade]).to eq(2)
      expect(events[1][:articulation]).to eq(:staccato)
    end

    it 'integrates datasets with Series' do
      include Musa::All
      include Musa::Datasets

      # Series of GDV events
      gdv_serie = Musa::Series::Constructors.S(
        { grade: 0, duration: 1r }.extend(Musa::Datasets::GDV),
        { grade: 2, duration: 1r }.extend(Musa::Datasets::GDV),
        { grade: 4, duration: 1r }.extend(Musa::Datasets::GDV)
      )

      # Verify serie contains GDV datasets
      gdv_array = gdv_serie.to_a(recursive: true)
      expect(gdv_array.size).to eq(3)
      expect(gdv_array[0].is_a?(Musa::Datasets::GDV)).to be true
      expect(gdv_array[1].is_a?(Musa::Datasets::GDV)).to be true
      expect(gdv_array[2].is_a?(Musa::Datasets::GDV)).to be true

      # Transform while preserving dataset type
      scale = Scales.et12[440.0].major[60]
      pdv_serie = gdv_serie.map { |gdv| gdv.to_pdv(scale) }

      # Verify transformation
      pdv_array = pdv_serie.to_a(recursive: true)
      expect(pdv_array.size).to eq(3)
      expect(pdv_array[0].is_a?(Musa::Datasets::PDV)).to be true
      expect(pdv_array[0][:pitch]).to eq(60)  # grade 0
      expect(pdv_array[1][:pitch]).to eq(64)  # grade 2
      expect(pdv_array[2][:pitch]).to eq(67)  # grade 4
    end

    it 'integrates datasets with Transcription for MIDI output' do
      include Musa::All
      include Musa::Datasets

      scale = Scales.et12[440.0].major[60]

      # GDV to PDV for MIDI output
      gdv_events = [
        { grade: 0, duration: 1r, velocity: 0 }.extend(Musa::Datasets::GDV),
        { grade: 2, duration: 1r, velocity: 1 }.extend(Musa::Datasets::GDV)
      ]

      midi_events = gdv_events.map { |gdv| gdv.to_pdv(scale) }

      # Verify MIDI events
      expect(midi_events.size).to eq(2)
      expect(midi_events[0].is_a?(Musa::Datasets::PDV)).to be true
      expect(midi_events[1].is_a?(Musa::Datasets::PDV)).to be true

      # Verify pitches
      expect(midi_events[0][:pitch]).to eq(60)  # C4
      expect(midi_events[1][:pitch]).to eq(64)  # E4

      # Verify durations preserved
      expect(midi_events[0][:duration]).to eq(1r)
      expect(midi_events[1][:duration]).to eq(1r)
    end

    it 'integrates datasets with Score Container' do
      include Musa::Datasets

      score = Musa::Datasets::Score.new

      # Add events at specific times
      score.at(1r, add: { grade: 0, duration: 1r }.extend(Musa::Datasets::GDV))
      score.at(2r, add: { grade: 2, duration: 1r }.extend(Musa::Datasets::GDV))
      score.at(3r, add: { grade: 4, duration: 1r }.extend(Musa::Datasets::GDV))

      # Query events at specific time
      events_at_2 = score.at(2r)
      expect(events_at_2).to be_an(Array)
      expect(events_at_2.size).to eq(1)
      expect(events_at_2[0][:grade]).to eq(2)

      # Query events in range [1r, 4r) - includes events at 1r, 2r, and 3r
      # Note: between() uses half-open interval [start, finish)
      events_in_range = score.between(1r, 4r)
      expect(events_in_range).to be_an(Array)
      expect(events_in_range.size).to eq(3)
      expect(events_in_range[0][:dataset][:grade]).to eq(0)
      expect(events_in_range[1][:dataset][:grade]).to eq(2)
      expect(events_in_range[2][:dataset][:grade]).to eq(4)
    end

    it 'queries events with between() for interval overlap' do
      score = Musa::Datasets::Score.new

      # Add events with durations
      score.at(1r, add: { pitch: 60, duration: 2r }.extend(Musa::Datasets::PDV))  # 1-3
      score.at(2r, add: { pitch: 64, duration: 1r }.extend(Musa::Datasets::PDV))  # 2-3
      score.at(3r, add: { pitch: 67, duration: 2r }.extend(Musa::Datasets::PDV))  # 3-5

      # Query events overlapping interval [2, 4)
      events = score.between(2r, 4r)

      expect(events.size).to eq(3)
      expect(events[0][:dataset][:pitch]).to eq(60)
      expect(events[1][:dataset][:pitch]).to eq(64)
      expect(events[2][:dataset][:pitch]).to eq(67)

      # Check effective intervals
      expect(events[0][:start_in_interval]).to eq(2r)
      expect(events[0][:finish_in_interval]).to eq(3r)
    end

    it 'gets timeline changes with changes_between()' do
      score = Musa::Datasets::Score.new

      score.at(1r, add: { pitch: 60, duration: 2r }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1r }.extend(Musa::Datasets::PDV))

      changes = score.changes_between(0r, 4r)

      # Find start and finish changes
      starts = changes.select { |c| c[:change] == :start }
      finishes = changes.select { |c| c[:change] == :finish }

      expect(starts.size).to eq(2)
      expect(finishes.size).to eq(2)

      expect(starts[0][:dataset][:pitch]).to eq(60)
      expect(starts[1][:dataset][:pitch]).to eq(64)
    end

    it 'collects unique attribute values with values_of()' do
      score = Musa::Datasets::Score.new

      score.at(1r, add: { pitch: 60, duration: 1r }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 64, duration: 1r }.extend(Musa::Datasets::PDV))
      score.at(3r, add: { pitch: 67, duration: 1r }.extend(Musa::Datasets::PDV))
      score.at(4r, add: { pitch: 64, duration: 1r }.extend(Musa::Datasets::PDV))  # Repeated

      pitches = score.values_of(:pitch)

      expect(pitches).to be_a(Set)
      expect(pitches).to include(60, 64, 67)
      expect(pitches.size).to eq(3)
    end

    it 'filters events with subset()' do
      score = Musa::Datasets::Score.new

      score.at(1r, add: { pitch: 60, velocity: 80, duration: 1r }.extend(Musa::Datasets::PDV))
      score.at(2r, add: { pitch: 72, velocity: 100, duration: 1r }.extend(Musa::Datasets::PDV))
      score.at(3r, add: { pitch: 64, velocity: 60, duration: 1r }.extend(Musa::Datasets::PDV))

      # Filter by pitch range
      high_notes = score.subset { |event| event[:pitch] >= 70 }

      expect(high_notes.at(2r).size).to eq(1)
      expect(high_notes.at(2r).first[:pitch]).to eq(72)
      expect(high_notes.at(3r)).to be_empty
    end
  end


end
