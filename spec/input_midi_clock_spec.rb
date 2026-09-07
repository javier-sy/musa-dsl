require 'spec_helper'

require 'musa-dsl'

# How a DAW's transport messages reach the clock, and how they are grouped.
#
# The grouping is the variable under test. InputMidiClock reads whatever one
# call to the input's `gets` returns, and how many messages that is depends on
# the platform: Core MIDI delivers packet lists that can carry several, WinMM
# raises one notification per short message. Nothing musical depends on it, so
# nothing in the clock should either -- which is exactly what went wrong.
RSpec.describe Musa::Clock::InputMidiClock do
  # An input satisfying the contract the clock relies on: `gets` blocks until
  # something arrives, then returns every message that accumulated.
  class BatchedInput
    def initialize
      @batches = Queue.new
    end

    def name
      'fake input'
    end

    # One call, one batch, however many messages are in it.
    def push(*messages)
      @batches << messages.map { |bytes| { data: bytes, timestamp: Time.now.to_f } }
    end

    def gets
      @batches.pop
    end
  end

  STOP = [0xFC].freeze
  SONG_POSITION = [0xF2, 0x00, 0x00].freeze
  CONTINUE = [0xFB].freeze
  START = [0xFA].freeze
  CLOCK = [0xF8].freeze

  let(:input) { BatchedInput.new }
  let(:clock) { described_class.new(input) }

  before do
    @starts = 0
    @ticks = 0

    clock.on_start { @starts += 1 }
    @thread = Thread.new { clock.run { @ticks += 1 } }
  end

  after do
    clock.terminate
    input.push # an empty batch, so the reader wakes and sees it should stop
    @thread.join(2)
  end

  # The clock runs in its own thread; give it a moment to catch up rather than
  # a fixed sleep, so the suite is neither flaky nor slow.
  def eventually(seconds = 2)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + seconds
    sleep 0.002 until yield || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    yield
  end

  # Starting is only worth anything if the ticks that follow are counted. A test
  # that checked on_start alone would have passed on the broken code for the
  # single-batch case and told us nothing about the others.
  def expect_running
    expect(eventually { @starts == 1 }).to be true

    before = @ticks
    3.times { input.push(CLOCK) }

    expect(eventually { @ticks >= before + 3 }).to be true
  end

  context 'a reposition: Stop, Song Position Pointer and Continue' do
    it 'starts when the three arrive in one read' do
      input.push(STOP, SONG_POSITION, CONTINUE)

      expect_running
    end

    it 'starts when the Stop arrives on its own' do
      input.push(STOP)
      input.push(SONG_POSITION, CONTINUE)

      expect_running
    end

    it 'starts when all three arrive separately' do
      input.push(STOP)
      input.push(SONG_POSITION)
      input.push(CONTINUE)

      expect_running
    end

    it 'reports the position it was told to move to' do
      positions = []
      clock.on_change_position { |midi_beats:| positions << midi_beats }

      input.push(STOP)
      input.push([0xF2, 0x10, 0x00], CONTINUE)

      expect(eventually { positions == [0x10] }).to be true
    end
  end

  context 'a plain Start' do
    it 'starts, whatever else shares its read' do
      input.push(START)

      expect_running
    end
  end

  context 'a Continue with nothing before it' do
    # The decision this test fixes: a Continue while stopped is a start. There is
    # nothing else it could reasonably mean, and a DAW that sends Continue
    # without a preceding Stop is not obliged to explain itself.
    it 'starts' do
      input.push(CONTINUE)

      expect_running
    end
  end

  context 'before anything has started it' do
    it 'ignores the ticks' do
      10.times { input.push(CLOCK) }

      # Nothing to wait for: assert that after the clock has had time to read
      # them, none was counted.
      sleep 0.1

      expect(@ticks).to eq 0
      expect(@starts).to eq 0
    end
  end
end
