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
		end

		def restart
			@serie.restart
		end

		def next_value
			source = @serie.next_value
			result = nil

			if source
				if source.key? :neuma
					result = @decoder.decode source
				elsif source.key? :serie
					result = S(*source[:serie]).neumatize @decoder, duplicate: @duplicate
				end
			end

			result
		end

		def infinite?
			@serie.infinite?
		end
	end

	private_constant :SerieNeumatizer
end	

def neuma_eval element, decoder:, context:, sequencer:, &block
	if element.is_a? Musa::Serie
		puts "neuma_eval: if Serie: #{element.to_a}"

		sequencer.play element.neumatize(decoder) do |e|
			neuma_eval e, decoder: decoder, context: context, sequencer: sequencer, &block
		end
	elsif block # se supone que llegados a este punto ne es un neuma final
		puts "neuma_eval: elseif block: #{element}"

		block.call element
	else
		puts "neuma_eval: else: #{element}"
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

			sequencer = Musa::Sequencer.new 4, 4 do
				at 1 do
					context = Context.new

					play serie.neumatize(gdv_decoder) do |element|
						neuma_eval element, decoder: gdv_decoder, context: context, sequencer: sequencer do |gdv|
							played[position] ||= []
							played[position] << gdv #.to_pdv(scale)
						end
					end
				end
			end

			sequencer.tick while sequencer.size > 0

			puts
			puts "PLAYED"
			puts "------"
			pp played

			expect(1).to eq(1)
		end
	end
end
