require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer
include Musa::Datasets
include Musa::Series

using Musa::Extension::InspectNice


RSpec.describe Musa::Sequencer do
  context 'Move2 testing' do

    it '' do
      raise NotImplementedError

      p = [ { a: 0r, b: 1r }.extend(PackedV), 3*4,
            { a: 4r, b: 5.75r }.extend(PackedV), 2*4,
            { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)

      s = BaseSequencer.new do_log: true, do_error_log: true

      s.at 1 do
        s.play_timed(p.to_timed_serie) do |values, next_values, duration:, quantized_duration:, started_ago:|
          s.debug "values #{values} next_values #{next_values} duration #{duration} quantized_duration #{quantized_duration} started_ago #{started_ago}"
        end
      end

      s.run

    end


    it '' do
      raise NotImplementedError
      p = [ { a: 0r, b: 1r }.extend(PackedV), 3*4,
            { a: 4r, b: 5.75r }.extend(PackedV), 2*4,
            { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)


      # pp p.to_ps_serie.to_a
      puts
      puts "to_timed_serie.flatten_timed"
      pp p.to_timed_serie.flatten_timed.to_a

      p.to_ps_serie == [ { from: { a: 0, b: 1 }.extend(PackedV), to: { a: 4, b: 5.75r }.extend(PackedV),  duration: 3*4 }.extend(PS),
                         { from: { a: 4, b: 5.75 }.extend(PackedV), to: { a: 1.5, b: 2 + 1/3r }.extend(PackedV),  duration: 2*4 }.extend(PS) ]


      p.to_timed_serie ==
      [ { time: 0, value: { a: 0r, b: 1r }.extend(PackedV) }.extend(AbsTimed),
        { time: 3, value: { a: 4r, b: 5.75r }.extend(PackedV) }.extend(AbsTimed),
        { time: 5, value: { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) }.extend(AbsTimed) ]


      p.to_timed_serie.flatten_timed ==
      [ {a: { time: 0, value: 0r }.extend(AbsTimed), b: {time: 0, value: 1r }.extend(AbsTimed) },
        {a: { time: 3, value: 4r }.extend(AbsTimed), b: {time: 3, value: 5.75r }.extend(AbsTimed) },
        {a: { time: 5, value: 1.5r }.extend(AbsTimed), b: {time: 5, value: 2 + 1/3r }.extend(AbsTimed) } ]

      split = p.to_timed_serie.flatten_timed.split



      puts
      puts "split[:a].to_a"
      pp split[:a].to_a

      puts
      puts "split[:b].to_a"
      pp split[:b].to_a

      qa = QUANTIZE(split[:a]).instance
      qb = QUANTIZE(split[:b]).instance


      s = BaseSequencer.new do_log: true, do_error_log: true

      s.at 1 do
        s.play qa, mode: :neumalang do |value|
          s.debug "a = #{value}"
        end

        s.play qb, mode: :neumalang do |value|
          s.debug "b = #{value}"
        end

      end






      puts
      s.run
      puts

    end

  end
end
