module Musa
  module Scales
    class << self
      def register(scale_system)
        @scale_systems ||= {}
        @scale_systems[scale_system.id] = scale_system
        self
      end

      def [](id)
        raise KeyError, "Scale system :#{id} not found" unless @scale_systems.key? id

        @scale_systems[id]
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
        @scale_systems.has_key?(method_name) || super
      end
    end
  end

  class ScaleSystem
    class << self
      # @abstract Subclass is expected to implement names
      # @!method id
      # @return [Symbol] the id of the ScaleSystem as a symbol
      #
      def id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement notes_in_octave
      # @!method notes_in_octave
      # @return [Integer] the number of notes in one octave in the ScaleSystem
      #
      def notes_in_octave
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement frequency_of_pitch
      # @!method frequency_of_pitch
      # @param pitch [Number] The pitch (MIDI note numbers based) of the note to get the fundamental frequency
      # @param root_pitch [Number] The pitch (MIDI note numbers based) of the root note of the scale (needed for not equally tempered scales)
      # @param a_frequency [Number] The reference frequency of the mid A note
      # @return [Number] the frequency of the fundamental tone of the pitch
      #
      def frequency_of_pitch(pitch, root_pitch, a_frequency)
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      def [](a_frequency)
        a_frequency = a_frequency.to_f

        @a_tunings ||= {}
        @a_tunings[a_frequency] = ScaleSystemTuning.new self, a_frequency unless @a_tunings.key? a_frequency

        @a_tunings[a_frequency]
      end

      def register(scale_kind_class)
        @scale_kind_classes ||= {}
        @scale_kind_classes[scale_kind_class.id] = scale_kind_class
        if scale_kind_class.full_canonical?
          @full_canonical_scale_kind_class = scale_kind_class
        end
        self
      end

      def scale_kind_class(id)
        raise KeyError, "Scale kind class [#{id}] not found in scale system [#{self.id}]" unless @scale_kind_classes.key? id

        @scale_kind_classes[id]
      end

      def scale_kind_class?(id)
        @scale_kind_classes.key? id
      end

      def full_canonical_class
        raise "Full-canonical scale kind class for [#{self.id}] scale system undefined" if @full_canonical_scale_kind_class.nil?

        @full_canonical_scale_kind_class
      end
    end
  end

  class ScaleSystemTuning
    extend Forwardable

    def initialize(scale_system, a_frequency)
      @scale_system = scale_system
      @a_frequency = a_frequency
      @scale_kinds = {}

      @canonical_scale_kind = self[@scale_system.full_canonical_class.id]
    end

    # TODO: allow scales not based in octaves but in other intervals (like fifths or other ratios)

    def_delegators :@scale_system, :notes_in_octave

    attr_reader :a_frequency, :scale_system

    def [](scale_kind_class_id)
      @scale_kinds[scale_kind_class_id] ||= @scale_system.scale_kind_class(scale_kind_class_id).new self
    end

    def full_canonical
      @canonical_scale_kind
    end

    def frequency_of_pitch(pitch, root)
      @scale_system.frequency_of_pitch(pitch, root, @a_frequency)
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
      @scale_system.scale_kind_class?(method_name) || super
    end
  end

  class ScaleKind
    extend Forwardable

    def initialize(tuning)
      @tuning = tuning
      @scales = {}
    end

    attr_reader :tuning

    def [](root_pitch)
      @scales[root_pitch] = Scale.new(self, root_pitch: root_pitch) unless @scales.key? root_pitch
      @scales[root_pitch]
    end

    class << self
      # @abstract Subclass is expected to implement id
      # @!method id
      # @return [Symbol] the id of the ScaleKind as a symbol
      def id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement pitches
      # @!method pitches
      # @return [Array] the pitches array of the ScaleKind as [ { functions: [ <symbol>, ...], pitch: <Number> }, ... ]
      def pitches
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement full_canonical?. Only one of the subclasses should return true.
      # @!method full_canonical?
      # @return [Boolean] wether the scales is a full scale (with all the notes in the ScaleSystem), sorted and to be considered canonical. I.e. a chromatic 12 semitones uprising serie in a 12 tone tempered ScaleSystem.
      def full_canonical?
        false
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
        self
      end
    end
  end

  class Scale
    extend Forwardable

    def initialize(kind, root_pitch:)
      @notes_by_grade = {}
      @notes_by_pitch = {}

      @kind = kind

      @root_pitch = root_pitch
    end

    def_delegators :@kind, :a_tuning

    attr_reader :kind

    def root
      self[0]
    end

    def full_canonical
      @kind.tuning.full_canonical[@root_pitch]
    end

    alias chromatic full_canonical

    def octave(octave)
      raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

      @kind[@root_pitch + octave * @kind.class.grades]
    end

    def [](grade_or_symbol)
      wide_grade = grade_of(grade_or_symbol)

      unless @notes_by_grade.key? wide_grade

        pitch = @root_pitch +
                octave * @kind.tuning.notes_in_octave +
                @kind.class.pitches[grade][:pitch]

        note = NoteInScale.new self, grade, octave, pitch

        @notes_by_grade[wide_grade] = @notes_by_pitch[pitch] = note
      end

      @notes_by_grade[wide_grade]
    end

    def grade_of(grade_or_symbol)
      symbol = grade_or_symbol.to_sym if grade_or_symbol.is_a?(Symbol) || grade_or_symbol.is_a?(String)
      wide_grade = grade_or_symbol.to_i if grade_or_symbol.is_a? Numeric

      raise ArgumentError, 'grade_or_symbol should be a Numeric, String or Symbol' unless wide_grade || symbol

      octave = wide_grade / @kind.class.grades if wide_grade
      grade = wide_grade % @kind.class.grades if wide_grade

      grade = @kind.class.find_index symbol if symbol

      octave ||= 0

      octave * @kind.class.grades + grade
    end

    def note_of_pitch(pitch)
      note = @notes_by_pitch[pitch]

      unless note
        pitch_offset = pitch - @root_pitch

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
      # TODO: implementar Scale.chord_of
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

    # @param scale [Scale]
    # @param grade []
    # @param octave [Integer]
    # @param pitch [Number] pitch of the note, based on MIDI note numbers. Can be Integer, Rational or Float to express fractions of a semitone
    #
    def initialize(scale, grade, octave, pitch)
      @scale = scale
      @grade = grade
      @octave = octave
      @pitch = pitch
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

    def down(interval, natural: nil, chromatic: nil)
      interval ||= 1
      # TODO:
    end

    def frequency
      @scale.kind.tuning.frequency_of_pitch(@pitch, @scale.root)
    end

    def scale(kind_id_or_kind = nil)
      if kind_id_or_kind.nil?
        @scale
      else
        if kind_id_or_kind.is_a? ScaleKind
          kind_id_or_kind[@pitch]
        else
          @scale.kind.tuning[kind_id_or_kind][@pitch]
        end
      end
    end

    def on(scale)
      scale.note_of_pitch @pitch
    end

    def chord(size_or_interval = nil, **features)
      size_or_interval ||= 3

      puts "Note.chord: size_or_interval = #{size_or_interval} features = #{features}"
      # TODO: implementar NoteInScale.chord
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
end
