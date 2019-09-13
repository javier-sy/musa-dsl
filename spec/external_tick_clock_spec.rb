require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Timer do
  context 'External tick clock' do
    it 'works ok' do

      clock = Musa::ExternalTickClock.new

      c = 0

      clock.run do
        c += 1
      end

      expect(c).to eq 0

      clock.tick

      expect(c).to eq 1

      clock.tick

      expect(c).to eq 2

      clock.terminate
      clock.tick

      expect(c).to eq 2

      clock.run
      clock.tick

      expect(c).to eq 2

      clock.terminate
      clock.tick

      expect(c).to eq 2
    end
  end
end

