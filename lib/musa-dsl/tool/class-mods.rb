# TODO hacer que *_nice permitar recibir atributos para indicar cómo se quieren procesar los parámetros (haciendo *, **, o sin hacer nada)

class Array
	def apply method_name, source
	
		source = [source] unless source.is_a? Array
		
		self.each_with_index do |o, i|
			o.send method_name, source[i % source.length]
		end
	end

	def get method_name
		self.collect { |o| o.send method_name }
	end
end

class Hash
	def inspect
		all = collect { |key, value| [ ", ", key.is_a?(Symbol) ? key.to_s + ": " : key + " => ", value.inspect ] }.flatten
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

	alias to_s inspect
end

