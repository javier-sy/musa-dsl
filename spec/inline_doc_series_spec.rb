require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Series Inline Documentation Examples' do
  include Musa::All

  context 'Constructors (main-serie-constructors.rb)' do
    it '@example Undefined placeholder' do
      proxy = PROXY()  # Uses UNDEFINED internally
      expect(proxy.undefined?).to be true
    end

    it '@example Nil serie' do
      s = NIL().i
      expect(s.next_value).to be_nil
      expect(s.next_value).to be_nil
    end

    it '@example Basic array' do
      notes = S(60, 64, 67, 72)
      expect(notes.i.to_a).to eq([60, 64, 67, 72])
    end

    it '@example With ranges' do
      scale = S(60..67)
      expect(scale.i.to_a).to eq([60, 61, 62, 63, 64, 65, 66, 67])
    end

    it '@example Hash of series' do
      h = H(pitch: S(60, 64, 67), velocity: S(96, 80, 64))
      inst = h.i
      expect(inst.next_value).to eq({pitch: 60, velocity: 96})
      expect(inst.next_value).to eq({pitch: 64, velocity: 80})
    end

    it '@example Combined cycling all series' do
      hc = HC(a: S(1, 2), b: S(10, 20, 30))
      result = hc.max_size(6).i.to_a
      expect(result).to eq([{a:1, b:10}, {a:2, b:20}, {a:1, b:30},
                            {a:2, b:10}, {a:1, b:20}, {a:2, b:30}])
    end

    it '@example Array of series' do
      a = A(S(1, 2, 3), S(10, 20, 30))
      inst = a.i
      expect(inst.next_value).to eq([1, 10])
      expect(inst.next_value).to eq([2, 20])
    end

    it '@example Combined cycling all series' do
      ac = AC(S(1, 2), S(10, 20, 30))
      result = ac.max_size(6).i.to_a
      expect(result).to eq([[1, 10], [2, 20], [1, 30],
                            [2, 10], [1, 20], [2, 30]])
    end

    it '@example Carrying state of its own, in `parameters`' do
      counter = E(1) { |v, last_value:| (last_value || v) + 1 unless (last_value || v) >= 5 }
      expect(counter.i.to_a).to eq([2, 3, 4, 5])
    end

    it 'E can carry state across calls in caller.parameters' do
      fib = E { |last_value:, caller:|
        a, b = caller.parameters
        caller.parameters = [b, a + b]
        a
      }
      fib.parameters = [0, 1]
      result = []
      inst = fib.i
      10.times { result << inst.next_value }
      expect(result).to eq([0, 1, 1, 2, 3, 5, 8, 13, 21, 34])
    end

    it '@example Ascending sequence' do
      s = FOR(from: 0, to: 10, step: 2)
      expect(s.i.to_a).to eq([0, 2, 4, 6, 8, 10])
    end

    it '@example Descending sequence' do
      s = FOR(from: 10, to: 0, step: 2)
      expect(s.i.to_a).to eq([10, 8, 6, 4, 2, 0])
    end

    it '@example Infinite sequence' do
      s = FOR(from: 0, step: 1)  # to: nil
      expect(s.infinite?).to be true
    end

    it '@example Shuffling an array' do
      # A shuffle, not a die: every value comes out exactly once and then the
      # serie ends. Membership was all that was asserted here, and membership is
      # true of a die too -- it is the part that does not distinguish them.
      shuffled = RND(1, 2, 3, 4, 5, 6, random: 42)

      expect(shuffled.i.to_a).to eq([4, 6, 3, 5, 2, 1])
      expect(shuffled.infinite?).to be false

      instance = shuffled.i
      6.times { instance.next_value }
      expect(instance.next_value).to be_nil
    end

    it 'sampling with replacement is RND().repeat' do
      die = RND(1, 2, 3, random: 42).repeat

      expect(die.infinite?).to be true

      instance = die.i
      # Reshuffled on each pass, so values do repeat across passes.
      expect(9.times.collect { instance.next_value }).to eq([3, 2, 1, 1, 2, 3, 3, 2, 1])
    end

    it '@example Random from range' do
      expect(RND(from: 0, to: 10, step: 5, random: 7).i.to_a).to eq([0, 10, 5])
    end

    it '@example With seed' do
      # The claim is reproducibility, so assert it: same seed, same sequence.
      expect(RND(1, 2, 3, random: 42).i.to_a).to eq([3, 2, 1])
      expect(RND(1, 2, 3, random: 42).i.to_a).to eq([3, 2, 1])
    end

    it '@example Merge sequences' do
      merged = MERGE(S(1, 2, 3), S(10, 20, 30))
      expect(merged.i.to_a).to eq([1, 2, 3, 10, 20, 30])
    end

    it '@example Single random value' do
      rnd = RND1(1, 2, 3, 4, 5)
      inst = rnd.i
      first_value = inst.next_value
      expect([1, 2, 3, 4, 5]).to include(first_value)
      expect(inst.next_value).to be_nil  # exhausted
    end

    it '@example Basic sine wave' do
      wave = SIN(steps: 8, amplitude: 10, center: 50)
      result = wave.i.to_a

      # One full period in 8 steps, starting and crossing the centre: the shape
      # is the claim, not that the values happen to be numbers.
      expect(result.collect { |v| v.round(6) })
        .to eq([50.0, 53.535534, 55.0, 53.535534, 50.0, 46.464466, 45.0, 46.464466])
    end

    it '@example Fibonacci numbers' do
      fib = FIBO()
      expect(fib.infinite?).to be true
      inst = fib.i
      result = []
      10.times { result << inst.next_value }

      expect(result).to eq([1, 1, 2, 3, 5, 8, 13, 21, 34, 55])
    end

    it '@example Harmonic series' do
      harmonics = HARMO(error: 0.5)
      expect(harmonics.infinite?).to be true

      inst = harmonics.i
      expect(8.times.map { inst.next_value }).to eq [0, 12, 19, 24, 28, 31, 34, 36]
    end

    it 'HARMO: a tighter tolerance drops the harmonics that fall between semitones' do
      inst = HARMO(error: 0.1).i
      expect(8.times.map { inst.next_value }).to eq [0, 12, 19, 24, 31, 36, 38, 43]
    end

    it 'HARMO: extended yields the same pitches, carrying their error' do
      plain = HARMO(error: 0.5).i
      extended = HARMO(error: 0.5, extended: true).i

      plain_values = 8.times.map { plain.next_value }
      extended_values = 8.times.map { extended.next_value }

      expect(extended_values.map { |v| v[:pitch] }).to eq plain_values
      expect(extended_values[0]).to eq({ pitch: 0, error: 0.0 })
      expect(extended_values[4][:error]).to be_within(0.001).of(-0.1369)
    end
  end

  context 'Operations (main-serie-operations.rb)' do
    it 'Infinite loop' do
      pattern = S(1, 2, 3).autorestart
      inst = pattern.i
      result = []
      9.times do
        val = inst.next_value
        result << val unless val.nil?
      end
      expect(result.size).to be >= 6
      expect(result[0..2]).to eq([1, 2, 3])
    end

    it '@example Fixed repetitions' do
      s = S(1, 2, 3).repeat(3)
      expect(s.i.to_a).to eq([1, 2, 3, 1, 2, 3, 1, 2, 3])
    end

    it '@example Conditional repeat' do
      count = 0
      s = S(1, 2, 3).repeat { (count += 1) < 3 }
      result = s.i.to_a
      expect(result).to eq([1, 2, 3, 1, 2, 3, 1, 2, 3])
    end

    it '@example Infinite repeat' do
      s = S(1, 2, 3).repeat
      expect(s.infinite?).to be true
    end

    it '@example Limit to 5' do
      s = FOR(from: 0, step: 1).max_size(5)
      expect(s.i.to_a).to eq([0, 1, 2, 3, 4])
    end

    it '@example Skip first 2' do
      s = S(1, 2, 3, 4, 5).skip(2)
      expect(s.i.to_a).to eq([3, 4, 5])
    end

    it '@example Flatten nested' do
      s = S(S(1, 2), S(3, 4), 5).flatten
      expect(s.i.to_a).to eq([1, 2, 3, 4, 5])
    end

    it '@example Array to hash' do
      s = S([60, 96], [64, 80]).hashify(:pitch, :velocity)
      inst = s.i
      expect(inst.next_value).to eq({pitch: 60, velocity: 96})
    end

    it '@example Transpose notes' do
      # shift operation rotates elements in series
      s = S(60, 64, 67).shift(-1)  # Rotate left by 1
      result = s.i.to_a
      expect(result).to eq([64, 67, 60])  # First element moved to end
    end

    it '@example Retrograde' do
      s = S(1, 2, 3, 4).reverse
      expect(s.i.to_a).to eq([4, 3, 2, 1])
    end

    it '@example Shuffle' do
      s = S(1, 2, 3, 4, 5).randomize
      result = s.i.to_a
      expect(result.size).to eq(5)
      expect(result.sort).to eq([1, 2, 3, 4, 5])
    end

    it '@example The same seed is the same shuffle' do
      expect(S(1, 2, 3, 4, 5).randomize(random: 7).i.to_a).to eq([5, 2, 4, 3, 1])
      expect(S(1, 2, 3, 4, 5).randomize(random: 7).i.to_a).to eq([5, 2, 4, 3, 1])
    end

    it '@example Remove odds' do
      s = S(1, 2, 3, 4, 5).remove { |n| n.odd? }
      expect(s.i.to_a).to eq([2, 4])
    end

    it '@example Select evens' do
      s = S(1, 2, 3, 4, 5).select { |n| n.even? }
      expect(s.i.to_a).to eq([2, 4])
    end

    it '@example Two materials taking turns, each continuing where it left off' do
      question = S(:q1, :q2, :q3)
      answer   = S(:a1, :a2)

      expect(S(0, 1, 0, 1, 0).switch(question, answer).i.to_a).to eq %i[q1 a1 q2 a2 q3]
    end

    it '@example Append' do
      s = S(1, 2).after(S(3, 4), S(5, 6))
      expect(s.i.to_a).to eq([1, 2, 3, 4, 5, 6])
    end

    it '@example Concatenate' do
      s = S(1, 2) + S(3, 4)
      expect(s.i.to_a).to eq([1, 2, 3, 4])
    end

    it '@example Cut into pairs' do
      s = S(1, 2, 3, 4, 5, 6).cut(2)
      inst = s.i
      result = []
      while (chunk = inst.next_value)
        result << chunk.i.to_a
      end
      expect(result).to eq([[1, 2], [3, 4], [5, 6]])
    end

    it '@example Merge phrases' do
      phrases = S(S(1, 2, 3), S(4, 5, 6))
      merged = phrases.merge
      expect(merged.i.to_a).to eq([1, 2, 3, 4, 5, 6])
    end

    it '@example Combine pitches and velocities' do
      pitches = S(60, 64, 67)
      velocities = S(96, 80, 64)
      notes = pitches.with(velocities, isolate_values: false) { |p, v| {pitch: p, velocity: v} }
      expect(notes.i.to_a).to eq([{pitch: 60, velocity: 96},
                                  {pitch: 64, velocity: 80},
                                  {pitch: 67, velocity: 64}])
    end

    it '@example Named series' do
      melody = S(60, 64, 67)
      rhythm = S(1r, 0.5r, 0.5r)
      combined = melody.with(duration: rhythm) { |pitch, duration:|
        {pitch: pitch, duration: duration}
      }
      expect(combined.i.to_a).to eq([{pitch: 60, duration: 1r},
                                      {pitch: 64, duration: 0.5r},
                                      {pitch: 67, duration: 0.5r}])
    end

    it '@example Transpose notes' do
      notes = S(60, 64, 67).map { |n| n + 12 }
      expect(notes.i.to_a).to eq([72, 76, 79])
    end

    it '@example Smooth transitions' do
      s = S(1, 5, 3, 8).anticipate { |prev, current, next_val|
        next_val ? (current + next_val) / 2.0 : current
      }
      result = s.i.to_a
      expect(result).to be_an(Array)
      expect(result.size).to eq(4)
    end

    it '@example Add interval information' do
      notes = S(60, 64, 67, 72).anticipate { |prev, pitch, next_pitch|
        interval = next_pitch ? next_pitch - pitch : nil
        {pitch: pitch, interval: interval}
      }
      result = notes.i.to_a
      expect(result.size).to eq(4)
      expect(result[0]).to eq({pitch: 60, interval: 4})
      expect(result[-1][:interval]).to be_nil
    end
  end

  context 'Base Series (base-series.rb)' do
    it '@example Create instances' do
      proto = S(1, 2, 3)
      a = proto.instance
      b = proto.instance  # Different instance

      expect(a.next_value).to eq(1)
      expect(b.next_value).to eq(1)  # independent
    end

    it '@example Peek ahead' do
      s = S(1, 2, 3).i
      expect(s.peek_next_value).to eq(1)
      expect(s.peek_next_value).to eq(1)  # same
      expect(s.next_value).to eq(1)
      expect(s.peek_next_value).to eq(2)
    end

    it '@example Track current' do
      s = S(1, 2, 3).i
      expect(s.current_value).to be_nil
      s.next_value  # => 1
      expect(s.current_value).to eq(1)
    end

    it '@example Basic conversion' do
      proto = S(1, 2, 3)
      expect(proto.to_a).to eq([1, 2, 3])
    end

    it '@example Preserve instance' do
      inst = S(1, 2, 3).i
      original_values = inst.to_a(duplicate: true)  # Consumes copy, inst unchanged
      expect(original_values).to eq([1, 2, 3])
      # inst should still be at beginning after duplicate: true
      expect(inst.next_value).to eq(1)
    end

    it '@example Recursive conversion' do
      s = S(S(1, 2), S(3, 4))
      result = s.to_a(recursive: true)
      expect(result).to eq([[1, 2], [3, 4]])
    end

    it '@example Restart series' do
      s = S(1, 2, 3).i
      expect(s.next_value).to eq(1)
      expect(s.next_value).to eq(2)
      s.restart
      expect(s.next_value).to eq(1)
    end

    it '@example Basic iteration' do
      s = S(1, 2, 3).i
      expect(s.next_value).to eq(1)
      expect(s.next_value).to eq(2)
      expect(s.next_value).to eq(3)
      expect(s.next_value).to be_nil
    end
  end

  context 'Array to Serie (array-to-serie.rb)' do
    it '@example Basic conversion' do
      result = [60, 64, 67].to_serie.i.to_a
      expect(result).to eq([60, 64, 67])
    end

    it '@example Serie of series' do
      result = [[1, 2], [3, 4]].to_serie(of_series: true)
      # Each [1,2], [3,4] becomes S(1,2), S(3,4)
      inst = result.i
      chunk1 = inst.next_value
      expect(chunk1.i.to_a).to eq([1, 2])
    end

    it '@example Recursive conversion' do
      result = [[1, [2, 3]], [4, 5]].to_serie(recursive: true)
      inst = result.i

      # Nesting goes all the way down: the first element is a serie holding a
      # value and another serie.
      first = inst.next_value.i.to_a

      expect(first.first).to eq(1)
      expect(first.last.i.to_a).to eq([2, 3])

      expect(inst.next_value.i.to_a).to eq([4, 5])
    end

    it '@example Short form' do
      result = [1, 2, 3].s  # => S(1, 2, 3)
      expect(result.i.to_a).to eq([1, 2, 3])
    end
  end

  context 'Buffer Serie (buffer-serie.rb)' do
    it '@example Multiple independent readers' do
      source = S(1, 2, 3, 4).buffered
      reader1 = source.buffer.i
      reader2 = source.buffer.i

      expect(reader1.next_value).to eq(1)
      expect(reader2.next_value).to eq(1)  # independent
      expect(reader1.next_value).to eq(2)
      expect(reader2.next_value).to eq(2)
    end

    it '@example Create buffered serie' do
      buffered = S(1, 2, 3, 4).buffered
      reader1 = buffered.buffer.i
      reader2 = buffered.buffer.i

      expect(reader1.next_value).to eq(1)
      expect(reader2.next_value).to eq(1)
    end
  end

  context 'Splitter (hash-or-array-serie-splitter.rb)' do
    it '@example Split hash values' do
      notes = S({pitch: 60, vel: 96}, {pitch: 64, vel: 80})
      splitter = notes.split.i

      pitches = splitter[:pitch]
      velocities = splitter[:vel]

      expect(pitches.next_value).to eq(60)
      expect(velocities.next_value).to eq(96)
    end

    it 'Split components' do
      splitter = S({a: 1, b: 2}, {a: 3, b: 4}).split.i
      expect(splitter[:a].to_a).to eq([1, 3])
      expect(splitter[:b].to_a).to eq([2, 4])
    end
  end

  context 'Proxy Serie (proxy-serie.rb)' do
    it '@example Forward reference' do
      proxy = PROXY()
      expect(proxy.undefined?).to be true

      # Define later
      proxy.proxy_source = S(1, 2, 3)
      expect(proxy.prototype?).to be true
    end

    it 'Empty proxy' do
      proxy = PROXY()

      expect(proxy.undefined?).to be true
      expect(proxy.prototype?).to be false
      expect(proxy.instance?).to be false

      proxy.proxy_source = S(1, 2, 3)

      expect(proxy.prototype?).to be true
      expect(proxy.i.to_a).to eq([1, 2, 3])
    end

    it '@example With initial source' do
      proxy = PROXY(S(1, 2, 3))
      expect(proxy.i.to_a).to eq([1, 2, 3])
    end
  end

  context 'Queue Serie (queue-serie.rb)' do
    it '@example Basic queue' do
      queue = QUEUE(S(1, 2, 3)).i
      expect(queue.next_value).to eq(1)
      queue << S(4, 5, 6).i  # Add dynamically
      remaining = []
      while (v = queue.next_value)
        remaining << v
      end
      expect(remaining).to eq([2, 3, 4, 5, 6])
    end

    it 'Create queue' do
      queue = QUEUE(S(1, 2), S(3, 4))
      expect(queue.i.to_a).to eq([1, 2, 3, 4])
    end
  end

  context 'Quantizer Serie (quantizer-serie.rb)' do
    it '@example Basic quantization' do
      # Quantize to semitones (12 steps per octave)
      pitch_bend = S({time: 0r, value: 60.3}, {time: 1r, value: 61.8})
        .map { |v| v.extend(Musa::Datasets::AbsTimed) }
      quantized = pitch_bend.quantize(step: 1)
      result = quantized.i.to_a

      # Two points in, two steps out -- and the second one starts halfway,
      # because that is where the ramp crosses into the next semitone.
      expect(result).to eq [{ time: 0r, value: 60r, duration: 1/2r },
                            { time: 1/2r, value: 61r, duration: 1/2r }]
    end

    it 'Quantize to integers' do
      serie = S({time: 0r, value: 1.3}, {time: 1r, value: 2.7})
        .map { |v| v.extend(Musa::Datasets::AbsTimed) }
      quantized = serie.quantize(step: 1)
      result = quantized.i.to_a

      # The values come out exact, as Rationals, and each step carries the
      # duration it holds -- it is a staircase, not a list of samples.
      expect(result).to eq [{ time: 0r, value: 1r, duration: 1/2r },
                            { time: 1/2r, value: 2r, duration: 1/2r }]
      expect(result.first[:value]).to be_a Rational
    end
  end

  context 'Integration tests' do
    it 'chains multiple operations correctly' do
      result = S(1, 2, 3, 4, 5, 6)
        .select { |n| n.even? }
        .map { |n| n * 10 }
        .repeat(2)
        .i.to_a

      expect(result).to eq([20, 40, 60, 20, 40, 60])
    end

    it 'handles nested series properly' do
      outer = S(S(1, 2), S(3, 4), S(5, 6))
      inst = outer.i

      chunk1 = inst.next_value
      expect(chunk1.i.to_a).to eq([1, 2])

      chunk2 = inst.next_value
      expect(chunk2.i.to_a).to eq([3, 4])

      chunk3 = inst.next_value
      expect(chunk3.i.to_a).to eq([5, 6])
    end

    it 'maintains independent instance state' do
      proto = S(1, 2, 3)
      inst1 = proto.i
      inst2 = proto.i

      expect(inst1.next_value).to eq(1)
      expect(inst1.next_value).to eq(2)

      expect(inst2.next_value).to eq(1)
      expect(inst2.next_value).to eq(2)
    end

    it 'handles infinite series with max_size' do
      infinite = FOR(from: 0, step: 1)
      limited = infinite.max_size(10)

      result = limited.i.to_a
      expect(result).to eq([0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
    end

    it 'combines H and with operations' do
      pitches = S(60, 64, 67)
      durations = S(1r, 0.5r, 0.5r)
      velocities = S(96, 80, 64)

      notes = H(pitch: pitches, duration: durations, velocity: velocities)
      result = notes.i.to_a

      expect(result.size).to eq(3)
      expect(result[0]).to eq({pitch: 60, duration: 1r, velocity: 96})
      expect(result[1]).to eq({pitch: 64, duration: 0.5r, velocity: 80})
      expect(result[2]).to eq({pitch: 67, duration: 0.5r, velocity: 64})
    end
  end
end
