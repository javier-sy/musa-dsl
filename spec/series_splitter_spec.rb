require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Serie do

	context "Hash series splitter" do

		it "S([1, 10, 100], [2, 20, 200], [3, 30, 300]).hashify.split (only next_value)" do

			s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
			h = s.hashify :a, :b, :c
			ss = h.split master: :c

			expect(ss[:a].next_value).to eq 1
			expect(ss[:b].next_value).to eq 10
			expect(ss[:c].next_value).to eq 100

			expect(ss[:a].next_value).to eq 1
			expect(ss[:b].next_value).to eq 10

			expect(ss[:a].next_value).to eq 1
			expect(ss[:b].next_value).to eq 10

			expect(ss[:c].next_value).to eq 200

			expect(ss[:a].next_value).to eq 2
			expect(ss[:b].next_value).to eq 20

			expect(ss[:a].next_value).to eq 2
			expect(ss[:b].next_value).to eq 20

			expect(ss[:c].next_value).to eq 300

			expect(ss[:a].next_value).to eq 3
			expect(ss[:b].next_value).to eq 30

			expect(ss[:a].next_value).to eq 3
			expect(ss[:b].next_value).to eq 30

			expect(ss[:c].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:c].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:c].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil
		end

		it "S([1, 10, 100], [2, 20, 200], [3, 30, 300]).hashify.split (next_value and peek_next_value)" do

			s = S([1, 10, 100], [2, 20, 200], [3, 30, 300])
			h = s.hashify :a, :b, :c
			ss = h.split master: :c

			expect(ss[:a].peek_next_value).to eq 1

			expect(ss[:a].next_value).to eq 1
			expect(ss[:b].next_value).to eq 10

			expect(ss[:c].peek_next_value).to eq 100
			expect(ss[:c].peek_next_value).to eq 100
			expect(ss[:c].next_value).to eq 100

			expect(ss[:a].next_value).to eq 1
			expect(ss[:b].next_value).to eq 10

			expect(ss[:a].next_value).to eq 1
			expect(ss[:b].next_value).to eq 10

			expect(ss[:c].peek_next_value).to eq 200
			expect(ss[:c].peek_next_value).to eq 200
			expect(ss[:a].next_value).to eq 1

			expect(ss[:c].next_value).to eq 200
			expect(ss[:c].peek_next_value).to eq 300
			expect(ss[:c].peek_next_value).to eq 300

			expect(ss[:a].next_value).to eq 2
			expect(ss[:b].next_value).to eq 20

			expect(ss[:a].next_value).to eq 2
			expect(ss[:b].next_value).to eq 20

			expect(ss[:c].peek_next_value).to eq 300
			expect(ss[:c].next_value).to eq 300
			expect(ss[:c].peek_next_value).to eq nil

			expect(ss[:a].peek_next_value).to eq 3
			expect(ss[:a].next_value).to eq 3
			expect(ss[:a].peek_next_value).to eq 3

			expect(ss[:b].next_value).to eq 30

			expect(ss[:a].next_value).to eq 3
			expect(ss[:b].next_value).to eq 30

			expect(ss[:c].next_value).to eq nil

			expect(ss[:a].peek_next_value).to eq nil
			expect(ss[:a].next_value).to eq nil
			expect(ss[:a].peek_next_value).to eq nil
			
			expect(ss[:b].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:c].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:c].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil

			expect(ss[:a].next_value).to eq nil
			expect(ss[:b].next_value).to eq nil
		end

	end
end
