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
			@scale_kinds = {}
		end

		# TODO allow scales not based in octaves but in other intervals (like fifths or other ratios)

		def_delegators :@scale_system, :notes_in_octave

		attr_reader :a_frequency, :scale_system

		def [] scale_kind_id
			@scale_kinds[scale_kind_id] = @scale_system.scale_kind(scale_kind_id).new self unless @scale_kinds.has_key? scale_kind_id
			@scale_kinds[scale_kind_id]
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

			def find_index symbol
				init unless @index
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

		def initialize kind, based_on_pitch:
			@notes_by_grade = {}
			@notes_by_pitch = {}

			@kind = kind

			@based_on_pitch = based_on_pitch
		end

		def_delegators :@kind, :la_tuning

		attr_reader :kind

		def based_on
			self[0]
		end

		def octave octave
			raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

			@kind[@based_on_pitch + octave * @kind.class.grades]
		end

		def [] grade_or_symbol
			symbol = grade_or_symbol.to_sym if grade_or_symbol.is_a?(Symbol) || grade_or_symbol.is_a?(String)
			wide_grade = grade_or_symbol.to_i if grade_or_symbol.is_a? Numeric

			raise ArgumentError, "grade_or_symbol should be a Numeric, String or Symbol" unless wide_grade || symbol

			octave = wide_grade / @kind.class.grades if wide_grade
			grade = wide_grade % @kind.class.grades if wide_grade

			grade = @kind.class.find_index symbol if symbol

			octave ||= 0

			wide_grade = octave * @kind.class.grades + grade

			unless @notes_by_grade.has_key? wide_grade

				pitch = @based_on_pitch +
								octave * @kind.tuning.notes_in_octave +
								@kind.class.pitches[grade][:pitch]

				note = NoteInScale.new self, grade, octave, pitch

				@notes_by_grade[wide_grade] = @notes_by_pitch[pitch] = note
			end

			@notes_by_grade[wide_grade]
		end

		def note_of_pitch pitch
			note = @notes_by_pitch[pitch]

			unless note
				pitch_offset = pitch - @based_on_pitch

				pitch_offset_in_octave = pitch_offset % @kind.class.grades
				pitch_offset_octave = pitch_offset / @kind.class.grades

				grade = @kind.class.pitches.find_index { |pitch_definition| pitch_definition[:pitch] == pitch_offset_in_octave }

				return nil unless grade

				wide_grade = pitch_offset_octave * @kind.class.grades + grade

				note = self[wide_grade]
			end

			note
		end

		def chord_of *grades_or_symbols

		end

		private

		def method_missing method_name, *args, **key_args, &block
			if args.empty? && key_args.empty? && !block
				self[method_name] || super
			else
				super
			end
		end

		def respond_to_missing? method_name, include_private
			@kind.class.find_index(method_name) || super
		end
	end

	class NoteInScale
		def initialize scale, grade, octave, pitch
			@scale = scale
			@grade = grade
			@octave = octave
			@pitch = pitch # MIDI note, can be Rational or Float to express parts of semitone
		end

		attr_reader :grade, :pitch

		def functions
			@scale.kind.class.pitches[grade][:functions]
		end

		def octave octave = nil
			if octave.nil?
				@octave
			else
				raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

				@scale[@grade + octave * @scale.kind.class.grades]
			end
		end

		def frequency
			# TODO allow different tuning systems (well tempered, perfect thirds, perfect fifths, etc) to be inherited from ScaleSystem
			(@scale.kind.tuning.a_frequency * Rational(2) ** Rational(@pitch - 69, 12)).to_f
		end

		def scale kind_id = nil
			if kind_id.nil?
				@scale
			else
				@scale.kind.tuning[kind_id][@pitch]
			end
		end

		def on scale
			scale.note_of_pitch @pitch
		end

		def chord size_or_interval = nil, features
			size_or_interval ||= 3


		end

		private

		def method_missing method_name, *args, **key_args, &block
			if args.empty? && key_args.empty? && !block
				scale(method_name) || super
			else
				super
			end
		end

		def respond_to_missing? method_name, include_private
			@scale.kind.class.tuning[method_name] || super
		end
	end

	class Chord
		def initialize
		end

		def scale
		end

		def fundamental
		end

		def [] position
		end

		def features
		end

		def size
		end

		def match cosas
		end

		alias length size

		private

		# minor, major, ...? features?

		def method_missing method_name, *args, **key_args, &block
			if args.empty? && key_args.empty? && !block
				scale(method_name) || super
			else
				super
			end
		end

		def respond_to_missing? method_name, include_private
			@scale.kind.class.tuning[method_name] || super
		end

	end

	class EquallyTempered12ToneScaleSystem < ScaleSystem
		class << self
			def id () :et12 end
			def notes_in_octave () 12 end
		end
		Scales.register EquallyTempered12ToneScaleSystem
	end

	class MajorScaleKind < ScaleKind
		class << self
			@@pitches =
			[	{ functions: [ :I , :_1, :tonic ],
					pitch: 0 },
				{ functions: [ :II, :_2, :supertonic ],
					pitch: 2 },
				{ functions: [ :III, :_3, :mediant ],
					pitch: 4 },
				{ functions: [ :IV, :_4, :subdominant ],
					pitch: 5 },
				{ functions: [ :V, :_5, :dominant ],
					pitch: 7 },
				{ functions: [ :VI, :_6, :submediant, :relative, :relative_minor ],
					pitch: 9 },
				{ functions: [ :VII, :_7, :leading ],
					pitch: 11 } ].freeze

			def pitches () @@pitches end
			def id () :major end
		end

		EquallyTempered12ToneScaleSystem.register MajorScaleKind
	end

	class MinorScaleKind < ScaleKind
		class << self
			@@pitches =
			[	{ functions: [:i, :_1, :tonic ],
			 		pitch: 0 },
				{ functions: [:ii, :_2, :supertonic ],
				 	pitch: 2 },
				{ functions: [:iii, :_3, :mediant, :relative, :relative_major ],
				 	pitch: 3 },
				{ functions: [:iv, :_4, :subdominant ],
					pitch: 5 },
				{ functions: [:v, :_5, :dominant ],
					pitch: 7 },
				{ functions: [:vi, :_6, :submediant ],
					pitch: 8 },
				{ functions: [:vii, :_7 ],
					pitch: 10 } ].freeze

			def pitches () @@pitches end
			def id () :minor end
		end

		EquallyTempered12ToneScaleSystem.register MinorScaleKind
	end

	class MinorHarmonicScaleKind < ScaleKind
		class << self
			@@pitches =
			[	{ functions: [:i, :_1, :tonic ],
			 		pitch: 0 },
				{ functions: [:ii, :_2, :supertonic ],
				 	pitch: 2 },
				{ functions: [:iii, :_3, :mediant, :relative, :relative_major ],
				 	pitch: 3 },
				{ functions: [:iv, :_4, :subdominant ],
					pitch: 5 },
				{ functions: [:v, :_5, :dominant ],
					pitch: 7 },
				{ functions: [:vi, :_6, :submediant ],
					pitch: 8 },
				{ functions: [:vii, :_7, :leading ],
					pitch: 11 } ].freeze

			def pitches () @@pitches end
			def id () :minor_harmonic end
		end

		EquallyTempered12ToneScaleSystem.register MinorHarmonicScaleKind
	end

	class ChromaticScaleKind < ScaleKind
		class << self
			@@pitches =
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
				{ functions: [:_12], pitch: 11 } ].freeze

			def pitches () @@pitches end
			def id () :chromatic end
		end

		EquallyTempered12ToneScaleSystem.register ChromaticScaleKind
	end
