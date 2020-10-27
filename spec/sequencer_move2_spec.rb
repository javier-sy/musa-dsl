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
  end
end
