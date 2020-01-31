require 'spec_helper'

require 'musa-dsl'

class Cosa
  include AsContextRun

  def hola
    "hola"
  end
end

RSpec.describe AsContextRun do
  context '.with evaluation' do
    it 'test1' do
      c = Cosa.new

      x = "x externo"

      xx = nil
      c.with do
        xx = x
      end

      expect(xx).to eq "x externo"
    end
  end
end