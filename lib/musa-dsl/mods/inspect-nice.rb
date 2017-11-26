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

	alias _to_s_original to_s

	def to_s
		if to_i == self
			to_i.to_s
		else
			_to_s_original
		end
	end
end
