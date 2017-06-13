require 'musa-dsl'
require 'pp'

RSpec.describe Musa::Darwin do
	context "Select over a range of variations" do

		it "" do

			d = Musa::Darwin.new do

				measures do |object|
					die if object.distance > 10

					feature :good_chord if object.x > 10
					feature :great_bla if object.y > 100

					dimension :height, object.height

					dimension :ratio, object.width / object.height
					dimension :light, object.light
				end


				weight good_chord: 1, height: 1, ratio: 1, light: 0.5, blueness: 0.1


			end

			survivors = d.select [ {}, {}, {}, {} ]

			expect(variations.size).to eq 1

			expect(variations[0]).to eq({ a: 1000, b: 0, c: 2, d: { 100 => { e: 4, f: 6 } }, finalized: true })
		end
	end
end
