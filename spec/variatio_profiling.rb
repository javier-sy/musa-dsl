require 'musa-dsl'
require 'profile'

v3 = Musa::Variatio.new :object do

	field :a
	field :b, [0, 1]
	field :c, [2, 3]

	constructor do |a:, b:|
		{ a: a, b: b, d: {} }
	end

	finalize do |object:|
		object[:finalized] = true
	end

	with_attributes do |object:, c:|
		object[:c] = c
	end

	fieldset :d, [100, 101] do

		field :e, [4, 5]
		field :f, [6, 7]

		with_attributes do |object:, d:, e:, f:|

			object[:d][d] ||= {}
			object[:d][d][:e] = e
			object[:d][d][:f] = f
		end

		fieldset :g, [200, 201] do
			
			field :h, [8, 9]
			field :i, [10, 11]

			with_attributes do |object:, d:, g:, h:, i:|
				object[:d][d][:g] ||= {}
				object[:d][d][:g][g] ||= {}

				object[:d][d][:g][g][:h] = h
				object[:d][d][:g][g][:i] = i
			end
		end
	end
end



variations = v3.on a: 1000

puts "variations.size = #{variations.size}"
