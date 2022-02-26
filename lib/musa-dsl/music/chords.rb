require_relative 'scales'
require_relative 'chord-definition'

module Musa
  module Chords
    using Musa::Extension::Arrayfy

    class Chord
      def initialize(name_or_notes_or_pitches = nil, # name | [notes] | [pitches]
                     # definitory
                     name: nil,
                     root: nil, root_grade: nil,
                     notes: nil, pitches: nil,
                     features: nil,
                     # target scale (or scale reference)
                     scale: nil,
                     allow_chromatic: nil,
                     # operations
                     inversion: nil, state: nil,
                     position: nil,
                     move: nil,
                     duplicate: nil,
                     add: nil,
                     drop: nil,
                     #
                     _source: nil)

        # Preparing notes and pitches Arrays: they will we used to collect further notes and pitches
        #
        if notes
          notes = notes.collect do |n|
            case n
            when Scales::NoteInScale
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

        allow_chromatic ||= scale.nil?

        if root&.is_a?(Scales::NoteInScale)
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
            when Scales::NoteInScale
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

        @notes = if _source.nil?
                   compute_notes(name, root_pitch, scale, notes, pitches, features, allow_chromatic)
                 else
                   compute_notes_from_source(_source, name, root_pitch, scale, notes, pitches, features, allow_chromatic)
                 end

        # Eval adding / droping operations
        #

        add&.each do |to_add|
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

        # TODO: Missing chord operations: drop, inversion, state, position
        #
        raise NotImplementedError, 'Missing chord operations: drop, inversion, state, position' if drop || inversion || state || position

        # Eval voice increment operations
        #

        if move
          raise ArgumentError, 'move: expected a Hash' unless move.is_a?(Hash)

          move.each do |position, octave|
            @notes[position][0] = @notes[position][0].octave(octave)
          end
        end

        if duplicate
          raise ArgumentError, 'duplicate: expected a Hash' unless duplicate.is_a?(Hash)

          duplicate.each do |position, octave|
            octave.arrayfy.each do |octave|
              @notes[position] << @notes[position][0].octave(octave)
            end
          end
        end

        # Identify chord
        #

        @notes.freeze

        @chord_definition = ChordDefinition.find_by_pitches(@notes.values.flatten(1).collect(&:pitch))

        ChordDefinition.feature_values.each do |name|
          define_singleton_method name do
            featuring(name)
          end
        end
      end

      attr_reader :notes, :chord_definition

      def name(name = nil)
        if name.nil?
          @chord_definition&.name
        else
          Chord.new(_source: self, name: name)
        end
      end

      def features
        @chord_definition&.features
      end

      def pitches(*grades)
        grades = @notes.keys if grades.empty?

        @notes.values_at(*grades).collect do |notes|
          notes.collect(&:pitch)
        end.flatten
      end

      def featuring(*values, allow_chromatic: nil, **hash)
        features = @chord_definition.features.dup if @chord_definition
        features ||= {}

        ChordDefinition.features_from(values, hash).each { |k, v| features[k] = v }

        Chord.new(_source: self, allow_chromatic: allow_chromatic, features: features)
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

      def move(**octaves)
        Chord.new(_source: self, move: octaves)
      end

      def duplicate(**octaves)
        Chord.new(_source: self, duplicate: octaves)
      end

      def scale
        scales = @notes.values.flatten(1).collect(&:scale).uniq
        scales.first if scales.size == 1
      end

      # Converts the chord to a specific scale with the notes in the chord
      def as_scale
      end

      def project_on_all(*scales, allow_chromatic: nil)
        # TODO add match to other chords... what does it means?
        allow_chromatic ||= false

        note_sets = {}
        scales.each do |scale|
          note_sets[scale] = if allow_chromatic
            @notes.values.flatten(1).collect { |n| n.on(scale) || n.on(scale.chromatic) }
          else
            @notes.values.flatten(1).collect { |n| n.on(scale) }
                             end
        end

        note_sets_in_scale = note_sets.values.reject { |notes| notes.include?(nil) }
        note_sets_in_scale.collect { |notes| Chord.new(notes: notes) }
      end

      def project_on(*scales, allow_chromatic: nil)
        allow_chromatic ||= false
        project_on_all(*scales, allow_chromatic: allow_chromatic).first
      end

      def ==(other)
        self.class == other.class && @notes == other.notes
      end

      def inspect
        "<Chord: notes = #{@notes}>"
      end

      alias to_s inspect

      private

      def compute_notes(name, root_pitch, scale, notes, pitches, features, allow_chromatic)
        if name && root_pitch && scale && !(notes || pitches || features)

          chord_definition = ChordDefinition[name]

          raise ArgumentError, "Unrecognized #{name} chord" unless chord_definition

          chord_definition.pitch_offsets.transform_values do |offset|
            pitch = root_pitch + offset
            [scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)]
          end

        elsif root_pitch && features && scale && !(name || notes || pitches)

          chord_definitions = ChordDefinition.find_by_features(**features)

          unless allow_chromatic
            chord_definitions.reject! do |chord_definition|
              chord_definition.pitches(root_pitch).find { |chord_pitch| scale.note_of_pitch(chord_pitch).nil? }
            end
          end

          selected = chord_definitions.first

          unless selected
            raise ArgumentError, "Don't know how to create a chord with root pitch #{root_pitch}"\
            " and features #{features} based on scale #{scale.kind.class} with root on #{scale.root}: "\
            " no suitable definition found (allow_chromatic is #{allow_chromatic})"
          end

          selected.pitch_offsets.transform_values do |offset|
            pitch = root_pitch + offset
            [scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)]
          end

        elsif (notes || pitches && scale) && !(name || root_pitch || features)

          notes ||= []

          notes += pitches.collect { |p| scale.note_of_pitch(p) } if pitches

          chord_definition = ChordDefinition.find_by_pitches(notes.collect(&:pitch))

          raise "Can't find a chord definition for pitches #{pitches} on scale #{scale.kind.id} based on #{scale.root}" unless chord_definition

          chord_definition.named_pitches(notes, &:pitch)
        else
          pattern = { name: name, root: root_pitch, scale: scale, notes: notes, pitches: pitches, features: features, allow_chromatic: allow_chromatic }
          raise ArgumentError, "Can't understand chord definition pattern #{pattern}"
        end
      end

      def compute_notes_from_source(source, name, root_pitch, scale, notes, pitches, features, allow_chromatic)
        if !(name || root_pitch || scale || notes || pitches || features)
          source.notes

        elsif features && !(name || root_pitch || scale || notes || pitches)
          compute_notes(nil, source.root.first.pitch, source.root.first.scale, nil, nil, features, allow_chromatic)

        else
          pattern = { name: name, root: root_pitch, scale: scale, notes: notes, pitches: pitches, features: features, allow_chromatic: allow_chromatic }
          raise ArgumentError, "Can't understand chord definition pattern #{pattern}"
        end
      end
    end
  end
end
