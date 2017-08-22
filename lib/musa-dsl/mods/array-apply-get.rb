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


