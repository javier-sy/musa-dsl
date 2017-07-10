require 'spec_helper'

require 'musa-dsl'

include Musa::Series

RSpec.describe Musa::Serie do

	context "Series operations" do
		it "Duplicate" do
			s1 = S(1, 2, 3, 4, 5, 6)

			s2 = s1.duplicate

			expect(s1.next_value).to eq 1
			expect(s1.next_value).to eq 2
			expect(s1.next_value).to eq 3

			expect(s2.next_value).to eq 1
			expect(s2.next_value).to eq 2
			expect(s2.next_value).to eq 3

			expect(s1.next_value).to eq 4
			expect(s1.next_value).to eq 5

			expect(s2.next_value).to eq 4
			expect(s2.next_value).to eq 5
			expect(s2.next_value).to eq 6

			expect(s2.next_value).to eq nil
			expect(s2.next_value).to eq nil

			expect(s1.next_value).to eq 6

			expect(s1.next_value).to eq nil
			expect(s1.next_value).to eq nil
		end
	end
end
