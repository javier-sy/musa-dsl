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
    it 'creates Markov chain for probabilistic sequence generation (CORRECTED FROM README)' do
      # NOTE: README shows Musa::Generative::Markov with DSL syntax
      # Real API is Musa::Markov::Markov with hash-based transitions

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

      melody = []
      16.times do
        value = markov.next_value
        break unless value
        melody << value
      end

      expect(melody).to be_an(Array)
      expect(melody.size).to be > 0
      expect([0, 2, 4, 5, 7]).to include(melody[0])
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
    end
  end

  context 'Music - Scales & Chords' do
    it 'gets scales from equal temperament 12-tone system (CORRECTED FROM README)' do
      # NOTE: README shows .dorian which doesn't exist in this scale system
      # Using .minor instead

      major = Musa::Scales::Scales.et12[440.0].major[60]      # C major
      minor = Musa::Scales::Scales.et12[440.0].minor[62]      # D minor

      expect(major).to be_a(Musa::Scales::Scale)
      expect(minor).to be_a(Musa::Scales::Scale)
    end

    it 'creates chord definitions from scale' do
      # Chord definitions from scale
      major = Musa::Scales::Scales.et12[440.0].major[60]

      c_major = major.tonic.chord

      expect(c_major).to be_a(Musa::Chords::Chord)

      # Get chord note pitches
      note_pitches = c_major.notes.map { |n| n.note.pitch }

      expect(note_pitches).to eq([60, 64, 67])  # C, E, G
    end
  end

  context 'Datasets - Musical Data Structures' do
    it 'creates GDV (Grade, Duration, Velocity) absolute structure' do
      # GDV - Grade, Duration, Velocity (absolute)
      gdv = { grade: 2, duration: 1/4r, velocity: 0.7 }

      expect(gdv).to be_a(Hash)
      expect(gdv[:grade]).to eq(2)
      expect(gdv[:duration]).to eq(1/4r)
      expect(gdv[:velocity]).to eq(0.7)
    end

    it 'creates GDVd (Grade, Duration, Velocity) differential structure' do
      # GDVd - Grade, Duration, Velocity (differential)
      gdvd = { grade_diff: +2, duration_factor: 2, velocity_factor: 1.2 }

      expect(gdvd).to be_a(Hash)
      expect(gdvd[:grade_diff]).to eq(2)
      expect(gdvd[:duration_factor]).to eq(2)
      expect(gdvd[:velocity_factor]).to eq(1.2)
    end

    it 'creates PDV (Pitch, Duration, Velocity) structure' do
      # PDV - Pitch, Duration, Velocity
      pdv = { pitch: 64, duration: 1/4r, velocity: 100 }

      expect(pdv).to be_a(Hash)
      expect(pdv[:pitch]).to eq(64)
      expect(pdv[:duration]).to eq(1/4r)
      expect(pdv[:velocity]).to eq(100)
    end
  end

  context 'Matrix - Musical Gesture Conversion' do
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
end
