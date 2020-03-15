require 'spec_helper'

require 'musa-dsl'

include Musa::Neumalang
include Musa::Scales
include Musa::Neumas

RSpec.describe Musa::Neumalang do

  context "Neuma parsing" do
    scale = Scales.et12[440.0].major[60]
    decoder = Decoders::NeumaDecoder.new scale

    it "Neumas with syntax 1" do
      a = Neumalang.parse('2.o3./.f').to_a(recursive: true)
      b = Neumalang.parse('(2 o3 / f)').to_a(recursive: true)
      c = Neumalang.parse('(2 3 1/2r 2)').to_a(recursive: true)

      puts "a = #{a}"
      puts "b = #{b}"
      puts "c = #{c}"

      expect(a).to eq(b)
      expect(a).to eq(c)
      expect(b).to eq(c)
    end

    it "Neumas with syntax 2" do
      a = Neumalang.parse('2.o3./.f', decode_with: decoder).to_a(recursive: true)
      b = Neumalang.parse('(2 o3 / f)', decode_with: decoder).to_a(recursive: true)
      #c = Neumalang.parse('(2 3 1/2r 2)', decode_with: decoder).to_a(recursive: true)

      puts "a = #{a}"
      puts "b = #{b}"
      #puts "c = #{c}"

      expect(a).to eq(b)
      expect(a).to eq(c)
        #expect(b).to eq(c)
    end

  end
end
