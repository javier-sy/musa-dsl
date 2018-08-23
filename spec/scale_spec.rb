require 'spec_helper'

require 'musa-dsl'

module Musa
	module Scales
		@@scale_systems = {}

		class << self
			def register scale_system
				@@scale_systems[scale_system.id] = scale_system
			end

			def [] id
				raise KeyError, "Scale system :#{id} not found" unless @@scale_systems.has_key? id
				@@scale_systems[id]
			end
		end
	end

	class ScaleSystem
		class << self
			# @abstract Subclass is expected to implement names
			# @!method id
			# 	Returns the id of the ScaleSystem as a symbol
			def id
				raise "Method not implemented. Should be implemented in subclass."
			end

			# @abstract Subclass is expected to implement notes_in_octave
			# @!method notes_in_octave
			# 	Returns the number of notes in one octave in the ScaleSystem
			def notes_in_octave
				raise "Method not implemented. Should be implemented in subclass."
			end

			def [] a_frequency
				a_frequency = a_frequency.to_f

				@a_tunings ||= {}
				@a_tunings[a_frequency] = ScaleSystemTuning.new self, a_frequency unless @a_tunings.has_key? a_frequency

				@a_tunings[a_frequency]
			end

			def register scale_kind
				@scale_kinds ||= {}
				@scale_kinds[scale_kind.id] = scale_kind
			end

			def scale_kind id
				raise KeyError, "Scale kind :#{id} not found in scale system :#{self.id}" unless @scale_kinds.has_key? id
				@scale_kinds[id]
			end
		end
	end

	class ScaleSystemTuning
		extend Forwardable

		def initialize scale_system, a_frequency
			@scale_system = scale_system
			@a_frequency = a_frequency
		end

		def_delegators :@scale_system, :notes_in_octave

		attr_reader :a_frequency, :scale_system

		def [] scale_kind_id
			@scale_system.scale_kind(scale_kind_id).new self
		end
	end

	class ScaleKind
		extend Forwardable

		def initialize tuning
			@tuning = tuning
			@scales = {}
		end

		attr_reader :tuning

		def [] based_on_pitch
			@scales[based_on_pitch] = Scale.new self, based_on_pitch: based_on_pitch unless @scales.has_key? based_on_pitch
			@scales[based_on_pitch]
		end

		def new_scale based_on:
			Scale.new self, based_on_note: based_on
		end

		class << self
			# @abstract Subclass is expected to implement id
			# @!method id
			# 	Returns the id of the ScaleKind as a symbol
			def id
				raise "Method not implemented. Should be implemented in subclass."
			end

			# @abstract Subclass is expected to implement pitches
			# @!method pitches
			# 	Returns the pitches array of the ScaleKind as [ { functions: [ <symbol>, ...], pitch: <Number> }, ... ]
			def pitches
				raise "Method not implemented. Should be implemented in subclass."
			end

			def index_of symbol
				init unless @index
				raise KeyError, "Symbol :#{symbol} not found in scale kind #{self.id}" unless @index[symbol]

				@index[symbol]
			end

			def grades
				pitches.length
			end

			private

			def init
				@index = {}
				pitches.each_index do |i|
					pitches[i][:functions].each do |function|
						@index[function] = i
					end
				end
			end
		end
	end

	class Scale
		extend Forwardable

		def initialize kind, based_on_pitch: nil, based_on_note: nil
			raise ArgumentError, "One of the arguments based_on_pitch: or based_on_note: is required" unless based_on_pitch || based_on_note
			raise ArgumentError, "Only one of the arguments based_on_pitch: or based_on_note: can be initialized" if based_on_pitch && based_on_note

			@notes = {}

			@kind = kind

			@based_on_pitch = based_on_pitch
			@based_on_note = based_on_note

			@based_on_pitch ||= @based_on_note.pitch
			@based_on_note ||= self[0]
		end

		def_delegators :@kind, :la_tuning

		attr_reader :kind

		def based_on
			@based_on_note
		end

		def [] grade_or_symbol
			symbol = grade_or_symbol.to_sym if grade_or_symbol.is_a?(Symbol) || grade_or_symbol.is_a?(String)
			wide_grade = grade_or_symbol.to_i if grade_or_symbol.is_a? Numeric

			raise ArgumentError, "grade_or_symbol should be a Numeric, String or Symbol" unless wide_grade || symbol

			octave = wide_grade / @kind.class.grades if wide_grade
			grade = wide_grade % @kind.class.grades if wide_grade

			grade = @kind.class.index_of symbol if symbol

			octave ||= 0

			wide_grade = octave * @kind.class.grades + grade

			pitch = @based_on_pitch +
							octave * @kind.tuning.notes_in_octave +
							@kind.class.pitches[grade][:pitch]

			@notes[wide_grade] =
				NoteInScale.new \
					self,
					grade,
					octave,
					pitch,
					pitch2frequency(pitch),
					@kind.class.pitches[grade][:functions] unless @notes.has_key? wide_grade

			@notes[wide_grade]
		end

		def on scale
			# proyectar la escala sobre otra escala... notas comunes????
		end

		def pitch2frequency pitch
			(@kind.tuning.a_frequency * Rational(2) ** Rational(pitch - 69, 12)).to_f
		end
	end

	class NoteInScale
		def initialize scale, grade, octave, pitch, frequency, functions
			@scale = scale
			@grade = grade
			@octave = octave
			@pitch = pitch
			@frequency = frequency
			@functions = functions
		end

		attr_reader :scale, :grade, :pitch, :frequency, :functions

		def octave octave = nil
			if octave.nil?
				@octave
			else
				@scale[@grade + octave * @scale.kind.class.grades]
			end
		end

		def as_base_of kind_id
			@scale.kind.tuning[kind_id].new_scale based_on: self
		end

		def on scale
			# obtener la nota en la escala de destino que tiene el mismo pitch/frecuencia
		end
	end

	class Tempered12ToneScaleSystem < ScaleSystem
		class << self
			def id () :t12 end
			def notes_in_octave () 12 end
		end
		Scales.register Tempered12ToneScaleSystem
	end

	class MajorScaleKind < ScaleKind
		class << self
			def pitches
				# Functions from: https://en.wikipedia.org/wiki/Diatonic_function
				[	{ functions: [:I , :_1, :tonic, :T],
						pitch: 0 },
					{ functions: [:II, :_2, :supertonic, :subdominant_parallel, :Sp],
						pitch: 2 },
					{ functions: [:III, :_3, :mediant, :dominant_parallel, :Dp, :tonic_counter_parallel, :Tcp ],
						pitch: 4 },
					{ functions: [:IV, :_4, :subdominant, :S ],
						pitch: 5 },
					{ functions: [:V, :_5, :dominant, :D ],
						pitch: 7 },
					{ functions: [:VI, :_6, :submediant, :tonic_parallel, :Tp ],
						pitch: 9 },
					{ functions: [:VII, :_7, :leading ],
						pitch: 11 } ]
			end

			def id () :major end
		end

		Tempered12ToneScaleSystem.register MajorScaleKind
	end

	class MinorScaleKind < ScaleKind
		class << self
			def pitches
				# Functions from: https://en.wikipedia.org/wiki/Diatonic_function

				# TODO revisar y añadir melódicas y armónicas

				[	{ functions: [:i, :_1, :tonic, :t],
				 		pitch: 0 },
					{ functions: [:ii, :_2 ],
					 	pitch: 2 },
					{ functions: [:iii, :_3 ],
					 	pitch: 3 },
					{ functions: [:iv, :_4, :subdominant, :s ],
						pitch: 5 },
					{ functions: [:v, :_5, :dominant, :d ],
						pitch: 7 },
					{ functions: [:vi, :_6 ],
						pitch: 8 },
					{ functions: [:vii, :_7 ],
						pitch: 10 } ]
			end

			def id () :minor end
		end

		Tempered12ToneScaleSystem.register MinorScaleKind
	end

	class ChromaticScaleKind < ScaleKind
		class << self
			def pitches
				[	{ functions: [:_1],	pitch: 0 },
					{ functions: [:_2], pitch: 1 },
					{ functions: [:_3], pitch: 2 },
					{ functions: [:_4], pitch: 3 },
					{ functions: [:_5], pitch: 4 },
					{ functions: [:_6], pitch: 5 },
					{ functions: [:_7], pitch: 6 },
					{ functions: [:_8], pitch: 7 },
					{ functions: [:_9], pitch: 8 },
					{ functions: [:_10], pitch: 9 },
					{ functions: [:_11], pitch: 10 },
					{ functions: [:_12], pitch: 11 } ]
			end

			def id () :chromatic end
		end

		Tempered12ToneScaleSystem.register ChromaticScaleKind
	end

