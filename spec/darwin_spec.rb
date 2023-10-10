require 'spec_helper'
require 'musa-dsl'

RSpec.describe Musa::Darwin do
  context 'Select over a range of variations' do
    include Musa::Series

    it 'Simple selection 1' do
      v = Musa::Variatio::Variatio.new :object do
        field :a, 1..10
        field :b, %i[alfa beta gamma delta]

        constructor do |a:, b:|
          { a: a, b: b }
        end
      end

      d = Musa::Darwin::Darwin.new do
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
      v = Musa::Variatio::Variatio.new :object do
        field :a, 1..10
        field :b, %i[alfa beta gamma delta]

        constructor do |a:, b:|
          { a: a, b: b }
        end
      end

      d = Musa::Darwin::Darwin.new do
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

  it 'Prueba para el doctorado' do
    from_progression_size = 3
    to_progression_size = 6
    samples_per_size = 20

    progressions =
      (from_progression_size..to_progression_size).collect do |size|
        (1..samples_per_size).collect do
          { parameters: { a: rand.round(3), b: rand.round(3), c: rand.round(3) },
            chords:
              (1..size).collect do
                [[:i, :ii, :iii, :iv, :v, :vi, :vii][rand(0..6)]] +
                [[:i, :ii, :iii, :iv, :v, :vi, :vii][rand(0..6)]] +
                [[:i, :ii, :iii, :iv, :v, :vi, :vii][rand(0..6)]]
            end
          }
        end
      end.flatten(1)

    puts "#{progressions}"

    d = Musa::Darwin::Darwin.new do
      measures do |progression|
        die if progression[:chords].last.include?(:vii)
        die if progression[:chords].any? { |chord| chord.uniq.size < chord.size }

        feature :ends_with_tonic if progression[:chords].last.include?(:i)
        feature :good_conduction if progression[:chords][-2].include?(:v)
        feature :conduction_with_dominant if progression[:chords][-2].include?(:iv) &&
                                             progression[:chords][-2].include?(:v)

        dimension :good_size, -(progression[:chords].size - 4).abs
      end

      weight good_size: 1,
             ends_with_tonic: 2,
             good_conduction: 1,
             conduction_with_dominant: 1
    end

    good_progressions = d.select progressions

    good_progressions.first(3).each do |progression|
      puts "Parámetros: #{progression[:parameters]} Progresión: #{progression[:chords]}"
    end
  end
end
