require 'spec_helper'

require 'pp'

require 'musa-dsl'

include Musa::Series



class Context < Object
end

module Musa::SerieOperations
	def neumatize decoder, duplicate: nil

		duplicate ||= false
		serie = duplicate ? self.duplicate : self

		Musa::Serie.new SerieNeumatizer.new(serie, duplicate, decoder)
	end

	class SerieNeumatizer
		include Musa::ProtoSerie
	
		def initialize(serie, duplicate, decoder)
			@serie = serie
			@duplicate = duplicate
			@decoder = decoder

			@result = []
		end

		def restart
			@serie.restart
			@result = []
		end

		def next_value
			if @result.empty?
				source = @serie.next_value

				###### TODO gestionar la creación de una única salida con: neumas para interpretar o proc's para ejecutar en el context
				####### Requiere la inclusión de código sofisticado en la semántica del parser? tipo: métodos sobre las series o sobre los assign_to que evalúen su contenido interno????

				if source
					if source.key?  :neuma
						@result << @decoder.decode(source)

					elsif source.key? :serie

						decoder = @decoder
						
						@result << proc do |context, control, block| # play subserie launching finish event after finishing serie
							handler = nil

							after = proc do
								puts "launch :end"
								handler.launch :end, @serie
							end

							handler = play S(*source[:serie]).neumatize(decoder), after: after do |element|
								neuma_eval element, context: context, &block
							end
						end

						@result << nil
					end
				end
			end

			@result.shift
		end

		def infinite?
			@serie.infinite?
		end
	end

	private_constant :SerieNeumatizer
end	

def neuma_eval element, context:, &block
	#puts "neuma_eval: #{element}"

	if element.is_a? Proc
		instance_exec context, block, &element
	else
		block.call element
	end

	nil
end


RSpec.describe Musa::Neuma do

	context "Neuma advanced parsing" do

		scale = Musa::Scales.get(:major).based_on_pitch 60
		gdv_decoder = Musa::Dataset::GDV::NeumaDecoder.new scale

		it "Complex file neuma parsing" do
			serie = S *(Musa::Neuma.parse_file File.join(File.dirname(__FILE__), "neuma3_spec.neu"))
			
			puts "SERIE"
			puts "------"
			pp serie.to_a
			puts

			played = {}

			context = Context.new
			sequencer = Musa::Sequencer.new 4, 4 do
				at 1 do
					play serie.neumatize(gdv_decoder) do |element|
						neuma_eval element, context: context do |gdv|
							played[position] ||= []
							played[position] << gdv #.to_pdv(scale)
						end
					end
				end
			end

			while sequencer.size > 0
				sequencer.tick
				puts "tick"
			end


			puts
			puts "PLAYED"
			puts "------"
			pp played

			expect(1).to eq(1)
		end
	end
end
