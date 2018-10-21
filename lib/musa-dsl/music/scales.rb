module Musa
  module Scales
    @@scale_systems = {}

    class << self
      def register(scale_system)
        @@scale_systems[scale_system.id] = scale_system
      end

      def [](id)
        raise KeyError, "Scale system :#{id} not found" unless @@scale_systems.key? id

        @@scale_systems[id]
      end
    end
  end

  class ScaleSystem
    class << self
      # @abstract Subclass is expected to implement names
      # @!method id
      #   Returns the id of the ScaleSystem as a symbol
      def id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement notes_in_octave
      # @!method notes_in_octave
      #   Returns the number of notes in one octave in the ScaleSystem
      def notes_in_octave
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      def [](a_frequency)
        a_frequency = a_frequency.to_f

        @a_tunings ||= {}
        @a_tunings[a_frequency] = ScaleSystemTuning.new self, a_frequency unless @a_tunings.key? a_frequency

        @a_tunings[a_frequency]
      end

      def register(scale_kind)
        @scale_kinds ||= {}
        @scale_kinds[scale_kind.id] = scale_kind
      end

      def scale_kind(id)
        raise KeyError, "Scale kind :#{id} not found in scale system :#{self.id}" unless @scale_kinds.key? id

        @scale_kinds[id]
      end
    end
  end

  class ScaleSystemTuning
    extend Forwardable

    def initialize(scale_system, a_frequency)
      @scale_system = scale_system
      @a_frequency = a_frequency
      @scale_kinds = {}
    end

    # TODO: allow scales not based in octaves but in other intervals (like fifths or other ratios)

    def_delegators :@scale_system, :notes_in_octave

    attr_reader :a_frequency, :scale_system

    def [](scale_kind_id)
      @scale_kinds[scale_kind_id] = @scale_system.scale_kind(scale_kind_id).new self unless @scale_kinds.key? scale_kind_id
      @scale_kinds[scale_kind_id]
    end
  end

  class ScaleKind
    extend Forwardable

    def initialize(tuning)
      @tuning = tuning
      @scales = {}
    end

    attr_reader :tuning

    def [](based_on_pitch)
      @scales[based_on_pitch] = Scale.new(self, based_on_pitch: based_on_pitch) unless @scales.key? based_on_pitch
      @scales[based_on_pitch]
    end

    class << self
      # @abstract Subclass is expected to implement id
      # @!method id
      #   Returns the id of the ScaleKind as a symbol
      def id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement pitches
      # @!method pitches
      #   Returns the pitches array of the ScaleKind as [ { functions: [ <symbol>, ...], pitch: <Number> }, ... ]
      def pitches
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      def find_index(symbol)
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

    def initialize(kind, based_on_pitch:)
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

    def chromatic
      # TODO: devuelve la escala cromática que tiene la misma fundamental (como abreviación)
    end

    def octave(octave)
      raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

      @kind[@based_on_pitch + octave * @kind.class.grades]
    end

    def [](grade_or_symbol)
      symbol = grade_or_symbol.to_sym if grade_or_symbol.is_a?(Symbol) || grade_or_symbol.is_a?(String)
      wide_grade = grade_or_symbol.to_i if grade_or_symbol.is_a? Numeric

      raise ArgumentError, 'grade_or_symbol should be a Numeric, String or Symbol' unless wide_grade || symbol

      octave = wide_grade / @kind.class.grades if wide_grade
      grade = wide_grade % @kind.class.grades if wide_grade

      grade = @kind.class.find_index symbol if symbol

      octave ||= 0

      wide_grade = octave * @kind.class.grades + grade

      unless @notes_by_grade.key? wide_grade

        pitch = @based_on_pitch +
            octave * @kind.tuning.notes_in_octave +
            @kind.class.pitches[grade][:pitch]

        note = NoteInScale.new self, grade, octave, pitch

        @notes_by_grade[wide_grade] = @notes_by_pitch[pitch] = note
      end

      @notes_by_grade[wide_grade]
    end

    def note_of_pitch(pitch)
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

    def chord_of(*grades_or_symbols)
    end

    private

    def method_missing(method_name, *args, **key_args, &block)
      if args.empty? && key_args.empty? && !block
        self[method_name] || super
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private)
      @kind.class.find_index(method_name) || super
    end
  end

  class NoteInScale
    def initialize(scale, grade, octave, pitch)
      @scale = scale
      @grade = grade
      @octave = octave
      @pitch = pitch # MIDI note, can be Rational or Float to express parts of semitone
    end

    attr_reader :grade, :pitch

    def functions
      @scale.kind.class.pitches[grade][:functions]
    end

    def octave(octave = nil)
      if octave.nil?
        @octave
      else
        raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

        @scale[@grade + octave * @scale.kind.class.grades]
      end
    end

    def up(interval = nil, natural: nil, chromatic: nil)
      interval ||= 1
      # TODO: sube un intérvalo de interval tonos (natural true) o semitonos (chromatic true)
    end

    def down(interval)
      interval ||= 1
      # TODO:
    end

    def frequency
      # TODO: allow different tuning systems (well tempered, perfect thirds, perfect fifths, etc) to be inherited from ScaleSystem
      (@scale.kind.tuning.a_frequency * Rational(2)**Rational(@pitch - 69, 12)).to_f
    end

    def scale(kind_id = nil)
      if kind_id.nil?
        @scale
      else
        @scale.kind.tuning[kind_id][@pitch]
      end
    end

    def on(scale)
      scale.note_of_pitch @pitch
    end

    def chord(size_or_interval = nil, **features)
      size_or_interval ||= 3

      puts "Note.chord: size_or_interval = #{size_or_interval} features = #{features}"
      # TODO: ...


      { :major, 3, [0, 4, 7] }
      { :major, 4, [0, 4, 7, 11] }

      { :minor, 3, [0, 3, 7] }
      { [:minor, :diminished], 3, [0, 3, 6] }

    end

    private

    def method_missing(method_name, *args, **key_args, &block)
      if args.empty? && key_args.empty? && !block
        scale(method_name) || super
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private)
      @scale.kind.class.tuning[method_name] || super
    end
  end
  class EquallyTempered12ToneScaleSystem < ScaleSystem
    class << self
      def id
        :et12
      end

      def notes_in_octave
        12
      end
    end
    Scales.register EquallyTempered12ToneScaleSystem
  end

  class MajorScaleKind < ScaleKind
    class << self
      @@pitches =
          [{ functions: %i[I _1 tonic],
             pitch: 0 },
           { functions: %i[II _2 supertonic],
             pitch: 2 },
           { functions: %i[III _3 mediant],
             pitch: 4 },
           { functions: %i[IV _4 subdominant],
             pitch: 5 },
           { functions: %i[V _5 dominant],
             pitch: 7 },
           { functions: %i[VI _6 submediant relative relative_minor],
             pitch: 9 },
           { functions: %i[VII _7 leading],
             pitch: 11 }].freeze

      def pitches
        @@pitches
      end

      def id
        :major
      end
    end

    EquallyTempered12ToneScaleSystem.register MajorScaleKind
  end

  class MinorScaleKind < ScaleKind
    class << self
      @@pitches =
          [{ functions: %i[i _1 tonic],
             pitch: 0 },
           { functions: %i[ii _2 supertonic],
             pitch: 2 },
           { functions: %i[iii _3 mediant relative relative_major],
             pitch: 3 },
           { functions: %i[iv _4 subdominant],
             pitch: 5 },
           { functions: %i[v _5 dominant],
             pitch: 7 },
           { functions: %i[vi _6 submediant],
             pitch: 8 },
           { functions: %i[vii _7],
             pitch: 10 }].freeze

      def pitches
        @@pitches
      end

      def id
        :minor
      end
    end

    EquallyTempered12ToneScaleSystem.register MinorScaleKind
  end

  class MinorHarmonicScaleKind < ScaleKind
    class << self
      @@pitches =
          [{ functions: %i[i _1 tonic],
             pitch: 0 },
           { functions: %i[ii _2 supertonic],
             pitch: 2 },
           { functions: %i[iii _3 mediant relative relative_major],
             pitch: 3 },
           { functions: %i[iv _4 subdominant],
             pitch: 5 },
           { functions: %i[v _5 dominant],
             pitch: 7 },
           { functions: %i[vi _6 submediant],
             pitch: 8 },
           { functions: %i[vii _7 leading],
             pitch: 11 }].freeze

      def pitches
        @@pitches
      end

      def id
        :minor_harmonic
      end
    end

    EquallyTempered12ToneScaleSystem.register MinorHarmonicScaleKind
  end

  class ChromaticScaleKind < ScaleKind
    class << self
      @@pitches =
          [{ functions: [:_1], pitch: 0 },
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
           { functions: [:_12], pitch: 11 }].freeze

      def pitches
        @@pitches
      end

      def id
        :chromatic
      end
    end

    EquallyTempered12ToneScaleSystem.register ChromaticScaleKind
  end
end
