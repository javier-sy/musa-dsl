require 'musa-dsl'

ChordProgression = Musa::Rules.new do

  rule "fundamental" do |seed|
    possibility Musa::Chord.new seed - 12
    possibility Musa::Chord.new seed
    possibility Musa::Chord.new seed + 12
  end

  rule "3º" do |chord, history|
    if chord.fundamental && !chord.third

      last = history.last unless history.empty?

      if last
        [-12, 0, +12, +24].each do |offset|
          last.ordered.find do |note|
            if (note - (chord.fundamental + offset + 4)).abs <= 4
              possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 + offset }
            end
          end
        end
      else
        possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 - 12 }
        possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 }
        possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 + 12 }
        possibility chord.duplicate.tap { |_| _.third = chord.fundamental + 4 + 24 }
      end
    end
  end

  rule "5º" do |chord, history|
    if chord.fundamental && !chord.fifth
      last = history.last unless history.empty?

      if last
        [-12, 0, +12, +24].each do |offset|
          last.ordered.find do |note|
            if (note - (chord.fundamental + offset + 7)).abs <= 4
              possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 + offset }
            end
          end
        end
      else
        possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 - 12 }
        possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 }
        possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 + 12 }
        possibility chord.duplicate.tap { |_| _.fifth = chord.fundamental + 7 + 24 }
      end
    end
  end

  rule "duplication" do |chord, history|
    if chord.fundamental && !chord.duplicated
      possibility chord.duplicate.tap { |_| _.duplicated = :fundamental; _.duplicate_on = -12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :fundamental; _.duplicate_on = +12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :third; _.duplicate_on = +12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :third; _.duplicate_on = +24 }
      possibility chord.duplicate.tap { |_| _.duplicated = :fifth; _.duplicate_on = +12 }
      possibility chord.duplicate.tap { |_| _.duplicated = :fifth; _.duplicate_on = +24 }
    end
  end

  ended_when do |chord|
    chord.soprano && chord.alto && chord.tenor && chord.bass
  end

  rejection "more than octave apart" do |chord|
    if chord.tenor && chord.bass
      reject "bass-tenor" if chord.tenor - chord.bass > 12
    end

    if chord.alto && chord.tenor
      reject "alto-tenor" if chord.alto - chord.tenor > 12
    end

    if chord.soprano && chord.alto
      reject "soprano-alto" if chord.soprano - chord.alto > 12
    end
  end

  rejection "parallel fifth" do |chord, history|
    if !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass

      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 5ª entre 2 voces del acorde
          # 5ª en el acorde anterior con las mismas voces
          reject if (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 7 &&
                    (history.last.ordered[voice] - history.last.ordered[voice2]) % 12 == 7
        end
      end
    end
  end

  rejection "parallel octave" do |chord, history|
    if !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass
      (0..3).find do |voice|
        (0..3).to_a.tap { |vv| vv.delete voice }.find do |voice2|
          # 8ª entre 2 voces del acorde
          # 8ª en el acorde anterior con las mismas voces
          reject if (chord.ordered[voice] - chord.ordered[voice2]) % 12 == 0 &&
                    (history.last.ordered[voice] - history.last.ordered[voice2]) % 12 == 0
        end
      end
    end
  end

  rejection "bad voice leading" do |chord, history|
    if !history.empty? && chord.soprano && chord.alto && chord.tenor && chord.bass
      last = history.last
      (0..3).find do |voice|
        reject "not gradual voice leading" if (last.ordered[voice] - chord.ordered[voice]).abs > 4
      end
    end
  end
end

n = ChordProgression.apply [60, 65, 67]

#pp n.fish
pp n.combinations
