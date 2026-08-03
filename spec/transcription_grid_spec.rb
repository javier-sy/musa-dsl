# The one transcription behaviour that no example can declare.
#
# A trill that would accelerate past the sequencer's tick resolution is clamped,
# and it says so through the logger. The claim is about a WARNING, not about a
# return value, so there is nothing to write as `# =>` -- everything else this
# file used to hold is now declared in the documentation of
# `lib/musa-dsl/transcription/` and verified there by tools/doc-examples.rb.

require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Transcription against the tick grid' do
  include Musa::All

  it 'never trills finer than the grid it is given' do
    trill = Musa::Transcriptors::FromGDV::ToMIDI::Trill.new(duration_factor: 1/8r)
    logged = []
    trill.instance_variable_set(:@logger, Class.new do
      define_method(:warn) { |_progname = nil, &block| logged << block.call }
    end.new)
  
    result = trill.transcript({ grade: 0, duration: 1r, tr: 1/8r },
                              base_duration: 1/4r, tick_duration: 1/96r)
  
    # The middle of a trill accelerates to 2/3 of its note duration, so the
    # floor is a tick and a half if nothing is to fall below the tick.
    expect(result.collect { |n| n[:duration] }.min).to eq(1/96r)
    expect(logged.size).to eq(1)
    expect(logged.first).to include('below the tick')
  end
end
