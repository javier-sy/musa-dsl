class Hash
	def inspect
		all = collect { |key, value| [ ", ", key.is_a?(Symbol) ? key.to_s + ": " : key.to_s + " => ", value.inspect ] }.flatten
		all.shift
		"{ " + all.join + " }"
	end
end

class Rational
	def inspect
		d = self - self.to_i
		if d != 0
			"#{self.to_i}(#{d.numerator}/#{d.denominator})"
		else
			"#{self.to_i}"
		end
	end
end
