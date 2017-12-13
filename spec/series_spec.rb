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

		it "After" do

			s1 = S(1, 2, 3, 4)
			s2 = S(5, 6, 7, 8)

			s3 = s1.after(s2)

			r = []

			while value = s3.next_value
				r << value
			end

			expect(r).to eq [1, 2, 3, 4, 5, 6, 7, 8]
			expect(s3.next_value).to eq nil

		end

		it "Hash serie repeated and split and H() should be equal to the original serie" do
			# TODO
		end

		it "Serie splitter" do
			s = S 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

			ss = s.cut 3

			sss1 = ss.next_value

			expect(sss1.to_a).to eq [1, 2, 3]

			sss2 = ss.next_value
			sss3 = ss.next_value
			sss4 = ss.next_value

			expect(sss2.to_a).to eq [4, 5, 6]
			expect(sss3.to_a).to eq [7, 8, 9]
			expect(sss4.to_a).to eq [10, 11, 12]

			sss5 = ss.next_value

			expect(sss5.to_a).to eq []
		end

		it "Serie splitted merged" do
			s = S 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12

			ss = s.cut 3

			sss = ss.merge

			expect(sss.to_a).to eq [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
		end
	end
end
