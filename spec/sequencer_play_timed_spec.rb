require 'spec_helper'

require 'musa-dsl'

include Musa::Sequencer
include Musa::Datasets
include Musa::Series

using Musa::Extension::InspectNice


RSpec.describe Musa::Sequencer do
  context 'play_timed' do

    it 'works well with a simple case (with stops, as default)' do
      p = [ { a: 0r, b: 1r }.extend(PackedV), 3*4,
            { a: 4r, b: 5.75r }.extend(PackedV), 2*4,
            { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)

      s = BaseSequencer.new do_log: false, do_error_log: true

      expected = [
          { position: 1r,
            values: { a: 0r, b: 1r }, next_values: { a: 1r, b: 2r },
            duration: { a: 3/4r, b: 3/5r }, quantized_duration: { a: 3/4r, b: 3/5r }, started_ago: {  } },
          { position: 1+3/5r,
            values: { b: 2r }, next_values: { b: 3r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 3/5r } },
          { position: 1+3/4r,
            values: { a: 1r }, next_values: { a: 2r },
            duration: { a: 3/4r }, quantized_duration: { a: 3/4r }, started_ago: { b: 3/20r } },
          { position: 2+1/5r,
            values: { b: 3r }, next_values: { b: 4r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 9/20r } },
          { position: 2+1/2r,
            values: { a: 2r }, next_values: { a: 3r },
            duration: { a: 3/4r }, quantized_duration: { a: 3/4r }, started_ago: { b: 3/10r } },
          { position: 2+4/5r,
            values: { b: 4r }, next_values: { b: 5r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 3/10r } },
          { position: 3+1/4r,
            values: { a: 3r }, next_values: { a: 4r },
            duration: { a: 3/4r }, quantized_duration: { a: 3/4r }, started_ago: { b: 9/20r } },
          { position: 3+2/5r,
            values: { b: 5r }, next_values: { b: 6r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 3/20r } },
          { position: 4r,
            values: { a: 4r, b: 6r }, next_values: { a: 3r, b: 5r },
            duration: { a: 2/3r, b: 1/2r }, quantized_duration: { a: 2/3r, b: 1/2r }, started_ago: {  } },
          { position: 4+1/2r,
            values: { b: 5r }, next_values: { b: 4r },
            duration: { b: 1/2r }, quantized_duration: { b: 1/2r }, started_ago: { a: 1/2r } },
          { position: 4+2/3r,
            values: { a: 3r }, next_values: { a: 2r },
            duration: { a: 2/3r }, quantized_duration: { a: 2/3r }, started_ago: { b: 1/6r } },
          { position: 5r,
            values: { b: 4r }, next_values: { b: 3r },
            duration: { b: 1/2r }, quantized_duration: { b: 1/2r }, started_ago: { a: 1/3r } },
          { position: 5+1/3r,
            values: { a: 2r }, next_values: { a: nil },
            duration: { a: 2/3r }, quantized_duration: { a: 2/3r }, started_ago: { b: 1/3r } },
          { position: 5+1/2r,
            values: { b: 3r }, next_values: { b: nil },
            duration: { b: 1/2r }, quantized_duration: { b: 1/2r }, started_ago: { a: 1/6r } }]

      result = []

      s.at 1 do
        s.play_timed(p.to_timed_serie) do |values, next_values, duration:, quantized_duration:, started_ago:|
          result << { position: s.position,
                      values: values.clone,
                      next_values: next_values.clone,
                      duration: duration.clone,
                      quantized_duration: quantized_duration.clone,
                      started_ago: started_ago.clone }
        end
      end

      s.run

      expect(result).to eq(expected)
    end

    it 'works well with a simple case (without stops)' do
      p = [ { a: 0r, b: 1r }.extend(PackedV), 3*4,
            { a: 4r, b: 5.75r }.extend(PackedV), 2*4,
            { a: 1.5r, b: 2 + 1/3r }.extend(PackedV) ].extend(P)

      s = BaseSequencer.new do_log: false, do_error_log: true

      expected = [
          { position: 1r,
            values: { a: 0r, b: 1r }, next_values: { a: 1r, b: 2r },
            duration: { a: 3/4r, b: 3/5r }, quantized_duration: { a: 3/4r, b: 3/5r }, started_ago: {  } },
          { position: 1+3/5r,
            values: { b: 2r }, next_values: { b: 3r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 3/5r } },
          { position: 1+3/4r,
            values: { a: 1r }, next_values: { a: 2r },
            duration: { a: 3/4r }, quantized_duration: { a: 3/4r }, started_ago: { b: 3/20r } },
          { position: 2+1/5r,
            values: { b: 3r }, next_values: { b: 4r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 9/20r } },
          { position: 2+1/2r,
            values: { a: 2r }, next_values: { a: 3r },
            duration: { a: 3/4r }, quantized_duration: { a: 3/4r }, started_ago: { b: 3/10r } },
          { position: 2+4/5r,
            values: { b: 4r }, next_values: { b: 5r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 3/10r } },
          { position: 3+1/4r,
            values: { a: 3r }, next_values: { a: 4r },
            duration: { a: 3/4r }, quantized_duration: { a: 3/4r }, started_ago: { b: 9/20r } },
          { position: 3+2/5r,
            values: { b: 5r }, next_values: { b: 6r },
            duration: { b: 3/5r }, quantized_duration: { b: 3/5r }, started_ago: { a: 3/20r } },
          { position: 4r,
            values: { a: 4r, b: 6r }, next_values: { a: 3r, b: 5r },
            duration: { a: 2/3r, b: 1/2r }, quantized_duration: { a: 2/3r, b: 1/2r }, started_ago: {  } },
          { position: 4+1/2r,
            values: { b: 5r }, next_values: { b: 4r },
            duration: { b: 1/2r }, quantized_duration: { b: 1/2r }, started_ago: { a: 1/2r } },
          { position: 4+2/3r,
            values: { a: 3r }, next_values: { a: 2r },
            duration: { a: 2/3r }, quantized_duration: { a: 2/3r }, started_ago: { b: 1/6r } },
          { position: 5r,
            values: { b: 4r }, next_values: { b: 3r },
            duration: { b: 1/2r }, quantized_duration: { b: 1/2r }, started_ago: { a: 1/3r } },
          { position: 5+1/3r,
            values: { a: 2r }, next_values: { a: nil },
            duration: { a: 2/3r }, quantized_duration: { a: 2/3r }, started_ago: { b: 1/3r } },
          { position: 5+1/2r,
            values: { b: 3r }, next_values: { b: nil },
            duration: { b: 1/2r }, quantized_duration: { b: 1/2r }, started_ago: { a: 1/6r } }
      ]

      result = []

      s.at 1 do
        s.play_timed(p.to_timed_serie, stops: false) do
        |values, next_values, duration:, quantized_duration:, started_ago:|

          result << { position: s.position,
                      values: values.clone,
                      next_values: next_values.clone,
                      duration: duration.clone,
                      quantized_duration: quantized_duration.clone,
                      started_ago: started_ago.clone }
        end
      end

      s.run

      expect(result).to eq(expected)
    end
  end
end
