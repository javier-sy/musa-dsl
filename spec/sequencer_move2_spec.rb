require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer
include Musa::Datasets

using Musa::Extension::InspectNice

RSpec.describe Musa::Sequencer do
  context 'Move2 testing' do
    it '' do
      s = BaseSequencer.new do_log: true, do_error_log: true

      p = [{ a: 0r, b: 1r }.extend(PackedV), 3, { a: 4r, b: 5.75r }.extend(PackedV), 2, { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)

      s.at 1 do
        s._move2 p.to_ps_serie(base_duration: 1).i, step: 1, reference: 0 do |values, duration:, quantized_duration:, started_ago:|
          s.debug "values = #{values.inspect} duration #{duration} q_duration #{quantized_duration} started_ago #{started_ago}"
        end
      end

      puts
      s.run
      puts

    end


    it '' do
      p = [{ a: 0r, b: 1r }.extend(PackedV), 3, { a: 4r, b: 5.75r }.extend(PackedV), 2, { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)


      p.to_ps_serie == [ { from: { a: 0, b: 1 }.extend(PackedV), to: { a: 4, b: 5.75r }.extend(PackedV),  duration: 3 }.extend(PS),
                         { from: { a: 4, b: 5.75 }.extend(PackedV), to: { a: 1.5, b: 2 + 1/3r }.extend(PackedV),  duration: 2 }.extend(PS) ]


      p.to_timed_serie ==
      [ { time: 0, value: { a: 0r, b: 1r }.extend(PackedV) }.extend(TimedAbsI),
        { time: 3, value: { a: 4r, b: 5.75r }.extend(PackedV) }.extend(TimedAbsI),
        { time: 5, value: { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) }.extend(TimedAbsI) ]


      p.to_timed_serie.flatten_timed ==
      [ { a: { time: 0, value: 0r }.extend(TimedAbsI), b: { time: 0, value: 1r }.extend(TimedAbsI) },
        { a: { time: 3, value: 4r }.extend(TimedAbsI), b: { time: 3, value: 5.75r }.extend(TimedAbsI) },
        { a: { time: 5, value: 1.5r }.extend(TimedAbsI), b: { time: 5, value: 2 + 1/3r }.extend(TimedAbsI) } ]

      p.to_timed_serie.flatten_timed

      split = p.to_timed_serie.flatten_timed.split ======= ....



      split[:a]
      split[:b]

      qa = QUANTIZE() { split[:a].next_value }
      qb = QUANTIZE() { split[:b].next_value }

      quantized = H(a: qa, b: qb)


      x = p.to_ps_serie.to_absd_serie.split

      QUANTIZE


      s.at 1 do
        s._move2 p.to_ps_serie(base_duration: 1).i, step: 1, reference: 0 do |values, duration:, quantized_duration:, started_ago:|
          s.debug "values = #{values.inspect} duration #{duration} q_duration #{quantized_duration} started_ago #{started_ago}"
        end
      end

      puts
      s.run
      puts

    end

  end
end
