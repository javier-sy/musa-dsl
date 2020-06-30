require 'spec_helper'

require 'musa-dsl'

class Test
  include Musa::Extension::With

  def initialize(value, &block)
    @value = value

    if value == 200
      with 'a string', &block if block_given?
    else
      with &block if block_given?
    end
  end

  attr_reader :value
end

RSpec.describe Musa::Extension::With do
  context 'With used' do

    it 'with no parameters it accesses object context' do
      x = nil
      Test.new(100) do
        x = @value
      end

      expect(x).to eq 100
    end

    it 'with one _ parameter it keeps original calling context' do
      x = nil
      y = nil

      Test.new(100) do |_|
        x = _.value
        y = @value
      end

      expect(x).to eq 100
      expect(y).to eq nil
    end

    it 'with one normal parameter and no passing parameters it accesses object context' do
      x = nil
      y = nil

      Test.new(100) do |t|
        x = t
        y = @value
      end

      expect(x).to eq nil
      expect(y).to eq 100
    end

    it 'with one normal parameter and passing parameters it accesses object context and receives the parameters' do
      x = nil
      y = nil

      Test.new(200) do |t|
        x = t
        y = @value
      end

      expect(x).to eq 'a string'
      expect(y).to eq 200
    end

    it 'with one _ parameter and one normal parameter and passing parameters it keeps original calling context and receives the parameters' do
      x = nil
      y = nil
      z = nil

      Test.new(200) do |_, t|
        x = t
        y = _.value
        z = @value
      end

      expect(x).to eq 'a string'
      expect(y).to eq 200
      expect(z).to eq nil
    end

  end
end
