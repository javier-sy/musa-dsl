require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Series do
  context 'Series queue' do
    it 'Basic QUEUE series: initialized from constructor' do
      s = QUEUE(S(1, 2, 3), S(4, 5, 6))

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Basic QUEUE series: adding a serie' do
      s = QUEUE(S(1, 2, 3), S(4, 5, 6))

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2

      s << S(7, 8, 9)

      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3
      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Basic QUEUE series: from source with .queued method' do
      s = S(1, 2, 3).queued

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s << S(4, 5, 6)

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2
      expect(s.next_value).to eq 3

      expect(s.next_value).to eq 4
      expect(s.next_value).to eq 5
      expect(s.next_value).to eq 6

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Basic QUEUE series: clearing and adding' do
      s = QUEUE(S(1, 2, 3), S(4, 5, 6))

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 1
      expect(s.current_value).to eq 1

      expect(s.next_value).to eq 2

      s.clear

      expect(s.current_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil


      s << S(7, 8, 9)

      expect(s.next_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil

      s.restart

      expect(s.current_value).to eq nil

      expect(s.next_value).to eq 7
      expect(s.current_value).to eq 7
      expect(s.next_value).to eq 8
      expect(s.next_value).to eq 9

      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
      expect(s.next_value).to eq nil
    end

    it 'Basic QUEUE series: deterministic and infinite checking' do
      s = QUEUE(S(1, 2, 3), S(4, 5, 6))

      expect(s.infinite?).to eq false

      s.clear

      expect(s.infinite?).to eq false

      s.clear

      s << RND(from: 1, to: 10)
      s << S(10, 11, 12)

      expect(s.infinite?).to eq false

      s.clear

      s << RND(from: 1, to: 10).repeat
      s << S(10, 11, 12)

      expect(s.infinite?).to eq true
    end
  end
end
