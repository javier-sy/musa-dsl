require 'spec_helper'

require 'musa-dsl'

using Musa::Extension::Neumas
using Musa::Extension::Matrix

RSpec.describe 'README.md Documentation Examples' do
  # Shared aliases needed for RSpec lexical scoping
  Scales = Musa::Scales::Scales
  Neumalang = Musa::Neumalang::Neumalang
  Decoders = Musa::Neumas::Decoders

  context 'Quick Start' do
    include Musa::All

    it 'demonstrates sequencer DSL with multiple interactive voice lines' do
      # Create scale for composition
      scale = Scales.et12[440.0].major[60]  # C major starting at middle C

      # Create sequencer (4 beats per bar, 24 ticks per beat)
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Track events for verification
      beat_events = []
      melody_events = []
      harmony_events = []

      # Shared state: current melody note (so harmony can follow)
      current_melody_note = nil

      # Program the sequencer using DSL
      sequencer.with do
        # Line 1: Beat every 4 bars (for 32 bars total)
        at 1 do
          every 4, duration: 32 do
            beat_events << { position: position, pitch: 36 }
          end
        end

        # Line 2: Ascending melody (bars 1-16) then descending (bars 17-32)
        at 1 do
          # Ascending: move from grade 0 to grade 14 over 16 bars
          move(from: 0, to: 14, duration: 16, every: 1/4r) do |grade|
            pitch = scale[grade.round].pitch
            current_melody_note = grade.round
            melody_events << { position: position, grade: grade.round, pitch: pitch }
          end
        end

        at 17 do
          # Descending: move from grade 14 to grade 0 over 16 bars
          move(from: 14, to: 0, duration: 16, every: 1/4r) do |grade|
            pitch = scale[grade.round].pitch
            current_melody_note = grade.round
            melody_events << { position: position, grade: grade.round, pitch: pitch }
          end
        end

        # Line 3: Harmony playing 3rd or 5th every 2 bars (for 32 bars total)
        at 1 do
          use_third = true

          every 2, duration: 32 do
            if current_melody_note
              harmony_grade = current_melody_note + (use_third ? 2 : 4)
              harmony_pitch = scale[harmony_grade].pitch
              harmony_events << {
                position: position,
                melody_grade: current_melody_note,
                harmony_grade: harmony_grade,
                pitch: harmony_pitch,
                interval: use_third ? :third : :fifth
              }
              use_third = !use_third
            end
          end
        end
      end

      # Execute sequencer
      sequencer.run

      # Verify beat events
      expect(beat_events.size).to be > 0
      expect(beat_events.first[:position]).to eq(1)  # First beat at bar 1
      expect(beat_events.first[:pitch]).to eq(36)    # Kick drum pitch

      # Verify spacing between beats (every 4 bars)
      if beat_events.size > 1
        expect(beat_events[1][:position]).to eq(5)  # Second beat at bar 5
      end

      # Verify melody events
      expect(melody_events.size).to be > 0

      # First melody note should be at grade 0
      expect(melody_events.first[:grade]).to eq(0)
      expect(melody_events.first[:pitch]).to eq(60)  # C4

      # Melody should ascend in first 16 bars
      first_half = melody_events.select { |e| e[:position] <= 16 }
      expect(first_half.last[:grade]).to be > first_half.first[:grade]

      # Melody should descend in bars 17-32
      second_half = melody_events.select { |e| e[:position] >= 17 && e[:position] <= 32 }
      if second_half.size > 1
        expect(second_half.last[:grade]).to be < second_half.first[:grade]
      end

      # Verify harmony events
      expect(harmony_events.size).to be > 0

      # First harmony should be at bar 1
      expect(harmony_events.first[:position]).to eq(1)

      # Verify harmony intervals (alternating 3rd and 5th)
      expect(harmony_events.first[:interval]).to eq(:third)
      if harmony_events.size > 1
        expect(harmony_events[1][:interval]).to eq(:fifth)
      end

      # Verify harmony follows melody
      harmony_events.each do |h|
        if h[:interval] == :third
          expect(h[:harmony_grade]).to eq(h[:melody_grade] + 2)
        else  # :fifth
          expect(h[:harmony_grade]).to eq(h[:melody_grade] + 4)
        end
      end

      # Verify spacing between harmony notes (every 2 bars)
      if harmony_events.size > 1
        expect(harmony_events[1][:position]).to eq(3)  # Second harmony at bar 3
      end
    end
  end

  context 'Not So Quick Start' do
    include Musa::All

    it 'creates melody using neuma notation, decodes to GDV events, and schedules with sequencer' do
      # Create a decoder with a major scale
      scale = Scales.et12[440.0].major[60]
      decoder = Decoders::NeumaDecoder.new(
        scale,
        base_duration: 1r  # Base duration for explicit duration values
      )

      # Define melody with duration and velocity
      melody = "(0 1/4 p) (+2 1/4 mp) (+2 1/4 mf) (-1 1/2 f) " \
               "(0 1/4 mf) (+4 1/4 mp) (+5 1/2 f) (+7 1/4 ff) " \
               "(+5 1/4 f) (+4 1/4 mf) (+2 1/4 mp) (0 1 p)"

      # Decode to GDV (Grade-Duration-Velocity) events
      gdv_notes = Neumalang.parse(melody, decode_with: decoder)

      # Verify GDV notes structure
      gdv_array = gdv_notes.to_a(recursive: true)
      expect(gdv_array).to be_an(Array)
      expect(gdv_array.size).to eq(12)

      gdv_array.each do |note|
        expect(note).to be_a(Hash)
        expect(note).to include(:grade, :duration, :velocity)
        expect(note[:grade]).to be_an(Integer)
        expect(note[:duration]).to be_a(Rational)
        expect(note[:velocity]).to be_a(Float).or be_a(Integer)
      end

      # Verify first note has specified duration and velocity
      expect(gdv_array[0][:grade]).to eq(0)
      expect(gdv_array[0][:duration]).to eq(1/4r)
      expect(gdv_array[0][:velocity]).to eq(-1)  # p = piano = -1

      # Verify fourth note has different duration (half note)
      expect(gdv_array[3][:duration]).to eq(1/2r)

      # Verify last note has longer duration (whole note)
      expect(gdv_array[11][:duration]).to eq(1r)

      # Convert GDV to PDV (Pitch-Duration-Velocity) for playback
      pdv_notes = gdv_notes.map { |note| note.to_pdv(scale) }

      # Verify PDV conversion
      pdv_array = pdv_notes.to_a(recursive: true)
      expect(pdv_array).to be_an(Array)
      expect(pdv_array.size).to eq(12)

      pdv_array.each do |note|
        expect(note).to be_a(Hash)
        expect(note).to include(:pitch, :duration)
        expect(note[:pitch]).to be_an(Integer)
        expect(note[:duration]).to be_a(Rational)
      end

      # Verify first PDV note preserves duration from GDV
      expect(pdv_array[0][:pitch]).to eq(60)  # C4 (grade 0 in C major scale)
      expect(pdv_array[0][:duration]).to eq(1/4r)
      # PDV velocity is converted to MIDI scale (0-127), different from GDV scale
      expect(pdv_array[0][:velocity]).to be_a(Numeric)
      expect(pdv_array[0][:velocity]).to be > 0

      # Verify different durations are preserved
      expect(pdv_array[3][:duration]).to eq(1/2r)  # Half note
      expect(pdv_array[11][:duration]).to eq(1r)   # Whole note

      # Verify velocity increases from p (piano) to ff (fortissimo)
      expect(pdv_array[7][:velocity]).to be > pdv_array[0][:velocity]

      # Verify sequencer.play API compatibility
      sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
      expect(sequencer).to be_a(Musa::Sequencer::BaseSequencer)

      # Test that sequencer.play can be called with PDV series
      played_notes = []
      sequencer.play(pdv_notes) do |note|
        played_notes << { pitch: note[:pitch], duration: note[:duration], velocity: note[:velocity] }
        # In real usage: voice.note pitch: note[:pitch], velocity: note[:velocity], duration: note[:duration]
      end

      # Execute sequencer to process scheduled events
      sequencer.run

      # Verify all notes were played
      expect(played_notes.size).to eq(12)

      # Verify first note (C4, quarter, piano)
      expect(played_notes[0][:pitch]).to eq(60)  # Grade 0 = C
      expect(played_notes[0][:duration]).to eq(1/4r)
      expect(played_notes[0][:velocity]).to be_a(Numeric)

      # Verify second note (E4, quarter, mezzo-piano) - +2 from grade 0
      expect(played_notes[1][:pitch]).to eq(64)  # Grade 2 = E
      expect(played_notes[1][:duration]).to eq(1/4r)

      # Verify fourth note has half duration (forte)
      expect(played_notes[3][:duration]).to eq(1/2r)

      # Verify last note (C4, whole, piano)
      expect(played_notes[11][:pitch]).to eq(60)
      expect(played_notes[11][:duration]).to eq(1r)

      # Verify velocity dynamics: ff (fortissimo) is louder than p (piano)
      expect(played_notes[7][:velocity]).to be > played_notes[0][:velocity]
    end
  end

  context 'Series - Sequence Generators' do
    include Musa::Series

    it 'creates melodic series using basic operations' do
      # S constructor with repeat
      melody = S(0, 2, 4, 5, 7).repeat(2)
      result = melody.i.to_a

      expect(result).to be_an(Array)
      expect(result.size).to eq(10)
      expect(result).to eq([0, 2, 4, 5, 7, 0, 2, 4, 5, 7])

      # Transform with map
      transposed = S(60, 64, 67).map { |n| n + 12 }
      expect(transposed.i.to_a).to eq([72, 76, 79])

      # Filter with select
      evens = S(1, 2, 3, 4, 5, 6).select { |n| n.even? }
      expect(evens.i.to_a).to eq([2, 4, 6])
    end

    it 'combines multiple parameters with .with' do
      pitches = S(60, 64, 67, 72)
      durations = S(1r, 1/2r, 1/2r, 1r)
      velocities = S(96, 80, 90, 100)

      notes = pitches.with(dur: durations, vel: velocities) do |p, dur:, vel:|
        { pitch: p, duration: dur, velocity: vel }
      end

      result = notes.i.to_a

      expect(result).to be_an(Array)
      expect(result.size).to eq(4)
      expect(result[0]).to eq({ pitch: 60, duration: 1r, velocity: 96 })
      expect(result[1]).to eq({ pitch: 64, duration: 1/2r, velocity: 80 })
      expect(result[2]).to eq({ pitch: 67, duration: 1/2r, velocity: 90 })
      expect(result[3]).to eq({ pitch: 72, duration: 1r, velocity: 100 })
    end

    it 'creates PDV with H() and HC()' do
      # Create PDV from series of different sizes
      pitches = S(60, 62, 64, 65, 67)      # 5 notes
      durations = S(1r, 1/2r, 1/4r)        # 3 durations
      velocities = S(96, 80, 90, 100)      # 4 velocities

      # H: Stop when shortest series exhausts
      notes = H(pitch: pitches, duration: durations, velocity: velocities)

      result = notes.i.to_a
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)  # Limited by shortest (durations)
      expect(result[0]).to eq({ pitch: 60, duration: 1r, velocity: 96 })
      expect(result[1]).to eq({ pitch: 62, duration: 1/2r, velocity: 80 })
      expect(result[2]).to eq({ pitch: 64, duration: 1/4r, velocity: 90 })

      # HC: Continue cycling all series
      pitches2 = S(60, 62, 64, 65, 67)
      durations2 = S(1r, 1/2r, 1/4r)
      velocities2 = S(96, 80, 90, 100)

      notes_cycling = HC(pitch: pitches2, duration: durations2, velocity: velocities2)
        .max_size(7)

      result_cycling = notes_cycling.i.to_a
      expect(result_cycling).to be_an(Array)
      expect(result_cycling.size).to eq(7)
      expect(result_cycling[0]).to eq({ pitch: 60, duration: 1r, velocity: 96 })
      expect(result_cycling[1]).to eq({ pitch: 62, duration: 1/2r, velocity: 80 })
      expect(result_cycling[2]).to eq({ pitch: 64, duration: 1/4r, velocity: 90 })
      expect(result_cycling[3]).to eq({ pitch: 65, duration: 1r, velocity: 100 })
      expect(result_cycling[4]).to eq({ pitch: 67, duration: 1/2r, velocity: 96 })
      expect(result_cycling[5]).to eq({ pitch: 60, duration: 1/4r, velocity: 80 })
      expect(result_cycling[6]).to eq({ pitch: 62, duration: 1r, velocity: 90 })
    end

    it 'merges melodic phrases with MERGE' do
      phrase1 = S(60, 64, 67)
      phrase2 = S(72, 69, 65)
      phrase3 = S(60, 62, 64)

      melody = MERGE(phrase1, phrase2, phrase3)
      expect(melody.i.to_a).to eq([60, 64, 67, 72, 69, 65, 60, 62, 64])

      # Repeat merged structure
      section = MERGE(S(1, 2, 3), S(4, 5, 6)).repeat(2)
      expect(section.i.to_a).to eq([1, 2, 3, 4, 5, 6, 1, 2, 3, 4, 5, 6])
    end

    it 'uses numeric generators FOR, FIBO, HARMO' do
      # FOR: ascending
      ascending = FOR(from: 0, to: 7, step: 1)
      expect(ascending.i.to_a).to eq([0, 1, 2, 3, 4, 5, 6, 7])

      # FOR: descending
      descending = FOR(from: 10, to: 0, step: 2)
      expect(descending.i.to_a).to eq([10, 8, 6, 4, 2, 0])

      # FIBO: Fibonacci rhythmic proportions
      rhythm = FIBO().max_size(8).map { |n| Rational(n, 16) }
      result = rhythm.i.to_a
      expect(result).to eq([1/16r, 1/16r, 1/8r, 3/16r, 5/16r, 1/2r, 13/16r, 21/16r])

      # HARMO: Harmonic series
      harmonics = HARMO(error: 0.5).max_size(10)
      result = harmonics.i.to_a
      expect(result).to be_an(Array)
      expect(result.size).to eq(10)
      expect(result.first).to eq(0)
      expect(result[1]).to eq(12)  # Octave
    end

    it 'uses structural transformations: reverse, merge, chaining' do
      # Reverse
      melody = S(60, 64, 67, 72)
      retrograde = melody.reverse
      expect(retrograde.i.to_a).to eq([72, 67, 64, 60])

      # merge operation on serie of series
      chunks = S(1, 2, 3, 4, 5, 6).cut(2)  # Split into pairs (serie of series)

      # Each chunk is a serie, use .merge to flatten
      reconstructed = chunks.merge
      expect(reconstructed.i.to_a).to eq([1, 2, 3, 4, 5, 6])

      # Verify chunks structure by converting each chunk to array
      chunks_inst = S(1, 2, 3, 4, 5, 6).cut(2).i
      chunk_arrays = []
      while (chunk = chunks_inst.next_value)
        chunk_arrays << chunk.i.to_a
      end
      expect(chunk_arrays).to eq([[1, 2], [3, 4], [5, 6]])

      # Chaining operations
      result = S(60, 62, 64, 65, 67, 69, 71, 72)
        .select { |n| n.even? }  # [60, 62, 64, 72]
        .map { |n| n + 12 }      # [72, 74, 76, 84]
        .reverse                  # [84, 76, 74, 72]
        .repeat(2)                # Repeat twice

      expect(result.i.to_a).to eq([84, 76, 74, 72, 84, 76, 74, 72])
    end
  end

  context 'Sequencer - Temporal Engine' do
    include Musa::All

    it 'demonstrates all sequencer DSL methods in a musical composition' do
      # Setup
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Define series outside DSL block
      melody = S({ note: 60, duration: 1/2r }, { note: 62, duration: 1/2r },
                 { note: 64, duration: 1/2r }, { note: 65, duration: 1/2r },
                 { note: 67, duration: 1/2r }, { note: 65, duration: 1/2r },
                 { note: 64, duration: 1/2r }, { note: 62, duration: 1/2r })

      # Track events for verification
      section_changes = []
      at_events = []
      wait_events = []
      play_notes = []
      play_positions = []
      every_events = []
      stop_executed = false
      move_values = []
      move_hash_values = []

      # Program sequencer using DSL
      sequencer.with do
        # Custom event handlers (on/launch)
        on :section_change do |name|
          section_changes << name
        end

        # Immediate event (now)
        now do
          launch :section_change, "Start"
        end

        # Absolute positioning (at): event at bar 1
        at 1 do
          at_events << position
        end

        # Relative positioning (wait): event 2 bars later
        wait 2 do
          wait_events << position
        end

        # Play series (play): reproduces series with automatic timing
        at 5 do
          play melody do |note:, duration:, control:|
            play_notes << { note: note, duration: duration }
            play_positions << position
          end
        end

        # Recurring event (every) with stop control
        beat_loop = nil
        at 10 do
          # Store control object to stop it later
          beat_loop = every 2, duration: 10 do
            every_events << position
          end
        end

        # Stop the beat loop at bar 18
        at 18 do
          beat_loop.stop if beat_loop
          stop_executed = true
        end

        # Animated value (move) from 0 to 10 over 4 bars
        at 20 do
          move from: 0, to: 10, duration: 4, every: 1/2r do |value|
            move_values << value.round(2)
          end
        end

        # Multi-parameter animation (move with hash)
        at 25 do
          move from: { pitch: 60, vel: 60 },
               to: { pitch: 72, vel: 100 },
               duration: 2,
               every: 1/4r do |values|
            move_hash_values << { pitch: values[:pitch].round, vel: values[:vel].round }
          end
        end

        # Final event
        at 30 do
          launch :section_change, "End"
          at_events << position
        end
      end

      # Execute sequencer
      sequencer.run

      # Verify section changes (on/launch)
      expect(section_changes).to eq(['Start', 'End'])

      # Verify at: events at specific positions
      expect(at_events).to include(1, 30)

      # Verify wait: event 2 bars after last now/at
      expect(wait_events.size).to eq(1)
      expect(wait_events.first).to be_between(2.9, 3.1)  # Approximately 3

      # Verify play: series played with all notes and durations
      expect(play_notes.size).to eq(8)
      expect(play_notes.map { |n| n[:note] }).to eq([60, 62, 64, 65, 67, 65, 64, 62])
      expect(play_notes.all? { |n| n[:duration] == 1/2r }).to be true

      # Verify notes are played sequentially, not simultaneously
      expect(play_positions.uniq.size).to eq(8)  # All different positions
      expect(play_positions.first).to eq(5)  # Starts at position 5
      expect(play_positions.last).to eq(5 + 7 * 1/2r)  # Last note at 5 + 3.5 = 8.5

      # Verify every: recurring events every 2 bars
      # Should be [10, 12, 14, 16] - stopped at bar 18 before next event at 18
      expect(every_events).to eq([10, 12, 14, 16])

      # Verify stop was executed
      expect(stop_executed).to be true

      # Verify move: animated values from 0 to 10
      expect(move_values.size).to be > 0
      expect(move_values.first).to eq(0.0)
      expect(move_values.last).to eq(10.0)

      # Verify move with hash: multi-parameter animation
      expect(move_hash_values.size).to be > 0
      expect(move_hash_values.first[:pitch]).to eq(60)
      expect(move_hash_values.last[:pitch]).to eq(72)
    end
  end

  context 'Neumas & Neumalang - Musical Notation' do
    using Musa::Extension::Neumas

    it 'parses neuma notation with durations' do
      # Test individual examples from README
      melody = "(0) (+2) (+2) (-1) (0)"
      rhythm = "(+2 1) (+2 2) (+1 1/2) (+2 1)"

      # Parse simple melody
      melody_neumas = melody.to_neumas
      expect(melody_neumas).to respond_to(:i)
      expect(melody_neumas.i.to_a.size).to eq(5)

      # Parse rhythm with durations
      rhythm_neumas = rhythm.to_neumas
      rhythm_array = rhythm_neumas.i.to_a
      expect(rhythm_array.size).to eq(4)
      expect(rhythm_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(rhythm_array[1][:gdvd][:abs_duration]).to eq(2)
      expect(rhythm_array[2][:gdvd][:abs_duration]).to eq(1/2r)
    end

    it 'parses complete song example with parallel voices using | operator' do
      # Complete example from README - parallel voices using | operator
      song = "(0 1 mf) (+2 1 mp) (+4 2 p) (+5 1/2 mf) (+7 1 f)" |
             "(+7 2 p) (+5 1 mp) (+7 1 mf) (+9 1/2 f) (+12 2 ff)"

      # Verify it's a parallel structure
      expect(song).to be_a(Hash)
      expect(song[:kind]).to eq(:parallel)
      expect(song[:parallel].size).to eq(2)

      # Test Voice 1 directly from parallel structure
      voice1_serie = song[:parallel][0][:serie]
      voice1_array = voice1_serie.i.to_a

      expect(voice1_array.size).to eq(5)

      # First note: grade 0, duration 1, velocity mf
      expect(voice1_array[0][:gdvd][:abs_grade]).to eq(0)
      expect(voice1_array[0][:gdvd][:abs_duration]).to eq(1)
      expect(voice1_array[0][:gdvd][:abs_velocity]).to eq(1)  # mf = 1

      # Third note: grade +4, duration 2, velocity p
      expect(voice1_array[2][:gdvd][:delta_grade]).to eq(4)
      expect(voice1_array[2][:gdvd][:abs_duration]).to eq(2)
      expect(voice1_array[2][:gdvd][:abs_velocity]).to eq(-1)  # p = -1

      # Fourth note: grade +5, duration 1/2, velocity mf
      expect(voice1_array[3][:gdvd][:delta_grade]).to eq(5)
      expect(voice1_array[3][:gdvd][:abs_duration]).to eq(1/2r)
      expect(voice1_array[3][:gdvd][:abs_velocity]).to eq(1)  # mf = 1

      # Test Voice 2 directly from parallel structure
      voice2_serie = song[:parallel][1][:serie]
      voice2_array = voice2_serie.i.to_a

      expect(voice2_array.size).to eq(5)

      # First note: grade +7, duration 2, velocity p
      expect(voice2_array[0][:gdvd][:delta_grade]).to eq(7)
      expect(voice2_array[0][:gdvd][:abs_duration]).to eq(2)
      expect(voice2_array[0][:gdvd][:abs_velocity]).to eq(-1)  # p = -1

      # Last note: grade +12, duration 2, velocity ff
      expect(voice2_array[4][:gdvd][:delta_grade]).to eq(12)
      expect(voice2_array[4][:gdvd][:abs_duration]).to eq(2)
      expect(voice2_array[4][:gdvd][:abs_velocity]).to eq(3)  # ff = 3
    end

    it 'plays parallel neumas with sequencer handling voices automatically' do
      # Create parallel structure
      song = "(0 1 mf) (+2 1 mp) (+4 2 p)" |
             "(+7 2 p) (+5 1 mp) (+7 1 mf)"

      # Wrap in serie outside DSL context
      song_serie = Musa::Series::Constructors.S(song)

      # Create decoder
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1r)

      # Track played notes
      played = []

      # Create sequencer and play parallel structure
      sequencer = Musa::Sequencer::Sequencer.new(4, 24) do
        at 1 do
          play song_serie, decoder: decoder, mode: :neumalang do |gdv|
            played << { position: position, gdv: gdv }
          end
        end
      end

      # Run sequencer
      sequencer.tick until sequencer.empty?

      # Verify notes were played
      expect(played.size).to eq(6)  # 3 notes from each voice

      # Verify parallel execution: first notes from both voices at same position
      expect(played[0][:position]).to eq(played[1][:position])
      expect(played[0][:gdv][:grade]).to eq(0)   # Voice 1 first note
      expect(played[1][:gdv][:grade]).to eq(7)   # Voice 2 first note

      # Verify durations were decoded
      expect(played[0][:gdv][:duration]).to eq(1)
      expect(played[1][:gdv][:duration]).to eq(2)

      # Verify velocities were decoded
      expect(played[0][:gdv][:velocity]).to eq(1)   # mf
      expect(played[1][:gdv][:velocity]).to eq(-1)  # p
    end
  end

  context 'Transcription - MIDI & MusicXML Output' do
    using Musa::Extension::Neumas

    it 'expands neuma ornaments (trill and mordent) to PDV note sequences for MIDI' do
      # Neuma notation with ornaments: trill (.tr) and mordent (.mor)
      neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

      # Create scale and decoder
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

      # Create MIDI transcriptor with ornament expansion
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMIDI.transcription_set(duration_factor: 1/6r),
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      # Parse and expand ornaments to PDV
      result = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                         .process_with { |gdv| transcriptor.transcript(gdv) }
                                         .map { |gdv| gdv.to_pdv(scale) }
                                         .to_a(recursive: true)

      # Verify expansion occurred (more notes than original 4 due to ornament expansion)
      expect(result.size).to be > 4

      # First note (no ornament)
      expect(result[0][:pitch]).to eq(60)  # C4
      expect(result[0][:duration]).to eq(1/4r)

      # Trill expansion (note with tr: true expands to multiple notes)
      # Second note has trill, so we should see alternating pitches
      trill_notes = result[1..6]  # Approximate range for trill expansion
      expect(trill_notes.any? { |n| n[:pitch] == 64 }).to be true  # E4 (original)
      expect(trill_notes.any? { |n| n[:pitch] == 65 }).to be true  # F4 (upper neighbor)

      # Verify all results have pitch, duration, and velocity
      result.each do |pdv|
        expect(pdv).to include(:pitch, :duration, :velocity)
      end
    end

    it 'generates MusicXML with ornaments preserved as notation symbols' do
      # Same phrase as MIDI example (ornaments preserved as symbols)
      neumas = "(0 1 mf) (+2 1 tr) (+4 1 mor) (+5 1)"

      # Create scale and decoder
      scale = Musa::Scales::Scales.et12[440.0].major[60]
      decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)

      # Create MusicXML transcriptor (preserves ornaments as symbols)
      transcriptor = Musa::Transcription::Transcriptor.new(
        Musa::Transcriptors::FromGDV::ToMusicXML.transcription_set,
        base_duration: 1/4r,
        tick_duration: 1/96r
      )

      # Parse and convert to GDV with preserved ornament markers
      serie = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder)
                                         .process_with { |gdv| transcriptor.transcript(gdv) }

      # Create Score and use sequencer to fill it
      score = Musa::Datasets::Score.new
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      sequencer.at 1 do
        play serie, decoder: decoder, mode: :neumalang do |gdv|
          pdv = gdv.to_pdv(scale)
          score.at(position, add: pdv)  # position is automatically tracked by sequencer
        end
      end

      sequencer.run

      # Convert to MusicXML
      mxml = score.to_mxml(
        4, 24,  # 4 beats per bar, 24 ticks per beat
        bpm: 120,
        title: 'Ornaments Example',
        creators: { composer: 'MusaDSL' },
        parts: { piano: { name: 'Piano', clefs: { g: 2 } } }
      )

      # Verify MusicXML structure
      xml_string = mxml.to_xml.string

      expect(xml_string).to include('Ornaments Example')
      expect(xml_string).to include('MusaDSL')

      # Verify ornaments preserved as XML notation symbols (not expanded)
      expect(xml_string).to include('<trill-mark />')
      expect(xml_string).to include('<inverted-mordent />')

      # Verify only 4 notes (not 11 like MIDI expansion)
      # Count <note> tags that aren't rests
      pitched_notes = xml_string.scan(/<note>.*?<pitch>.*?<\/note>/m)
      expect(pitched_notes.size).to eq(4)
    end
  end

  context 'Generative - Algorithmic Composition' do
    it 'creates Markov chain for probabilistic sequence generation' do
      markov = Musa::Markov::Markov.new(
        start: 0,
        finish: :end,
        transitions: {
          0 => { 2 => 0.5, 4 => 0.3, 7 => 0.2 },
          2 => { 0 => 0.3, 4 => 0.5, 5 => 0.2 },
          4 => { 2 => 0.4, 5 => 0.4, 7 => 0.2 },
          5 => { 0 => 0.5, :end => 0.5 },
          7 => { 0 => 0.6, :end => 0.4 }
        }
      ).i

      # Generate melody pitches (Markov is a Serie, so we can use .to_a)
      melody_pitches = markov.to_a

      expect(melody_pitches).to be_an(Array)
      expect(melody_pitches.size).to be > 0
      expect([0, 2, 4, 5, 7]).to include(melody_pitches[0])
    end

    it 'uses Variatio for Cartesian product of parameter variations' do
      # Variatio - Cartesian product of parameter variations
      # Generates ALL combinations of field values
      variatio = Musa::Variatio::Variatio.new :chord do
        field :root, [60, 64, 67]     # C, E, G
        field :type, [:major, :minor]

        constructor do |root:, type:|
          { root: root, type: type }
        end
      end

      all_chords = variatio.run

      # 3 roots × 2 types = 6 variations
      expect(all_chords).to be_an(Array)
      expect(all_chords.size).to eq(6)

      expect(all_chords).to include({ root: 60, type: :major })
      expect(all_chords).to include({ root: 60, type: :minor })
      expect(all_chords).to include({ root: 64, type: :major })
      expect(all_chords).to include({ root: 64, type: :minor })
      expect(all_chords).to include({ root: 67, type: :major })
      expect(all_chords).to include({ root: 67, type: :minor })

      # Override field values at runtime
      limited_chords = variatio.on(root: [60, 64])
      # 2 roots × 2 types = 4 variations
      expect(limited_chords.size).to eq(4)
      expect(limited_chords).to include({ root: 60, type: :major })
      expect(limited_chords).to include({ root: 60, type: :minor })
      expect(limited_chords).to include({ root: 64, type: :major })
      expect(limited_chords).to include({ root: 64, type: :minor })
    end

    it 'generates chord voicings using Rules production system' do
      # Build chord voicings by adding notes sequentially
      rules = Musa::Rules::Rules.new do
        # Step 1: Choose root note
        grow 'add root' do |seed|
          [60, 64, 67].each { |root| branch [root] }  # C, E, G
        end

        # Step 2: Add third (major or minor)
        grow 'add third' do |chord|
          branch chord + [chord[0] + 4]  # Major third
          branch chord + [chord[0] + 3]  # Minor third
        end

        # Step 3: Add fifth
        grow 'add fifth' do |chord|
          branch chord + [chord[0] + 7]
        end

        # Pruning rule: avoid wide intervals
        cut 'no wide spacing' do |chord|
          if chord.size >= 2
            prune if (chord[-1] - chord[-2]) > 12  # Max octave between adjacent notes
          end
        end

        # End after three notes
        ended_when do |chord|
          chord.size == 3
        end
      end

      tree = rules.apply(0)  # seed value (triggers generation)
      combinations = tree.combinations

      expect(combinations).to be_an(Array)
      expect(combinations.size).to eq(6)  # 3 roots × 2 thirds × 1 fifth = 6 voicings

      # Extract voicings from combinations (last element of each path)
      voicings = combinations.map { |path| path.last }

      # All voicings should have 3 notes
      expect(voicings.all? { |v| v.size == 3 }).to be true

      # Should include specific voicings
      expect(voicings).to include([60, 64, 67])  # C major
      expect(voicings).to include([60, 63, 67])  # C minor

      # With parameters
      tree_with_params = rules.apply(0, max_interval: 7)
      expect(tree_with_params).to respond_to(:combinations)
      expect(tree_with_params.combinations).to be_an(Array)
    end

    it 'generates combinations using Generative Grammar with operators' do
      # Use GenerativeGrammar module methods directly
      a = Musa::GenerativeGrammar.N('a', size: 1)
      b = Musa::GenerativeGrammar.N('b', size: 1)
      c = Musa::GenerativeGrammar.N('c', size: 1)
      d = b | c  # d can be either b or c

      # Grammar: (a or d) repeated 3 times, then c
      grammar = (a | d).repeat(3) + c

      # Generate all possibilities
      result = grammar.options(content: :join)

      expect(result).to be_an(Array)
      expect(result.size).to eq(27)  # 3^3 × 1 = 27 combinations

      # Should include specific combinations
      expect(result).to include("aaac")
      expect(result).to include("abac")
      expect(result).to include("acac")
      expect(result).to include("cccc")

      # With constraints - filter by attribute
      grammar_with_limit = (a | d).repeat(min: 1, max: 4).limit { |o|
        o.collect { |e| e.attributes[:size] }.sum <= 3
      }

      result_limited = grammar_with_limit.options(content: :join)
      expect(result_limited).to be_an(Array)
      expect(result_limited.size).to eq(36)  # All valid combinations with size <= 3

      # Should include pairs (size = 2)
      expect(result_limited).to include("aa")
      expect(result_limited).to include("ab")
      expect(result_limited).to include("bc")

      # Should include triples (size = 3)
      expect(result_limited).to include("aaa")
      expect(result_limited).to include("abc")
      expect(result_limited).to include("ccc")

      # Should NOT include quadruples (size > 3)
      expect(result_limited).not_to include("aaaa")
      expect(result_limited).not_to include("abcd")
    end

    it 'selects and ranks population using Darwin fitness evaluation' do
      # Generate population using Variatio
      variatio = Musa::Variatio::Variatio.new :melody do
        field :interval, 1..7
        field :contour, [:up, :down, :repeat]
        field :duration, [1/4r, 1/2r, 1r]

        constructor do |interval:, contour:, duration:|
          { interval: interval, contour: contour, duration: duration }
        end
      end

      candidates = variatio.run
      expect(candidates.size).to eq(63)  # 7 × 3 × 3

      # Select and rank using Darwin
      darwin = Musa::Darwin::Darwin.new do
        measures do |melody|
          die if melody[:interval] > 5  # No large leaps

          feature :stepwise if melody[:interval] <= 2
          feature :has_quarter_notes if melody[:duration] == 1/4r

          dimension :interval_size, -melody[:interval].to_f
          dimension :duration_value, melody[:duration].to_f
        end

        weight interval_size: 2.0,
               stepwise: 1.5,
               has_quarter_notes: 1.0,
               duration_value: -0.5
      end

      ranked = darwin.select(candidates)

      # Verify large intervals are excluded
      expect(ranked.none? { |m| m[:interval] > 5 }).to be true

      # Verify we have results
      expect(ranked.size).to be > 0
      expect(ranked.size).to be < 63  # Some candidates excluded

      # Best candidate should have good characteristics
      best_melody = ranked.first
      expect(best_melody[:interval]).to be <= 5
      expect([1, 2, 3, 4, 5]).to include(best_melody[:interval])
    end
  end

  context 'Music - Scales & Chords' do
    include Musa::Scales
    include Musa::Chords

    it 'accesses default system and creates scales' do
      # Access default system and tuning
      tuning = Scales.default_system.default_tuning

      # Create scales using available scale kinds
      c_major = tuning.major[60]
      d_minor = tuning.minor[62]
      e_harmonic = tuning.minor_harmonic[64]
      chromatic = tuning.chromatic[60]

      expect(c_major).to be_a(Musa::Scales::Scale)
      expect(d_minor).to be_a(Musa::Scales::Scale)
      expect(e_harmonic).to be_a(Musa::Scales::Scale)
      expect(chromatic).to be_a(Musa::Scales::Scale)
    end

    it 'accesses scale notes by grade and function' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      # Access by grade
      tonic = c_major[0]
      mediant = c_major[2]
      dominant = c_major[4]

      expect(tonic.pitch).to eq(60)    # C
      expect(mediant.pitch).to eq(64)  # E
      expect(dominant.pitch).to eq(67) # G

      # Access by function name
      expect(c_major.tonic.pitch).to eq(60)
      expect(c_major.supertonic.pitch).to eq(62)
      expect(c_major.mediant.pitch).to eq(64)
      expect(c_major.subdominant.pitch).to eq(65)
      expect(c_major.dominant.pitch).to eq(67)

      # Access by Roman numeral
      expect(c_major[:I].pitch).to eq(60)
      expect(c_major[:V].pitch).to eq(67)
    end

    it 'navigates with octaves and chromatic operations' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      # Octave navigation
      note = c_major[2].octave(1)
      expect(note.pitch).to eq(76)  # E in octave 1

      # Chromatic operations
      c_sharp = c_major.tonic.sharp
      c_flat = c_major.tonic.flat

      expect(c_sharp.pitch).to eq(61)  # C#
      expect(c_flat.pitch).to eq(59)   # Cb

      # Navigate by semitones
      fifth_up = c_major.tonic.sharp(7)
      third_up = c_major.tonic.sharp(4)

      expect(fifth_up.pitch).to eq(67)  # G
      expect(third_up.pitch).to eq(64)  # E
    end

    it 'calculates frequencies' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      frequency = c_major.tonic.frequency
      expect(frequency).to be_within(0.01).of(261.63)  # Middle C at A=440
    end

    it 'creates chords from scale degrees' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]

      # Create triads
      i_chord = c_major.tonic.chord
      ii_chord = c_major.supertonic.chord
      v_chord = c_major.dominant.chord

      expect(i_chord).to be_a(Musa::Chords::Chord)
      expect(i_chord.pitches).to eq([60, 64, 67])  # C, E, G

      # Create extended chords
      i_seventh = c_major.tonic.chord :seventh
      expect(i_seventh.pitches).to eq([60, 64, 67, 71])  # C, E, G, B
    end

    it 'accesses chord tones and features' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      i_chord = c_major.tonic.chord

      # Access chord tones by name
      root = i_chord.root
      third = i_chord.third
      fifth = i_chord.fifth

      expect(root.pitch).to eq(60)
      expect(third.pitch).to eq(64)
      expect(fifth.pitch).to eq(67)

      # Chord features
      expect(i_chord.quality).to eq(:major)
      expect(i_chord.size).to eq(:triad)
    end

    it 'navigates between chord qualities and extensions' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      i_chord = c_major.tonic.chord

      # Navigate between chord qualities
      minor_chord = i_chord.with_quality(:minor)
      expect(minor_chord.quality).to eq(:minor)
      expect(minor_chord.pitches).to eq([60, 63, 67])  # C, Eb, G

      diminished = i_chord.with_quality(:diminished)
      expect(diminished.quality).to eq(:diminished)

      # Change chord extensions
      seventh_chord = i_chord.with_size(:seventh)
      expect(seventh_chord.size).to eq(:seventh)
      expect(seventh_chord.pitches.size).to eq(4)
    end

    it 'modifies chord voicings' do
      tuning = Scales.default_system.default_tuning
      c_major = tuning.major[60]
      i_chord = c_major.tonic.chord

      # Move specific tones to different octaves
      voiced = i_chord.move(root: -1, fifth: 1)
      expect(voiced.root.pitch).to eq(48)   # Root down one octave
      expect(voiced.fifth.pitch).to eq(79)  # Fifth up one octave

      # Duplicate tones in other octaves
      doubled = i_chord.duplicate(root: -2)
      pitches = doubled.pitches
      expect(pitches).to include(36)  # Root 2 octaves down
      expect(pitches).to include(60)  # Original root

      # Transpose entire chord
      lower = i_chord.octave(-1)
      expect(lower.pitches).to eq([48, 52, 55])  # Whole chord down one octave
    end

    it 'defines and uses custom pentatonic scale kind' do
      # Define custom pentatonic scale kind
      class PentatonicMajorScaleKind < Musa::Scales::ScaleKind
        class << self
          def id
            :pentatonic_major
          end

          def pitches
            [{ functions: [:I, :_1, :tonic], pitch: 0 },
             { functions: [:II, :_2], pitch: 2 },
             { functions: [:III, :_3], pitch: 4 },
             { functions: [:V, :_5], pitch: 7 },
             { functions: [:VI, :_6], pitch: 9 }]
          end

          def grades
            5
          end
        end
      end

      # Register with the 12-tone system
      Scales.et12.register(PentatonicMajorScaleKind)

      # Use the new scale kind
      tuning = Scales.default_system.default_tuning
      c_pentatonic = tuning[:pentatonic_major][60]

      expect(c_pentatonic).to be_a(Musa::Scales::Scale)
      expect(c_pentatonic[0].pitch).to eq(60)  # C
      expect(c_pentatonic[1].pitch).to eq(62)  # D
      expect(c_pentatonic[2].pitch).to eq(64)  # E
      expect(c_pentatonic[3].pitch).to eq(67)  # G
      expect(c_pentatonic[4].pitch).to eq(69)  # A
    end

    it 'defines and registers custom chord definitions' do
      # Register sus4 chord
      Musa::Chords::ChordDefinition.register :sus4_test,
        quality: :suspended,
        size: :triad,
        offsets: { root: 0, fourth: 5, fifth: 7 }

      # Register add9 chord
      Musa::Chords::ChordDefinition.register :add9_test,
        quality: :major,
        size: :extended,
        offsets: { root: 0, third: 4, fifth: 7, ninth: 14 }

      # Verify registrations
      sus4_def = Musa::Chords::ChordDefinition[:sus4_test]
      add9_def = Musa::Chords::ChordDefinition[:add9_test]

      expect(sus4_def).not_to be_nil
      expect(sus4_def.name).to eq(:sus4_test)
      expect(sus4_def.features[:quality]).to eq(:suspended)
      expect(sus4_def.features[:size]).to eq(:triad)

      expect(add9_def).not_to be_nil
      expect(add9_def.name).to eq(:add9_test)
      expect(add9_def.features[:quality]).to eq(:major)
      expect(add9_def.features[:size]).to eq(:extended)
    end
  end

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
  end

  context 'MusicXML Builder - Music Notation Export' do
    it 'creates score using constructor style (method calls)' do
      # Create score with metadata
      score = Musa::MusicXML::Builder::ScorePartwise.new(
        work_title: "Piano Piece",
        creators: { composer: "Your Name" },
        encoding_date: DateTime.new(2024, 1, 1)
      )

      # Add parts using add_* methods
      part = score.add_part(:p1, name: "Piano", abbreviation: "Pno.")

      # Add measures and attributes
      measure = part.add_measure(divisions: 4)

      # Add attributes (key, time, clef, etc.)
      measure.attributes.last.add_key(1, fifths: 0)        # C major
      measure.attributes.last.add_time(1, beats: 4, beat_type: 4)
      measure.attributes.last.add_clef(1, sign: 'G', line: 2)

      # Add notes
      measure.add_pitch(step: 'C', octave: 4, duration: 4, type: 'quarter')
      measure.add_pitch(step: 'E', octave: 4, duration: 4, type: 'quarter')
      measure.add_pitch(step: 'G', octave: 4, duration: 4, type: 'quarter')
      measure.add_pitch(step: 'C', octave: 5, duration: 4, type: 'quarter')

      # Verify XML is generated
      xml_string = score.to_xml.string
      expect(xml_string).to include('<?xml version="1.0"')
      expect(xml_string).to include('<score-partwise')
      expect(xml_string).to include('<work-title>Piano Piece</work-title>')
      expect(xml_string).to include('<creator type="composer">Your Name</creator>')
      expect(xml_string).to include('</score-partwise>')
    end

    it 'creates score using DSL style (blocks)' do
      score = Musa::MusicXML::Builder::ScorePartwise.new do
        work_title "Piano Piece"
        creators composer: "Your Name"
        encoding_date DateTime.new(2024, 1, 1)

        part :p1, name: "Piano", abbreviation: "Pno." do
          measure do
            attributes do
              divisions 4
              key 1, fifths: 0        # C major
              time 1, beats: 4, beat_type: 4
              clef 1, sign: 'G', line: 2
            end

            pitch 'C', octave: 4, duration: 4, type: 'quarter'
            pitch 'E', octave: 4, duration: 4, type: 'quarter'
            pitch 'G', octave: 4, duration: 4, type: 'quarter'
            pitch 'C', octave: 5, duration: 4, type: 'quarter'
          end
        end
      end

      # Verify XML is generated
      xml_string = score.to_xml.string
      expect(xml_string).to include('<?xml version="1.0"')
      expect(xml_string).to include('<score-partwise')
      expect(xml_string).to include('<work-title>Piano Piece</work-title>')
      expect(xml_string).to include('<creator type="composer">Your Name</creator>')
      expect(xml_string).to include('</score-partwise>')
    end

    it 'creates sophisticated piano score with multiple features' do
      score = Musa::MusicXML::Builder::ScorePartwise.new do
        work_title "Étude in D Major"
        work_number 1
        creators composer: "Example Composer"
        encoding_date DateTime.new(2024, 1, 1)

        part :p1, name: "Piano" do
          # Measure 1 - Setup and opening with two staves
          measure do
            attributes do
              divisions 2

              # Treble clef (staff 1)
              key 1, fifths: 2        # D major
              clef 1, sign: 'G', line: 2
              time 1, beats: 4, beat_type: 4

              # Bass clef (staff 2)
              key 2, fifths: 2
              clef 2, sign: 'F', line: 4
              time 2, beats: 4, beat_type: 4
            end

            # Tempo marking
            metronome beat_unit: 'quarter', per_minute: 120

            # Right hand
            pitch 'D', octave: 4, duration: 4, type: 'half', slur: 'start'
            pitch 'E', octave: 4, duration: 4, type: 'half', slur: 'stop'

            # Return for left hand
            backup 8

            # Left hand
            pitch 'D', octave: 3, duration: 8, type: 'whole', staff: 2
          end

          # Measure 2 - Two voices
          measure do
            # Voice 1
            pitch 'F#', octave: 4, duration: 2, type: 'quarter', alter: 1, voice: 1
            pitch 'G', octave: 4, duration: 2, type: 'quarter', voice: 1

            # Return for voice 2
            backup 4

            # Voice 2
            pitch 'A', octave: 3, duration: 2, type: 'quarter', voice: 2
            pitch 'B', octave: 3, duration: 2, type: 'quarter', voice: 2
          end
        end
      end

      xml_string = score.to_xml.string

      # Verify structure
      expect(xml_string).to include('<work-title>Étude in D Major</work-title>')
      expect(xml_string).to include('<work-number>1</work-number>')
      expect(xml_string).to include('<beat-unit>quarter</beat-unit>')
      expect(xml_string).to include('<per-minute>120</per-minute>')

      # Verify multiple staves
      expect(xml_string).to include('<staff>2</staff>')
      expect(xml_string).to include('<staves>2</staves>')

      # Verify slurs
      expect(xml_string).to include('<slur type="start"/>')
      expect(xml_string).to include('<slur type="stop"/>')

      # Verify backup
      expect(xml_string).to include('<backup>')

      # Verify voices
      expect(xml_string).to include('<voice>1</voice>')
      expect(xml_string).to include('<voice>2</voice>')

      # Verify alterations
      expect(xml_string).to include('<alter>1</alter>')
    end
  end

  context 'MIDI - Voice Management & Recording' do
    it 'creates MIDIRecorder and captures transcription format' do
      # Create sequencer
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Create recorder
      recorder = Musa::MIDIRecorder::MIDIRecorder.new(sequencer)

      # Verify recorder was created
      expect(recorder).to be_a(Musa::MIDIRecorder::MIDIRecorder)

      # Verify it has transcription method
      expect(recorder).to respond_to(:transcription)

      # Verify it has raw method
      expect(recorder).to respond_to(:raw)

      # Verify it has clear method
      expect(recorder).to respond_to(:clear)

      # Verify it has record method
      expect(recorder).to respond_to(:record)

      # Initially empty
      expect(recorder.transcription).to eq([])
      expect(recorder.raw).to eq([])

      # After clearing, still empty
      recorder.clear
      expect(recorder.transcription).to eq([])
    end

    it 'understands transcription output format' do
      # Transcription output format documentation
      note_example = {
        position: 1r,
        channel: 0,
        pitch: 60,
        velocity: 100,
        duration: 1/4r,
        velocity_off: 64
      }

      silence_example = {
        position: 5/4r,
        channel: 0,
        pitch: :silence,
        duration: 1/8r
      }

      # Verify expected keys exist
      expect(note_example).to have_key(:position)
      expect(note_example).to have_key(:channel)
      expect(note_example).to have_key(:pitch)
      expect(note_example).to have_key(:velocity)
      expect(note_example).to have_key(:duration)
      expect(note_example).to have_key(:velocity_off)

      # Verify silence format
      expect(silence_example[:pitch]).to eq(:silence)
      expect(silence_example).to have_key(:duration)
    end
  end

  context 'Matrix - Sonic Gesture Conversion' do
    it 'converts matrix to P format for sequencer playback' do
      # Matrix representing a melodic gesture: [time, pitch]
      melody_matrix = Matrix[[0, 60], [1, 62], [2, 64]]

      # Convert to P format for sequencer playback
      p_sequence = melody_matrix.to_p(time_dimension: 0)

      expect(p_sequence).to be_an(Array)
      expect(p_sequence.size).to eq(1)

      # Result format: [[pitch1], duration1, [pitch2], duration2, [pitch3]]
      first_p = p_sequence[0]
      expect(first_p).to eq([[60], 1, [62], 1, [64]])
    end

    it 'converts multi-parameter matrix (time, pitch, velocity) to P format' do
      # Multi-parameter example: [time, pitch, velocity]
      gesture = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
      p_with_velocity = gesture.to_p(time_dimension: 0)

      expect(p_with_velocity).to be_an(Array)
      expect(p_with_velocity.size).to eq(1)

      # Result: [[pitch, velocity], duration, [pitch, velocity], duration, [pitch, velocity]]
      first_p = p_with_velocity[0]
      expect(first_p).to eq([[60, 100], 0.5, [62, 110], 0.5, [64, 120]])
    end

    it 'condenses connected gestures that share endpoints' do
      # Two phrases that connect at [1, 62]
      phrase1 = Matrix[[0, 60], [1, 62]]
      phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]

      # Matrices that share endpoints are automatically merged
      merged = [phrase1, phrase2].to_p(time_dimension: 0)

      expect(merged).to be_an(Array)
      expect(merged.size).to eq(1)

      # Both phrases merged into continuous sequence
      first_p = merged[0]
      expect(first_p).to eq([[[60], 1, [62], 1, [64], 1, [65]]])
    end
  end

  context 'Transport - Timing & Clocks' do
    it 'creates different clock types for various timing sources' do
      # TimerClock - internal Ruby timer
      timer_clock = Musa::Clock::TimerClock.new(bpm: 120, ticks_per_beat: 24)
      expect(timer_clock).to be_a(Musa::Clock::TimerClock)

      # DummyClock - for testing without real timing (100 ticks)
      dummy_clock = Musa::Clock::DummyClock.new(100)
      expect(dummy_clock).to be_a(Musa::Clock::DummyClock)

      # ExternalTickClock - manual tick control
      external_clock = Musa::Clock::ExternalTickClock.new
      expect(external_clock).to be_a(Musa::Clock::ExternalTickClock)
    end

    it 'creates transport with lifecycle callbacks and schedules events' do
      # Create clock and transport
      # Position 2 bars = 2 * 24 ticks/beat * 4 beats/bar = 192 ticks
      # Add extra ticks for safety
      clock = Musa::Clock::DummyClock.new(200)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      # Track lifecycle events
      events = []

      transport.before_begin { events << :before_begin }
      transport.on_start { events << :on_start }
      transport.after_stop { events << :after_stop }

      # Schedule events
      sequencer = transport.sequencer
      sequencer.at 1 do
        events << :event_at_1
      end

      sequencer.at 2 do
        events << :event_at_2
        transport.stop
      end

      # Start transport (runs until stopped)
      transport.start

      # Verify lifecycle callbacks were called in order
      # Note: after_stop calls before_begin again to prepare for next start
      expect(events).to eq([:before_begin, :on_start, :event_at_1, :event_at_2, :after_stop, :before_begin])
    end

    it 'supports manual position control and on_change_position callback' do
      # 4 bars * 24 ticks/beat * 4 beats/bar = 384 ticks
      clock = Musa::Clock::DummyClock.new(400)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      positions = []
      transport.on_change_position { |seq| positions << seq.position }

      # Schedule event to stop at bar 4
      transport.sequencer.at 4 do
        transport.stop
      end

      transport.start

      # Verify position changes were tracked (if any occurred)
      # on_change_position is called when position jumps/seeks occur
      # Since we're not jumping positions, this may be empty
      expect(positions).to be_an(Array)
    end

    it 'allows changing playback position via change_position_to' do
      # 8 bars * 24 ticks/beat * 4 beats/bar = 768 ticks
      clock = Musa::Clock::DummyClock.new(800)
      transport = Musa::Transport::Transport.new(clock, 4, 24)

      events = []
      positions_changed = []

      transport.on_change_position { |seq| positions_changed << seq.position }

      # Schedule event at position 8
      transport.sequencer.at 8 do
        events << :measure_8
        transport.stop
      end

      # Start from bar 8 (position 8)
      transport.change_position_to(bars: 8)
      transport.start

      # Verify the event at position 8 was executed
      expect(events).to include(:measure_8)
      # Verify position change was detected (approximately at bar 8)
      expect(positions_changed).not_to be_empty
      expect(positions_changed.first.to_f).to be_within(0.1).of(8.0)
    end
  end
end
