require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Transcription::Transcriptor do
  context 'GDV transcriptors' do
    include Musa::Series

    it 'Neuma parsing with staccato extended notation' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas    = '(0 1 mf) (+1 st) (. st(1)) (. st(2)) (. st(3)) (. st(4))'

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      transcriptor = Musa::Transcription::Transcriptor.new [ Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new(min_duration_factor: 1/6r) ]

      result_gdv = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| transcriptor.transcript(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, note_duration: 1/8r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, note_duration: 1/8r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, note_duration: 1/16r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, note_duration: 1/24r)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1, note_duration: 1/24r)
    end

    it 'Neuma parsing with basic trill extended notation' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas    = '(0 1 mf) (+1 tr)'

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      transcriptor = Musa::Transcription::Transcriptor.new \
            [ Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new,
                          Musa::Transcriptors::FromGDV::ToMIDI::Trill.new(duration_factor: 1/6r) ],
            base_duration: 1/4r,
            tick_duration: 1/96r

        result_gdv = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| transcriptor.transcript(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
    end

    it 'Neuma parsing with mordent extended notation' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas = '(0 1 mf) (+1 mor) (+3 +1 mor(low))'

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      transcriptor = Musa::Transcription::Transcriptor.new \
        [ Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Trill.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Mordent.new(duration_factor: 1/6r) ],
        base_duration: 1/4r,
        tick_duration: 1/96r

      result_gdv = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| transcriptor.transcript(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 2, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 4/24r, velocity: 1)

      expect(result_gdv[c += 1]).to eq(grade: 4, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, octave: 0, duration: 1/24r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 4, octave: 0, duration: 10/24r, velocity: 1)
    end

    it 'Neuma parsing with mute extended notation' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas = '(0 1 mf) (+1) (5 base) (+2)'

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      decorators = Musa::Transcription::Transcriptor.new [ Musa::Transcriptors::FromGDV::Base.new ],
                                    base_duration: 1/4r,
                                    tick_duration: 1/96r

      result_gdv = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| decorators.transcript(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(duration: 0)
      expect(result_gdv[c += 1]).to eq(grade: 7, octave: 0, duration: 1/4r, velocity: 1)

    end

    it 'Modifiers extended neumas parsing with sequencer play' do
      debug = false
      #debug = true

      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas = '(0 1 mf) (+1 mor) (+3 +1 mor(low)) (-2)'

      transcriptor = Musa::Transcription::Transcriptor.new \
        [ Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Trill.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Mordent.new(duration_factor: 1/8r) ],
         base_duration: 1/4r,
         tick_duration: 1/96r

      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale, transcriptor: transcriptor, base_duration: 1/4r

      serie = Musa::Neumalang::Neumalang.parse(neumas)

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer::Sequencer.new 4, 24 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            if debug
              played[position] ||= []
              played[position] << gdv
            else
              played << { position: position }
              played << gdv
            end
          end

          handler.on :event do
            if debug
              played[position] ||= []
              played[position] << [:event]
            else
              played << { position: position }
              played << [:event]
            end
          end
        end
      end

      sequencer.tick until sequencer.empty?

      if debug
        puts
        puts 'PLAYED'
        puts '------'
        pp played
      end

      unless debug
        expect(played).to eq(
        [{ position: 1 },
         { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
         { position: 1+1/4r },
         { grade: 1, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+9/32r },
         { grade: 2, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+5/16r },
         { grade: 1, octave: 0, duration: 3/16r, velocity: 1 },
         { position: 1+1/2r },
         { grade: 4, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+17/32r },
         { grade: 3, octave: 0, duration: 1/32r, velocity: 1 },
         { position: 1+9/16r },
         { grade: 4, octave: 0, duration: 14/32r, velocity: 1 },
         { position: 2 },
         { grade: 2, octave: 0, duration: 1/2r, velocity: 1 }])
      end
    end

    it 'Modifier .base extended neumas parsing with sequencer play' do
      debug = false
      #debug = true

      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas = '(0 1 mf) (+1 *2) (5 b) (+2)'

      transcriptor = Musa::Transcription::Transcriptor.new \
        [ Musa::Transcriptors::FromGDV::Base.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Trill.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Mordent.new(duration_factor: 1/8r) ],
        base_duration: 1/4r,
        tick_duration: 1/96r

      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale, transcriptor: transcriptor, base_duration: 1/4r

      serie = Musa::Neumalang::Neumalang.parse(neumas)

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer::Sequencer.new 4, 24 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            if debug
              played[position] ||= []
              played[position] << gdv
            else
              played << { position: position }
              played << gdv
            end
          end

          handler.on :event do
            if debug
              played[position] ||= []
              played[position] << [:event]
            else
              played << { position: position }
              played << [:event]
            end
          end
        end
      end

      sequencer.tick until sequencer.empty?

      if debug
        puts
        puts 'PLAYED'
        puts '------'
        pp played
      end

      unless debug
        expect(played).to eq(
                              [{ position: 1 },
                               { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 1+1/4r },
                               { grade: 1, octave: 0, duration: 2/4r, velocity: 1 },
                               { position: 1+3/4r },
                               { duration: 0 },
                               { position: 1+3/4r },
                               { grade: 7, octave: 0, duration: 2/4r, velocity: 1 }])
      end
    end

    it 'Neuma parsing with apoggiatura extended notation' do
      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas = '(0 1 mf) (+1) <(+2 //)>(+3) (0)'

      result = Musa::Neumalang::Neumalang.parse(neumas).to_a(recursive: true)

      decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale

      transcriptor = Musa::Transcription::Transcriptor.new \
        [ Musa::Transcriptors::FromGDV::ToMIDI::Appogiatura.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Staccato.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Trill.new,
          Musa::Transcriptors::FromGDV::ToMIDI::Mordent.new ],
        base_duration: 1/4r,
        tick_duration: 1/96r

      result_gdv = Musa::Neumalang::Neumalang.parse(neumas, decode_with: decoder).process_with { |gdv| transcriptor.transcript(gdv) }.to_a(recursive: true)

      c = -1

      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 1, octave: 0, duration: 1/4r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 3, octave: 0, duration: 1/16r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 4, octave: 0, duration: 3/16r, velocity: 1)
      expect(result_gdv[c += 1]).to eq(grade: 0, octave: 0, duration: 1/4r, velocity: 1)
    end

    it 'Appogiatura extended neumas parsing with sequencer play' do
      debug = false
      #debug = true

      scale = Musa::Scales::Scales.et12[440.0].major[60]

      neumas = '[(0 1 mf) (+1) <(+2 //)>(+3) (0) (+1)]'

      transcriptor = Musa::Transcription::Transcriptor.new Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
        base_duration: 1/4r,
        tick_duration: 1/96r

      gdv_decoder = Musa::Neumas::Decoders::NeumaDecoder.new scale, transcriptor: transcriptor, base_duration: 1/4r

      serie = Musa::Neumalang::Neumalang.parse(neumas)

      if debug
        puts
        puts 'SERIE'
        puts '-----'
        pp serie.to_a(recursive: true)
        puts
      end

      played = {} if debug
      played = [] unless debug

      sequencer = Musa::Sequencer::Sequencer.new 4, 24 do
        at 1 do
          handler = play serie, decoder: gdv_decoder, mode: :neumalang do |gdv|
            if debug
              played[position] ||= []
              played[position] << gdv
            else
              played << { position: position }
              played << gdv
            end
          end

          handler.on :event do
            if debug
              played[position] ||= []
              played[position] << [:event]
            else
              played << { position: position }
              played << [:event]
            end
          end
        end
      end

      sequencer.tick until sequencer.empty?

      if debug
        puts
        puts 'PLAYED'
        puts '------'
        pp played
      end

      unless debug
        expect(played).to eq(
                              [{ position: 1 },
                               { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 1+1/4r },
                               { grade: 1, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 1+1/2r },
                               { grade: 3, octave: 0, duration: 1/16r, velocity: 1 },
                               { position: 1+9/16r },
                               { grade: 4, octave: 0, duration: 3/16r, velocity: 1 },
                               { position: 1+3/4r },
                               { grade: 0, octave: 0, duration: 1/4r, velocity: 1 },
                               { position: 2 },
                               { grade: 1, octave: 0, duration: 1/4r, velocity: 1 }])
      end
    end
  end
end
