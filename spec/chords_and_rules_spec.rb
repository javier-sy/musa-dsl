require 'spec_helper'

require 'musa-dsl'

RSpec.describe Musa::Rules do
  context 'Rules grow/prune generation (without parameters)' do
    rules = Musa::Rules::Rules.new do
      grow 'generate 1 octave down' do |chord|
        branch chord
        branch chord.octave(-1)
      end

      grow 'generate inversions' do |chord|
        branch chord
        branch chord.move root: 1
        branch chord.move(root: 1, third: 1)
        branch chord.move(root: 1, third: 1, fifth: 1)
        branch chord.move(root: 1, third: 1, fifth: 1, seventh: 1) if chord.features[:size] == :seventh
        branch chord.move(root: 1, third: 1, fifth: 1, seventh: 1, ninth: 1) if chord.features[:size] == :ninth
        branch chord.move(root: 1, third: 1, fifth: 1, seventh: 1, ninth: 1, eleventh: 1) if chord.features[:size] == :eleventh
      end

      grow 'generate 4 voices duplicating one of them if needed' do |chord|
        if chord.pitches.size == 3
          branch chord.duplicate({ chord.notes[0].grade => 1 })
        end
      end

      # grow 'generate 2nd inversion' do |chord|
      #   branch chord.move({ root: 1, third: 1 })
      # end
      #
      # grow 'generate 3rd inversion' do |chord|
      #   branch chord.move({ root: 1, third: 1, fifth: 1 })
      # end
      #
      # grow 'generate 4th inversion' do |chord|
      #   branch chord.move({ root: 1, third: 1, fifth: 1, seventh: 1 }) if chord[:seventh]
      # end
      #
      # grow 'generate 5th inversion' do |chord|
      #   branch chord.move({ root: 1, third: 1, fifth: 1, seventh: 1, ninth: 1 }) if chord[:ninth]
      # end
      #
      # grow 'generate 6th inversion' do |chord|
      #   branch chord.move({ root: 1, third: 1, fifth: 1, seventh: 1, ninth: 1, eleventh: 1 }) if chord[:eleventh]
      # end

      # cut 'parallel fifth' do |chord, history|
      #
      #   if !history.empty?
      #     chord_sorted_piches = chord.pitches.sort
      #     last_chord_sorted_piches = history.last.pitches.sort
      #
      #     (0..3).find do |voice|
      #       (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
      #         # 5ª entre 2 voces del acorde
      #         # 5ª en el acorde anterior con las mismas voces
      #         prune if (chord_sorted_piches[voice] - chord_sorted_piches[voice2]) % 12 == 7 &&
      #           (last_chord_sorted_piches[voice] - last_chord_sorted_piches[voice2]) % 12 == 7
      #       end
      #     end
      #   end
      # end

      # cut 'parallel octave' do |chord, history|
      #   if !history.empty?
      #     chord_sorted_piches = chord.pitches.sort
      #     last_chord_sorted_piches = history.last.pitches.sort
      #
      #     (0..3).find do |voice|
      #       (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
      #         # 8ª entre 2 voces del acorde
      #         # 8ª en el acorde anterior con las mismas voces
      #         prune if (chord_sorted_pitches[voice] - chord_sorted_pitches[voice2]) % 12 == 0 &&
      #           (last_chord_sorted_piches[voice] - last_chord_sorted_piches[voice2]) % 12 == 0
      #       end
      #     end
      #   end
      # end

      cut 'bad voice leading' do |chord, history|
        if !history.empty?
          chord_sorted_piches = chord.pitches.sort
          last_chord_sorted_piches = history.last.pitches.sort

          chord_sorted_piches.each_index.find do |voice|
            if (last_chord_sorted_piches[voice] - chord_sorted_piches[voice]).abs > 2
              prune 'not gradual voice leading'
              break
            end
          end
        end
      end
    end

    it 'test', skip: 'pensar y completar test' do
      major = Musa::Scales::Scales.et12[440.0].major[60]

      IM = major.tonic.chord :triad #, duplicate: { root: 1 }
      IIIm = major.third.chord :triad #, duplicate: { root: 1 }
      IVM7 = major.fourth.chord :seventh #, duplicate: { root: 1 }
      V = major.fifth.chord :triad
      V7 = major.dominant.chord :dominant
      VM = major.fifth.chord :triad # , duplicate: { root: 1 }

      V7_VI = major.sixth.scale(:major).fifth.chord :dominant
      V7_II = major.second.scale(:major).fifth.chord :dominant
      V7_V = major.fifth.scale(:major).fifth.chord :dominant

      VIm = major.sixth.chord :triad # , duplicate: { root: 1 }

      combinations = rules.apply([IM, V7]).combinations

      puts 'combinations ='
      combinations.each do |combination|
        pp combination.collect(&:pitches).collect(&:sort)
      end
    end
  end
end
