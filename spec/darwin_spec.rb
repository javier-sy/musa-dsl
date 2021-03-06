require 'spec_helper'

require 'musa-dsl'

include Musa::Darwin
include Musa::Variatio
include Musa::Series

RSpec.describe Musa::Darwin do
  context 'Select over a range of variations' do
    it 'Simple selection 1' do
      v = Variatio.new :object do
        field :a, 1..10
        field :b, %i[alfa beta gamma delta]

        constructor do |a:, b:|
          { a: a, b: b }
        end
      end

      d = Darwin.new do
        measures do |object|
          die if object[:b] == :gamma

          feature :alfa_feature if object[:b] == :alfa
          feature :beta_feature if object[:b] == :beta

          dimension :a_dimension, -object[:a].to_f
        end

        weight a_dimension: 2, alfa_feature: 1, beta_feature: -0.5
      end

      population = S(*v.run).randomize.to_a

      survivors = d.select population

      expect(survivors.size).to eq(population.size - 10)

      expect(survivors[0]).to eq(a: 1, b: :alfa)
      expect(survivors.last).to eq(a: 10, b: :beta)
    end

    it 'Simple selection 2' do
      v = Variatio.new :object do
        field :a, 1..10
        field :b, %i[alfa beta gamma delta]

        constructor do |a:, b:|
          { a: a, b: b }
        end
      end

      d = Darwin.new do
        measures do |object|
          die if object[:b] == :gamma

          feature :alfa_feature if object[:b] == :alfa
          feature :beta_feature if object[:b] == :beta

          dimension :a_dimension, -object[:a].to_f
        end

        weight a_dimension: 1, beta_feature: 1, alfa_feature: -0.5
      end

      population = S(*v.run).randomize.to_a

      survivors = d.select population

      expect(survivors.size).to eq(population.size - 10)

      expect(survivors[0]).to eq(a: 1, b: :beta)
      expect(survivors.last).to eq(a: 10, b: :alfa)
    end
  end
end
