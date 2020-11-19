module Musa
  module Scales
    module Scales
      def self.register(scale_system, default: nil)
        @scale_systems ||= {}
        @scale_systems[scale_system.id] = scale_system

        @default_scale_system = scale_system if default

        self.class.define_method scale_system.id do
          scale_system
        end

        self
      end

      def self.[](id)
        raise KeyError, "Scale system :#{id} not found" unless @scale_systems.key?(id)

        @scale_systems[id]
      end

      def self.default_system
        @default_scale_system
      end
    end

    class ScaleSystem
      # @abstract Subclass is expected to implement names
      # @!method id
      # @return [Symbol] the id of the ScaleSystem as a symbol
      #
      def self.id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement notes_in_octave
      # @!method notes_in_octave
      # @return [Integer] the number of notes in one octave in the ScaleSystem
      #
      def self.notes_in_octave
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement part_of_tone_size
      # @!method part_of_tone_size
      # @return [Integer] the size inside the ScaleSystem of the smaller part of a tone; used for calculate sharp and flat notes
      #
      def self.part_of_tone_size
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement intervals
      # @!method intervals
      # @return [Hash] the intervals of the ScaleSystem as { name: semitones#, ... }
      #
      def self.intervals
        # TODO: implementar intérvalos sinónimos (p.ej, m3 = A2)
        # TODO: implementar identificación de intérvalos, teniendo en cuenta no sólo los semitonos sino los grados de separación
        # TODO: implementar inversión de intérvalos
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement frequency_of_pitch
      # @!method frequency_of_pitch
      # @param pitch [Number] The pitch (MIDI note numbers based) of the note to get the fundamental frequency
      # @param root_pitch [Number] The pitch (MIDI note numbers based) of the root note of the scale (needed for not equally tempered scales)
      # @param a_frequency [Number] The reference frequency of the mid A note
      # @return [Number] the frequency of the fundamental tone of the pitch
      #
      def self.frequency_of_pitch(pitch, root_pitch, a_frequency)
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass can implement default_a_frequency. If subclass doesn't implement default_a_frequency 440.0 Hz is assumed.
      # @!method default_a_frequency
      # @return [Number] the frequency A by default
      #
      def self.default_a_frequency
        440.0
      end

      def self.[](a_frequency)
        a_frequency = a_frequency.to_f

        @a_tunings ||= {}
        @a_tunings[a_frequency] = ScaleSystemTuning.new self, a_frequency unless @a_tunings.key?(a_frequency)

        @a_tunings[a_frequency]
      end

      def self.offset_of_interval(name)
        intervals[name]
      end

      def self.default_tuning
        self[default_a_frequency]
      end

      def self.register(scale_kind_class)
        @scale_kind_classes ||= {}
        @scale_kind_classes[scale_kind_class.id] = scale_kind_class
        if scale_kind_class.chromatic?
          @chromatic_scale_kind_class = scale_kind_class
        end
        self
      end

      def self.scale_kind_class(id)
        raise KeyError, "Scale kind class [#{id}] not found in scale system [#{self.id}]" unless @scale_kind_classes.key? id

        @scale_kind_classes[id]
      end

      def self.scale_kind_class?(id)
        @scale_kind_classes.key? id
      end

      def self.scale_kind_classes
        @scale_kind_classes
      end

      def self.chromatic_class
        raise "Chromatic scale kind class for [#{self.id}] scale system undefined" if @chromatic_scale_kind_class.nil?

        @chromatic_scale_kind_class
      end

      def ==(other)
        self.class == other.class
      end
    end

    class ScaleSystemTuning
      extend Forwardable

      def initialize(scale_system, a_frequency)
        @scale_system = scale_system
        @a_frequency = a_frequency
        @scale_kinds = {}

        @chromatic_scale_kind = self[@scale_system.chromatic_class.id]

        @scale_system.scale_kind_classes.each_key do |name|
          define_singleton_method name do
            self[name]
          end
        end
      end

      # TODO: allow scales not based in octaves but in other intervals (like fifths or other ratios). Possibly based on intervals definition of ScaleSystem plus a "generator interval" attribute

      def_delegators :@scale_system, :notes_in_octave, :offset_of_interval

      attr_reader :a_frequency, :scale_system

      def [](scale_kind_class_id)
        @scale_kinds[scale_kind_class_id] ||= @scale_system.scale_kind_class(scale_kind_class_id).new self
      end

      def chromatic
        @chromatic_scale_kind
      end

      def frequency_of_pitch(pitch, root)
        @scale_system.frequency_of_pitch(pitch, root, @a_frequency)
      end

      def ==(other)
        self.class == other.class &&
            @scale_system == other.scale_system &&
            @a_frequency == other.a_frequency
      end

      def inspect
        "<ScaleSystemTuning: scale_system = #{@scale_system} a_frequency = #{@a_frequency}>"
      end

      alias to_s inspect
    end

    class ScaleKind
      extend Forwardable

      def initialize(tuning)
        @tuning = tuning
        @scales = {}
      end

      attr_reader :tuning

      def [](root_pitch)
        @scales[root_pitch] = Scale.new(self, root_pitch: root_pitch) unless @scales.key?(root_pitch)
        @scales[root_pitch]
      end

      def absolut
        self[0]
      end

      def ==(other)
        self.class == other.class && @tuning == other.tuning
      end

      def inspect
        "<#{self.class.name}: tuning = #{@tuning}>"
      end

      alias to_s inspect

      # @abstract Subclass is expected to implement id
      # @!method id
      # @return [Symbol] the id of the ScaleKind as a symbol
      def self.id
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement pitches
      # @!method pitches
      # @return [Array] the pitches array of the ScaleKind as [ { functions: [ <symbol>, ...], pitch: <Number> }, ... ]
      def self.pitches
        raise 'Method not implemented. Should be implemented in subclass.'
      end

      # @abstract Subclass is expected to implement chromatic?. Only one of the subclasses should return true.
      # @!method chromatic?
      # @return [Boolean] wether the scales is a full scale (with all the notes in the ScaleSystem), sorted and to be considered canonical. I.e. a chromatic 12 semitones uprising serie in a 12 tone tempered ScaleSystem.
      def self.chromatic?
        false
      end

      # @abstract Subclass is expected to implement grades when the ScaleKind is defining more pitches than notes by octave has the scale. This can happen when there are pitches defined on upper octaves (i.e., to define XII grade, as a octave + fifth)
      # @!method grades
      # @return [Integer] Number of grades inside of a octave of the scale
      def self.grades
        pitches.length
      end

      def self.grade_of_function(symbol)
        create_grade_functions_index unless @grade_names_index
        @grade_names_index[symbol]
      end

      def self.grades_functions
        create_grade_functions_index unless @grade_names_index
        @grade_names_index.keys
      end

      private

      def self.create_grade_functions_index
        @grade_names_index = {}
        pitches.each_index do |i|
          pitches[i][:functions].each do |function|
            @grade_names_index[function] = i
          end
        end

        self
      end
    end

    class Scale
      extend Forwardable

      def initialize(kind, root_pitch:)
        @notes_by_grade = {}
        @notes_by_pitch = {}

        @kind = kind

        @root_pitch = root_pitch

        @kind.class.grades_functions.each do |name|
          define_singleton_method name do
            self[name]
          end
        end

      end

      def_delegators :@kind, :a_tuning

      attr_reader :kind, :root_pitch

      def root
        self[0]
      end

      def chromatic
        @kind.tuning.chromatic[@root_pitch]
      end

      def absolut
        @kind[0]
      end

      def octave(octave)
        raise ArgumentError, "#{octave} is not integer" unless octave == octave.to_i

        @kind[@root_pitch + octave * @kind.class.grades]
      end

      def [](grade_or_symbol)

        raise ArgumentError, "grade_or_symbol '#{grade_or_symbol}' should be a Integer, String or Symbol" unless grade_or_symbol.is_a?(Symbol) || grade_or_symbol.is_a?(String) || grade_or_symbol.is_a?(Integer)

        wide_grade, sharps = grade_of(grade_or_symbol)

        unless @notes_by_grade.key?(wide_grade)

          octave = wide_grade / @kind.class.grades
          grade = wide_grade % @kind.class.grades

          pitch = @root_pitch +
              octave * @kind.tuning.notes_in_octave +
              @kind.class.pitches[grade][:pitch]

          note = NoteInScale.new self, grade, octave, pitch

          @notes_by_grade[wide_grade] = @notes_by_pitch[pitch] = note
        end


        @notes_by_grade[wide_grade].sharp(sharps)
      end

      def grade_of(grade_or_string_or_symbol)
        name, wide_grade, accidentals = parse_grade(grade_or_string_or_symbol)

        grade = @kind.class.grade_of_function name if name

        octave = wide_grade / @kind.class.grades if wide_grade
        grade = wide_grade % @kind.class.grades if wide_grade

        octave ||= 0

        return octave * @kind.class.grades + grade, accidentals
      end

      def parse_grade(neuma_grade)
        name = wide_grade = nil
        accidentals = 0

        case neuma_grade
        when Symbol, String
          match = /\A(?<name>[^[#|_]]*)(?<accidental_sharps>#*)(?<accidental_flats>_*)\Z/.match neuma_grade.to_s

          if match
            if match[:name] == match[:name].to_i.to_s
              wide_grade = match[:name].to_i
            else
              name = match[:name].to_sym unless match[:name].empty?
            end
            accidentals = match[:accidental_sharps].length - match[:accidental_flats].length
          else
            name = neuma_grade.to_sym unless (neuma_grade.nil? || neuma_grade.empty?)
          end
        when Numeric
          wide_grade = neuma_grade.to_i

        else
          raise ArgumentError, "Cannot eval #{neuma_grade} as name or grade position."
        end

        return name, wide_grade, accidentals
      end

      def note_of_pitch(pitch, allow_chromatic: nil, allow_nearest: nil)
        allow_chromatic ||= false
        allow_nearest ||= false

        note = @notes_by_pitch[pitch]

        unless note
          pitch_offset = pitch - @root_pitch

          pitch_offset_in_octave = pitch_offset % @kind.tuning.scale_system.notes_in_octave
          pitch_offset_octave = pitch_offset / @kind.tuning.scale_system.notes_in_octave

          grade = @kind.class.pitches.find_index { |pitch_definition| pitch_definition[:pitch] == pitch_offset_in_octave }

          if grade
            wide_grade = pitch_offset_octave * @kind.class.grades + grade
            note = self[wide_grade]

          elsif allow_nearest
            sharps = 0

            until note
              note = note_of_pitch(pitch - (sharps += 1) * @kind.tuning.scale_system.part_of_tone_size)
              note ||= note_of_pitch(pitch + sharps * @kind.tuning.scale_system.part_of_tone_size)
            end

          elsif allow_chromatic
            nearest = note_of_pitch(pitch, allow_nearest: true)

            note = chromatic.note_of_pitch(pitch).with_background(scale: self, grade: nearest.grade, octave: nearest.octave, sharps: (pitch - nearest.pitch) / @kind.tuning.scale_system.part_of_tone_size)
          end
        end

        note
      end

      def offset_of_interval(interval_name)
        @kind.tuning.offset_of_interval(interval_name)
      end

      def chord_of(*grades_or_symbols)
        Chord.new(notes: grades_or_symbols.collect { |g| self[g] })
      end

      def ==(other)
        self.class == other.class &&
            @kind == other.kind &&
            @root_pitch == other.root_pitch
      end

      def inspect
        "<Scale: kind = #{@kind} root_pitch = #{@root_pitch}>"
      end

      alias to_s inspect
    end

    class NoteInScale

      # @param scale [Scale]
      # @param grade []
      # @param octave [Integer]
      # @param pitch [Number] pitch of the note, based on MIDI note numbers. Can be Integer, Rational or Float to express fractions of a semitone
      #
      def initialize(scale, grade, octave, pitch, background_scale: nil, background_grade: nil, background_octave: nil, background_sharps: nil)
        @scale = scale
        @grade = grade
        @octave = octave
        @pitch = pitch

        @background_scale = background_scale
        @background_grade = background_grade
        @background_octave = background_octave
        @background_sharps = background_sharps

        @scale.kind.tuning.scale_system.scale_kind_classes.each_key do |name|
          define_singleton_method name do
            scale(name)
          end
        end
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

          @scale[@grade + (@octave + octave) * @scale.kind.class.grades]
        end
      end

      def with_background(scale:, grade: nil, octave: nil, sharps: nil)
        NoteInScale.new(@scale, @grade, @octave, @pitch,
                        background_scale: scale,
                        background_grade: grade,
                        background_octave: octave,
                        background_sharps: sharps)
      end

      attr_reader :background_scale

      def background_note
        @background_scale[@background_grade + (@background_octave || 0) * @background_scale.kind.class.grades] if @background_grade
      end

      attr_reader :background_sharps

      def wide_grade
        @grade + @octave * @scale.kind.class.grades
      end

      def up(interval_name_or_interval, natural_or_chromatic = nil, sign: nil)

        sign ||= 1

        if interval_name_or_interval.is_a?(Numeric)
          natural_or_chromatic ||= :natural
        else
          natural_or_chromatic = :chromatic
        end

        if natural_or_chromatic == :chromatic
          interval = if interval_name_or_interval.is_a?(Symbol)
                       @scale.kind.tuning.offset_of_interval(interval_name_or_interval)
                     else
                       interval_name_or_interval
                     end

          calculate_note_of_pitch(@pitch, sign * interval)
        else
          @scale[@grade + sign * interval_name_or_interval]
        end
      end

      def calculate_note_of_pitch(in_scale_pitch, sharps)
        pitch = in_scale_pitch + sharps * @scale.kind.tuning.scale_system.part_of_tone_size

        if pitch == @pitch
          self
        else
          note = @scale.note_of_pitch(pitch, allow_chromatic: true)
          if @background_scale
            note.on(@background_scale) || note
          else
            note
          end
        end
      end

      private :calculate_note_of_pitch

      def down(interval_name_or_interval, natural_or_chromatic = nil)
        up(interval_name_or_interval, natural_or_chromatic, sign: -1)
      end

      def sharp(count = nil)
        count ||= 1
        calculate_note_of_pitch(@pitch, count)
      end

      def flat(count = nil)
        count ||= 1
        sharp(-count)
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

      def chord(*feature_values, allow_chromatic: nil, **features_hash)
        features = { size: :triad } if feature_values.empty? && features_hash.empty?
        features ||= ChordDefinition.features_from(feature_values, features_hash)

        Musa::Chords::Chord.new(root: self, allow_chromatic: allow_chromatic, features: features)
      end

      def ==(other)
        self.class == other.class &&
            @scale == other.scale &&
            @grade == other.grade &&
            @octave == other.octave &&
            @pitch == other.pitch
      end

      def inspect
        "<NoteInScale: grade = #{@grade} octave = #{@octave} pitch = #{@pitch} scale = (#{@scale.kind.class.name} on #{scale.root_pitch})>"
      end

      alias to_s inspect
    end
  end
end