end

RSpec.describe Musa::EquallyTempered12ToneScaleSystem do

	context "Equally tempered 12 semitones scales" do

		scale_system = Musa::Scales[:et12][440.0]

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
			expect(scale.I.pitch).to eq 60
			expect(scale.tonic.pitch).to eq 60

			expect(scale[:tonic].pitch).to eq 60
			expect(scale.tonic.pitch).to eq 60

			expect(scale[:I].functions).to include :tonic

			expect(scale[:V].pitch).to eq 67
			expect(scale[4].pitch).to eq 67
			expect(scale[:dominant].pitch).to eq 67
			expect(scale.dominant.pitch).to eq 67

			expect(scale[:V].functions).to include :dominant

			expect(scale[:I].octave(-1).pitch).to eq 48
			expect(scale[:I].octave(-1).octave).to eq -1
			expect(scale[:I].octave(-1).grade).to eq 0
			expect(scale.tonic.octave(-1).grade).to eq 0

			expect(scale[0].octave(-1).pitch).to eq 48
		end

		it "Basic minor scale pitch and functions" do

			scale = scale_system[:minor][60]

			expect(scale.kind.class.id).to eq :minor
			expect(scale.based_on.pitch).to eq 60

			expect(scale[:i].functions).to include :tonic

			expect(scale[:iii].pitch).to eq 63
			expect(scale[2].pitch).to eq 63

			expect(scale[:dominant].pitch).to eq 67

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

			scale2 = scale.relative_minor.octave(-1).scale(:minor)
			scale3 = scale.relative_minor.octave(-1).minor

			expect(scale2).to eq scale3

			expect(scale2.kind.class.id).to eq :minor
			expect(scale2.based_on.pitch).to eq 57
			expect(scale2.based_on.scale).to eq scale2
			expect(scale2.relative_major.major).to eq scale

			expect(scale2.tonic.pitch).to eq 57
		end

		it "Basic scale notes projection" do

			scale = scale_system[:major][60]
			scale2 = scale_system[:chromatic][61]

			expect(scale[0].on(scale2).grade).to eq 11
			expect(scale[0].on(scale2).octave).to eq -1
			expect(scale[0].on(scale2).pitch).to eq 60

			expect(scale[0].octave(-1).on(scale2).grade).to eq 11
			expect(scale[0].octave(-1).on(scale2).octave).to eq -2
			expect(scale[0].octave(-1).on(scale2).pitch).to eq 48
		end
  end

	context "Chords in equally tempered 12 tone scales" do

		scale_system = Musa::Scales[:et12][440.0]

		major = scale_system[:major][60]
		minor = major.octave(-1).relative_minor.scale(:minor)
		chromatic = scale_system[:chromatic][60]

		it "Basic triad major chord creation" do
			maj3 = major.tonic.chord
			expect(maj3.scale).to be major
			expect(maj3.fundamental.pitch).to eq 60
			expect(maj3.features).to include :major

			expect(maj3[0].pitch).to eq 60
			expect(maj3[0].grade).to eq 0
			expect(maj3[0].octave).to eq 0
			expect(maj3[0].scale).to be major

			expect(maj3[1].pitch).to eq 64
			expect(maj3[1].grade).to eq 2
			expect(maj3[1].octave).to eq 0
			expect(maj3[1].scale).to be major

			expect(maj3[2].pitch).to eq 67
			expect(maj3[2].grade).to eq 4
			expect(maj3[2].octave).to eq 0
			expect(maj3[2].scale).to be major

			expect(maj3[3]).to eq nil
			expect(maj3.size).to eq 3
			expect(maj3.length).to eq 3
		end

		it "Basic triad major to minor chord navigation" do

			maj3 = major.tonic.chord

			min3 = maj3.minor

			expect(min3.scale).to eq nil
			expect(min3.fundamental.pitch).to eq 60
			expect(min3.features).to include :minor

			expect(min3[0].pitch).to eq 60
			expect(min3[0].grade).to eq 0
			expect(min3[0].octave).to eq 0
			expect(min3[0].scale).to be major

			expect(min3[1].pitch).to eq 63
			expect(min3[1].grade).to eq nil
			expect(min3[1].octave).to eq nil
			expect(min3[1].scale).to eq nil

			expect(min3[2].pitch).to eq 67
			expect(min3[2].grade).to eq 4
			expect(min3[2].octave).to eq 0
			expect(min3min3[2].scale).to be major

			expect(maj3[3]).to eq nil
			expect(min3.size).to eq 3
			expect(min3.length).to eq 3
		end

		it "Basic triad major to minor chord navigation with modal change" do

			maj3 = major.tonic.chord

			min3 = maj3.minor

			matches = min3.match(major.tonic.minor, major.relative_minor.minor, chomatic)

			expect(matches.size).to eq 2

			chord = matches[0]

			expect(chord.scale).to be scale_system[:minor][60]
			expect(chord.fundamental.pitch).to eq 60

			expect(chord[0].scale).to be scale_system[:minor][60]
			expect(chord[1].scale).to be scale_system[:minor][60]
			expect(chord[2].scale).to be scale_system[:minor][60]

			chord = matches[1]

			expect(chord.scale).to be scale_system[:chromatic][60]
			expect(chord.fundamental.pitch).to eq 60

			expect(chord[0].scale).to be scale_system[:chromatic][60]
			expect(chord[1].scale).to be scale_system[:chromatic][60]
			expect(chord[2].scale).to be scale_system[:chromatic][60]
		end

		it "Basic triad chord chromatically defined to major chord navigation" do

			c3 = chromatic.chord_of 0, 3, 7

			maj3 = c3.match(major)

			expect(maj3.scale).to be major
			expect(maj3.fundamental.pitch).to eq 60
			expect(maj3.features).to include :major

			expect(maj3[0].pitch).to eq 60
			expect(maj3[0].octave).to eq 0
			expect(maj3[0].scale).to be major

			expect(maj3[1].pitch).to eq 64
			expect(maj3[1].octave).to eq 0
			expect(maj3[1].scale).to be major

			expect(maj3[2].pitch).to eq 67
			expect(maj3[2].octave).to eq 0
			expect(maj3[2].scale).to be major

			expect(maj3[3]).to eq nil
			expect(maj3.size).to eq 3
			expect(maj3.length).to eq 3
		end

		it "..." do
			c = major.dominant.chord 2

			expect(c[0].pitch).to eq 67
			expect(c[1].pitch).to eq 71
			expect(c[2]).to eq nil

			expect(c.size).to eq 2

			c = major.dominant.chord 3
			expect(c[0].pitch).to eq 67
			expect(c[1].pitch).to eq 71
			expect(c[2].pitch).to eq 74
			expect(c[3]).to eq nil

			expect(c.size).to eq 3

			c = major.dominant.chord :seventh
			cb = major.dominant.chord 4

			expect(c).to be cb

			expect(c[0].pitch).to eq 67
			expect(c[1].pitch).to eq 71
			expect(c[2].pitch).to eq 74
			expect(c[3].pitch).to eq 77
			expect(c[4]).to eq nil

			expect(c.size).to eq 4

			c = major.dominant.chord :ninth
			cb = major.dominant.chord 5

			expect(c).to be cb

			expect(c[0].pitch).to eq 67
			expect(c[1].pitch).to eq 71
			expect(c[2].pitch).to eq 74
			expect(c[3].pitch).to eq 77
			expect(c[4].pitch).to eq 81
			expect(c[5]).to eq nil

			expect(c.size).to eq 5

			c = major.dominant.chord :eleventh
			cb = major.dominant.chord 6

			expect(c).to be cb

			expect(c[0].pitch).to eq 67
			expect(c[1].pitch).to eq 71
			expect(c[2].pitch).to eq 74
			expect(c[3].pitch).to eq 77
			expect(c[4].pitch).to eq 81
			expect(c[5].pitch).to eq 84
			expect(c[6]).to eq nil

			expect(c.size).to eq 6

			c = major.dominant.chord :thirteenth
			cb = major.dominant.chord 7

			expect(c[0].pitch).to eq 67
			expect(c[1].pitch).to eq 71
			expect(c[2].pitch).to eq 74
			expect(c[3].pitch).to eq 77
			expect(c[4].pitch).to eq 81
			expect(c[5].pitch).to eq 84
			expect(c[6].pitch).to eq 88
			expect(c[7]).to eq nil

			expect(c.size).to eq 7

		end


		it "" do

			major.dominant.octave(-1).major.dominant.chord :seventh # V/V
		end

		it "" do



			c1 = major.tonic.chord inversion: 1

			#c1 = major.tonic.chord(inversion: 1, { duplicate: :fundamental, octave: -1 })

			#c1 = major.tonic.chord(:minor, inversion: 1, { duplicate: :fundamn, octave: -1 })

			c1 = major.dominant.chord 2, inversion: 1

			c1 = major.dominant.chord 3, inversion: 1

			c1 = major.dominant.chord :seventh, inversion: 1
			c1 = major.dominant.chord 4, inversion: 1

			c1 = major.dominant.chord :ninth, inversion: 1
			c1 = major.dominant.chord 5, inversion: 1

			c1 = major.dominant.chord :eleventh, inversion: 1
			c1 = major.dominant.chord 6, inversion: 1

			c1 = major.dominant.chord :thirteenth, inversion: 1
			c1 = major.dominant.chord 7, inversion: 1



		end
	end
end