end

RSpec.describe Musa::Tempered12ToneScaleSystem do

	context "Tempered 12 semitones scales" do

		scale_system = Musa::Scales[:t12][440.0]

		it "Basic major scale pitch and functions" do

			scale = scale_system[:major][60]

			expect(scale.kind.class.id).to eq :major
			expect(scale.kind.class.grades).to eq 7
			expect(scale.based_on.pitch).to eq 60
			expect(scale.based_on.scale).to be scale

			expect(scale[0].grade).to eq 0
			expect(scale[0].octave).to eq 0

			expect(scale[0].pitch).to eq 60
			expect(scale[:I].pitch).to eq 60
			expect(scale[:T].pitch).to eq 60

			expect(scale[:I].functions).to include :tonic

			expect(scale[:V].pitch).to eq 67
			expect(scale[4].pitch).to eq 67
			expect(scale[:D].pitch).to eq 67

			expect(scale[:V].functions).to include :dominant

			expect(scale[:I].octave(-1).pitch).to eq 48
			expect(scale[:I].octave(-1).octave).to eq -1
			expect(scale[:I].octave(-1).grade).to eq 0

			expect(scale[0].octave(-1).pitch).to eq 48
		end

		it "Basic minor scale pitch and functions" do

			scale = scale_system[:minor][60]

			expect(scale.kind.class.id).to eq :minor
			expect(scale.based_on.pitch).to eq 60

			expect(scale[:i].functions).to include :tonic

			expect(scale[:iii].pitch).to eq 63
			expect(scale[2].pitch).to eq 63

			expect(scale[:d].pitch).to eq 67

			expect(scale[:v].functions).to include :dominant
		end

		it "Basic frequency testing" do
			scale = scale_system[:major][60]

			expect(scale[:VI].frequency).to eq 440.0
			expect(scale[:VI].pitch).to eq 69
			expect(scale[:VI].octave(-1).frequency).to eq 220.0
			expect(scale[:VI].octave(-1).pitch).to eq 69 - 12
		end

		it "Basic scale navigation" do
			scale = scale_system[:major][60]

			scale2 = scale[:V].as_base_of(:minor)

			expect(scale2.kind.class.id).to eq :minor
			expect(scale2.based_on.pitch).to eq 67
			expect(scale2.based_on.scale).to eq scale

			expect(scale2[0].pitch).to eq 67

			expect(scale.common_notes_with(scale2).first[0].grade).to eq 0
			expect(scale.common_notes_with(scale2).first[1].grade).to eq 3
		end

		it "Basic scale notes projection" do

			scale = scale_system[:major][60]
			scale2 = scale_system[:chromatic][61]

			expect(scale[0].on(scale2).grade).to eq 11
			expect(scale[0].on(scale2).octave).to eq 0
			expect(scale[0].on(scale2).pitch).to eq 60

			expect(scale[0].octave(-1).on(scale2).grade).to eq 11
			expect(scale[0].octave(-1).on(scale2).octave).to eq -1
			expect(scale[0].octave(-1).on(scale2).pitch).to eq 48
		end

		it "Basic scales projection" do

			scale = scale_system[:major][60]
			scale2 = scale_system[:chromatic][61]

			expect(scale.on(scale2).length).to eq 7

			expect(scale.on(scale2)[0][0].grade).to eq 0
			expect(scale.on(scale2)[0][1].grade).to eq 0

			expect(scale.on(scale2)[1][0].grade).to eq 1
			expect(scale.on(scale2)[1][1].grade).to eq 2

			expect(scale.on(scale2)[4][0].grade).to eq 4
			expect(scale.on(scale2)[4][1].grade).to eq 7
		end
  end
end
