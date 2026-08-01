require 'spec_helper'
require 'musa-dsl'

# The pitfalls the Nota plugin's always-in-context reference warns about.
#
# WHY THESE LIVE IN A SPEC. A warning is the strongest thing a reference can
# say: it is read as settled and copied without checking, and emphasis
# multiplies whatever it is applied to. Three of the sixteen warnings in that
# list turned out to be false -- `RND()` announced as infinite when it is a
# shuffle that exhausts, `duration: nil` offered as the way to hold a note when
# it raises, series constructors declared unavailable inside DSL blocks where
# they work -- and each had been sitting there being trusted.
#
# So the rule is now: every pitfall cites the example here that demonstrates it,
# and one that cannot be demonstrated does not go in the list. A warning with no
# spec behind it is a conjecture with typography.
#
# NOTE: this file deliberately does NOT declare `using Musa::Extension::Neumas`
# at the top, because the first pitfall is about that refinement being
# file-scoped and could not be shown otherwise.
RSpec.describe 'Pitfalls warned about in the reference' do
  include Musa::All

  let(:scale) { Musa::Scales::Scales.et12[440.0].major[60] }

  it 'refinements are file-scoped, so .to_neumas is absent where `using` is not written' do
    expect { '(0) (+2)'.to_neumas }.to raise_error(NoMethodError, /to_neumas/)
  end

  it 'a serie is lazy: a prototype cannot be read, and to_a restarts the instance' do
    serie = Musa::Series::Constructors.S(1, 2, 3)

    expect(serie).not_to respond_to(:each)
    expect { serie.next_value }
      .to raise_error(Musa::Series::Serie::Prototyping::PrototypingError)

    instance = serie.i
    instance.next_value

    # to_a does not continue from where next_value left off: it starts again.
    expect(instance.to_a).to eq([1, 2, 3])
  end

  it 'neuma durations are multiples of base_duration, not fractions of a bar' do
    quarters = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)
    bars = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1r)

    duration = lambda do |decoder|
      Musa::Neumalang::Neumalang.parse('(0 1)', decode_with: decoder)
                                .to_a(recursive: true).first[:duration]
    end

    # The same `1` is a quarter under one base duration and a whole bar under
    # the other. It is a count of base_durations, never a fraction of a bar.
    expect(duration.call(quarters)).to eq(1/4r)
    expect(duration.call(bars)).to eq(1r)
  end

  it 'a Float position is quantised to the tick grid, a Rational is not' do
    sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
    fired = []

    sequencer.at(1.3) { fired << sequencer.position }
    200.times { sequencer.tick }

    # 1.3 is not on the grid of 96ths, so it lands on the nearest tick.
    expect(fired).to eq([125/96r])
    expect(125/96r.to_f).to be_within(0.005).of(1.302)
  end

  it 'without a transcriptor an ornament survives as an annotation and expands into nothing' do
    decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale, base_duration: 1/4r)
    transcriptor = Musa::Transcription::Transcriptor.new(
      Musa::Transcriptors::FromGDV::ToMIDI.transcription_set,
      base_duration: 1/4r, tick_duration: 1/96r
    )

    without = Musa::Neumalang::Neumalang.parse('(0 1) (+2 1 tr)', decode_with: decoder)
                                        .to_a(recursive: true)

    # Two events, and the trill is still sitting there as a flag nobody read.
    expect(without.size).to eq(2)
    expect(without.last[:tr]).to be true

    with = Musa::Neumalang::Neumalang.parse('(0 1) (+2 1 tr)', decode_with: decoder)
                                     .process_with { |gdv| transcriptor.transcript(gdv) }
                                     .to_a(recursive: true)

    expect(with.size).to eq(5)
  end

  it 'after fires on natural completion, on_stop on any ending including a manual stop' do
    sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
    serie = Musa::Series::Constructors.S({ pitch: 60, duration: 1r }, { pitch: 62, duration: 1r })

    afters = []
    stops = []

    control = sequencer.play(serie) { |pitch:, duration:| }
    control.after { afters << :fired }
    control.on_stop { stops << :fired }

    control.stop
    400.times { sequencer.tick }

    expect(stops).to eq([:fired])
    expect(afters).to be_empty
  end

  it 'MIDI channels are 0-indexed' do
    sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    output = [].tap { |sent| def sent.puts(message) = self << message }

    voices = Musa::MIDIVoices::MIDIVoices.new(
      sequencer: sequencer, output: output, channels: 0..15
    )

    expect(voices.voices.size).to eq(16)
    expect(voices.voices.collect(&:channel)).to eq((0..15).to_a)
  end

  it 'play in its default mode needs a :duration on every element' do
    sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)

    positions = []
    control = sequencer.play(Musa::Series::Constructors.S({ pitch: 60 }, { pitch: 62 })) do |pitch:|
      positions << sequencer.position
    end

    stopped = []
    control.on_stop { stopped << :fired }

    400.times { sequencer.tick }

    # Without durations everything happens in the same instant and the control
    # never completes, so `after` and `on_stop` never run (issue #72).
    expect(positions).to eq([95/96r, 95/96r])
    expect(stopped).to be_empty
  end

  it 'RND is a shuffle that exhausts; repeat is what samples with replacement' do
    shuffled = Musa::Series::Constructors.RND(1, 2, 3, 4, 5, 6, random: 42)

    expect(shuffled.infinite?).to be false
    expect(shuffled.i.to_a).to eq([4, 6, 3, 5, 2, 1])

    instance = shuffled.i
    6.times { instance.next_value }
    expect(instance.next_value).to be_nil

    expect(Musa::Series::Constructors.RND(1, 2, 3, random: 42).repeat.infinite?).to be true
  end

  it 'FIBO starts at 1, and its seeds are its first two values' do
    expect(Musa::Series::Constructors.FIBO().i.max_size(8).to_a).to eq([1, 1, 2, 3, 5, 8, 13, 21])
    expect(Musa::Series::Constructors.FIBO(0, 1).i.max_size(8).to_a).to eq([0, 1, 1, 2, 3, 5, 8, 13])
  end

  it 'move takes every: as a keyword, not as a positional argument' do
    sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)

    expect { sequencer.move(1/4r, from: 0, to: 10, duration: 1r) { } }
      .to raise_error(ArgumentError, /wrong number of arguments/)

    values = []
    sequencer.move(every: 1/4r, from: 0, to: 12, duration: 1r) { |value| values << value }
    400.times { sequencer.tick }

    expect(values.first).to eq(0)
    expect(values.last).to eq(12)
  end

  it 'a note with no duration sounds until it is released by hand' do
    sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    output = [].tap { |sent| def sent.puts(message) = self << message }
    voice = Musa::MIDIVoices::MIDIVoices.new(
      sequencer: sequencer, output: output, channels: [0]
    ).voices.first

    control = voice.note(60, duration: nil)
    400.times { sequencer.tick }

    expect(output.size).to eq(1)
    expect(control.active?).to be true

    control.note_off

    expect(output.size).to eq(2)
  end

  it 'series constructors DO work inside a DSL block, contrary to the old warning' do
    sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    collected = []

    sequencer.with do
      serie = Musa::Series::Constructors.S(1, 2, 3)
      at(1) { collected.concat(serie.i.to_a) }
    end

    200.times { sequencer.tick }

    expect(collected).to eq([1, 2, 3])
  end
end
