require_relative 'scales'

=begin
c = Chord.new root: 60, # root: major.tonic,
              scale_system: nil, # scale_system[:major],
              scale: nil, # major,
              notes: [1, 2, 3],
              add: [0, :m6, NoteInScale],
              # NO: specie: :major,
              name: :major, # :minor, :maj7, :min
              size: 3, # :fifth, :seventh, :sixth?, ...
              # NO: generative_interval: :third, # :fourth, :fifth?
              inversion: 1,
              state: :third,
              position: :fifth,
              duplicate: { third: -1 },
              move: { fifth: 1 },
              drop: { third: 0 } # drop: :third, drop: [ :third, :root ]
=end

module Musa
  class ChordDefinition
    class << self
      def [](name)
        @definitions[name]
      end

      def register(name, offsets:, **features)
        definition = ChordDefinition.new(name, offsets: offsets, **features)

        @definitions ||= {}
        @definitions[definition.name] = definition

        @features_by_value ||= {}
        definition.features.each { |k, v| @features_by_value[v] = k }

        self
      end

      def find_by_pitches(pitches)
        @definitions.values.find { |d| d.matches(pitches) }
      end

      def find_by_features(feature_values_or_features)
        feature_values_or_features = [feature_values_or_features] if feature_values_or_features.is_a?(Symbol)

        case feature_values_or_features
        when Array
          features = feature_values_or_features.collect { |v| [@features_by_value[v], v] }.to_h
        when Hash
          features = feature_values_or_features
        else
          raise ArgumentError, "Don't know how to find features #{feature_values_or_features}"
        end

        @definitions.values.select { |d| features <= d.features }
      end

      def feature_key_of(feature_value)
        @features_by_value[feature_value]
      end
    end

    def initialize(name, offsets:, **features)
      @name = name
      @features = features.clone.freeze
      @pitch_offsets = offsets.clone.freeze
      @pitch_names = offsets.collect { |k, v| [v, k] }.to_h
    end

    attr_reader :name, :features, :pitch_offsets, :pitch_names

    def pitches(root_pitch)
      @pitch_offsets.values.collect { |offset| root_pitch + offset }
    end

    def named_pitches(elements_or_pitches, &block)
      pitches = elements_or_pitches.collect do |element_or_pitch|
        [if block
           yield element_or_pitch
         else
           element_or_pitch
         end,
         element_or_pitch]
      end.to_h

      root_pitch = pitches.keys.find do |candidate_root_pitch|
        candidate_pitches = pitches.keys.collect { |p| p - candidate_root_pitch }
        octave_reduce(candidate_pitches).uniq == octave_reduce(@pitch_offsets.values).uniq
      end

      # TODO: OJO: problema con las notas duplicadas, con la identificación de inversiones y con las notas a distancias de más de una octava

      pitches.collect do |pitch, element|
        [@pitch_names[pitch - root_pitch], element]
      end.to_h
    end

    def matches(pitches)
      reduced_pitches = octave_reduce(pitches).uniq

      !!reduced_pitches.find do |candidate_root_pitch|
        reduced_pitches.sort == octave_reduce(pitches(candidate_root_pitch)).uniq.sort
      end
    end

    def to_s
      "<ChordDefinition: name = #{@name} features = #{@features} pitch_offsets = #{@pitch_offsets}>"
    end

    alias inspect to_s

    protected

    def octave_reduce(pitches)
      pitches.collect { |p| p % 12 }
    end
  end

  class Chord
    def initialize(name_or_notes_or_pitches = nil, # name | [notes] | [pitches]
                   # definitory
                   name: nil,
                   root: nil, root_grade: nil,
                   notes: nil, pitches: nil,
                   features: nil,
                   # target scale (or scale reference)
                   scale: nil,
                   # operations
                   inversion: nil, state: nil,
                   position: nil,
                   duplicate: nil,
                   move: nil,
                   add: nil,
                   drop: nil,
                   #
                   _source: nil)

      # Preparing notes and pitches Arrays: they will we used to collect further notes and pitches
      #
      if notes
        notes = notes.collect do |n|
          case n
          when Musa::NoteInScale
            n
          when Numeric, Symbol
            scale[n]
          else
            raise ArgumentError, "Can't recognize #{n} in notes list #{notes}"
          end
        end
      end

      pitches = pitches.clone if pitches

      # Preparing root_pitch
      #

      root_pitch = nil

      raise ArgumentError, "Duplicate parameter: root: #{root} and root_grade: #{root_grade}" if root && root_grade

      if root && root.is_a?(Musa::NoteInScale)
        root_pitch = root.pitch
        scale ||= root.scale
      end

      raise ArgumentError, "Don't know how to recognize root_grade #{root_grade}: scale is not provided" if root_grade && !scale

      root_pitch = scale[root_grade].pitch if root_grade && scale

      # Parse name_or_notes_or_pitches to name, notes, pitches
      #
      #
      case name_or_notes_or_pitches
      when Symbol
        raise ArgumentError, "Duplicate parameter #{name_or_notes_or_pitches} and name: #{name}" if name

        name = name_or_notes_or_pitches

      when Array
        name_or_notes_or_pitches.each do |note_or_pitch|
          case note_or_pitch
          when Musa::NoteInScale
            notes ||= [] << note_or_pitch
          when Numeric
            if scale
              notes ||= [] << scale[note_or_pitch]
            else
              pitches ||= [] << note_or_pitch
            end
          when Symbol
            raise ArgumentError, "Don't know how to recognize #{note_or_pitch} in parameter list #{name_or_notes_or_pitches}: it's a symbol but the scale is not provided" unless scale

            notes ||= [] << scale[note_or_pitch]
          else
            raise ArgumentError, "Can't recognize #{note_or_pitch} in parameter list #{name_or_notes_or_pitches}"
          end
        end

      when nil
        # nothing happens
      else
        raise ArgumentError, "Can't recognize #{name_or_notes_or_pitches}"
      end

      # Eval definitory atributes
      #

      if _source.nil?
        @notes = compute_notes(name, root_pitch, scale, notes, pitches, features)
      else
        @notes = compute_notes_from_source(_source, name, root_pitch, scale, notes, pitches, features)
      end

      # Eval adding / droping operations
      #

      if add
        add.each do |to_add|
          case to_add
          when NoteInScale
            @notes << to_add
          when Numeric # pitch increment
            pitch = root_pitch + to_add
            @notes << scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)
          when Symbol # interval name
            pitch = root_pitch + scale.offset_of_interval(to_add)
            @notes << scale.note_of_pitch(pitch)
          else
            raise ArgumentError, "Can't recognize element to add #{to_add}"
          end
        end
      end

      # Eval voice increment operations
      #
      # ????

      # Identify chord
      #

      @notes.freeze

      @chord_definition = ChordDefinition.find_by_pitches(@notes.values.collect(&:pitch))
    end

    attr_reader :notes

    def name(name = nil)
      if name.nil?
        @chord_definition.name if @chord_definition
      else
        Chord.new(_source: self, name: name)
      end
    end

    def features
      @chord_definition.features if @chord_definition
    end

    def featuring(feature_values_or_features)
      features = @chord_definition.features.dup if @chord_definition
      features ||= {}

      feature_values_or_features = [feature_values_or_features] if feature_values_or_features.is_a?(Symbol)

      case feature_values_or_features
      when Array
        feature_values_or_features.each { |v| features[ChordDefinition.feature_key_of(v)] = v }
      when Hash
        feature_values_or_features.each { |k, v| features[k] = v }
      else
        raise ArgumentError, "Don't know how to find features #{feature_values_or_features}"
      end

      Chord.new(_source: self, features: features)
    end

    def root(root = nil)
      if root.nil?
        @notes[:root]
      else
        Chord.new(_source: self, root: root)
      end
    end

    def [](position)
      case position
      when Numeric
        @notes.values[position]
      when Symbol
        @notes[position]
      end
    end

    def scale
      scales = @notes.values.collect(&:scale).uniq
      scales.first if scales.size == 1
    end

    # Converts the chord to a specific scale with the notes in the chord
    def as_scale
    end


    def project_on_all(*scales)
      # TODO add match to other chords... what does it means?

      note_sets = {}
      scales.each do |scale|
        note_sets[scale] = @notes.values.collect { |n| n.on(scale) }
      end

      note_sets_in_scale = note_sets.values.reject { |notes| notes.include?(nil) }
      note_sets_in_scale.collect { |notes| Chord.new(notes: notes) }
    end

    def project_on(*scales)
      project_on_all(*scales).first
    end

    def ==(other)
      self.class == other.class && @notes == other.notes
    end

    def to_s
      "<Chord: notes = #{@notes}>"
    end

    alias inspect to_s

    private

    def compute_notes(name, root_pitch, scale, notes, pitches, features)
      if name && root_pitch && scale && !(notes || pitches || features)

        chord_definition = ChordDefinition[name]

        raise ArgumentError, "Unrecognized #{name} chord" unless chord_definition

        chord_definition.pitch_offsets.transform_values do |offset|
          pitch = root_pitch + offset
          scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)
        end

      elsif root_pitch && features && scale && !(name || notes || pitches)

        chord_definitions = ChordDefinition.find_by_features(features)

        in_scale_chord_definitions = chord_definitions.reject do |chord_definition|
          chord_definition.pitches(root_pitch).find { |chord_pitch| scale.note_of_pitch(chord_pitch).nil? }
        end

        selected =
          if in_scale_chord_definitions.size == 1
            in_scale_chord_definitions.first
          elsif in_scale_chord_definitions.size.zero? && chord_definitions.size == 1
            chord_definitions.first
          end

        unless selected
          raise ArgumentError, "Don't know how to create a chord with root pitch #{root_pitch}"\
            " and features #{features} based on scale #{scale.kind.class} with root on #{scale.root}: "\
            " found #{in_scale_chord_definitions.size}"\
            " in-scale chord definitions and #{chord_definitions.size - in_scale_chord_definitions.size}"\
            " out-of-scale chord definitions"
        end

        selected.pitch_offsets.transform_values do |offset|
          pitch = root_pitch + offset
          scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)
        end

      elsif (notes || pitches && scale) && !(name || root_pitch || features)

        notes ||= []

        notes += pitches.collect { |p| scale.note_of_pitch(p) } if pitches

        chord_definition = ChordDefinition.find_by_pitches(notes.collect(&:pitch))

        raise "Can't find a chord definition for pitches #{pitches} on scale #{scale.kind.id} based on #{scale.root}" unless chord_definition

        chord_definition.named_pitches(notes, &:pitch)
      else
        pattern = { name: name, root: root_pitch, scale: scale, notes: notes, pitches: pitches, features: features }
        raise ArgumentError, "Can't understand chord definition pattern #{pattern}"
      end

    end

    def compute_notes_from_source(source, name, root_pitch, scale, notes, pitches, features)
      if !(name || root_pitch || scale || notes || pitches || features)
        source.notes

      elsif features && !(name || root_pitch || scale || notes || pitches)
        compute_notes(nil, source.root.pitch, source.root.scale, nil, nil, features)

      else
        pattern = { name: name, root: root_pitch, scale: scale, notes: notes, pitches: pitches, features: features }
        raise ArgumentError, "Can't understand chord definition pattern #{pattern}"
      end
    end

    def method_missing(method_name, *args, **key_args, &block)
      if ChordDefinition.feature_key_of(method_name) && args.empty? && key_args.empty? && !block
        featuring(method_name)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private)
      ChordDefinition.feature_key_of(method_name) || super
    end
  end
end
