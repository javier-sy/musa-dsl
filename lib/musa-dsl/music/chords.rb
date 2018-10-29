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

      def register(definition)
        @definitions ||= {}
        @definitions[definition.name] = definition
        self
      end

      def find(pitches)
        @definitions.find { |d| d.matches(pitches) }
      end
    end

    def initialize(name, **pitch_offsets)
      @name = name
      @pitch_offsets = pitch_offsets
      @pitch_names = pitch_offsets.each_pair { |k, v| [v, k] }.to_h
    end

    attr_reader :name, :pitch_offsets, :pitch_names

    protected

    def matches(pitches)
      octave_reduce(pitches).sort == @pitches.sort
    end

    def octave_reduce(pitches)
      pitches.collect { |p| p % 12 }
    end
  end

  class Chord
    def initialize(name_or_size_or_notes_or_pitches = nil, # name | size | [notes] | [pitches]
                   # definitory
                   name: nil,
                   root: nil,
                   notes: nil, pitches: nil,
                   size: nil,
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

      pitches = pitches.clone

      # Parse name_or_size_or_notes_or_pitches to name, size, notes, pitches
      #
      case name_or_size_or_notes_or_pitches
      when Symbol
        raise ArgumentError, "Duplicate parameter #{name_or_size_or_notes_or_pitches} and name: #{name}" if name

        name = name_or_size_or_notes_or_pitches

      when Integer
        raise ArgumentError, "Duplicate parameter #{name_or_size_or_notes_or_pitches} and size: #{size}" if size

        size = name_or_size_or_notes_or_pitches

      when Array
        name_or_size_or_notes_or_pitches.each do |note_or_pitch|
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
            raise ArgumentError, "Don't know how to recognize #{note_or_pitch} in parameter list #{name_or_size_or_notes_or_pitches}: it's a symbol but the scale is not provided" unless scale

            notes ||= [] << scale[note_or_pitch]
          else
            raise ArgumentError, "Can't recognize #{note_or_pitch} in parameter list #{name_or_size_or_notes_or_pitches}"
          end
        end

      when nil
        # nothing happens
      else
        raise ArgumentError, "Can't recognize #{name_or_size_or_notes_or_pitches}"
      end

      # Eval definitory atributes
      #
      @notes =
        if name && root && scale && !(notes || pitches || size || _source)

          chord_definition = ChordDefinition[name]

          raise ArgumentError, "Unrecognized #{name} chord" unless chord_definition

          root_pitch = scale[root].pitch

          chord_definition.pitch_offsets.transform_values do |offset|
            pitch = root_pitch + offset
            [scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)]
          end

        elsif root && scale && !(name || notes || pitches || _source)

          size ||= 3

          raise ArgumentError, "Don't know how to create a chord with root #{root} and size #{size} on scale #{scale.kind.id} based on #{scale.root} because the scale doesn't have 7 grades per octave" unless scale.kind.grades == 7

          root_grade_index = scale.grade_of(root)
          notes = Array.new(size) { |i| scale[root_grade_index + i * 2] }
          chord_definition = ChordDefinition.find(notes.collect(&:pitch))

          raise "Can't find a chord definition for pitches #{pitches} on scale #{scale.kind.id} based on #{scale.root}" unless chord_definition

          notes.collect { |g| [chord_definition.pitch_names[g.pitch], [g]] }.to_h

        elsif (notes || pitches && scale) && !(name || size || root || _source)

          notes += pitches.collect { |p| scale.note_of_pitch(p) }
          chord_definition = ChordDefinition.find(notes.collect(&:pitch))

          raise "Can't find a chord definition for pitches #{pitches} on scale #{scale.kind.id} based on #{scale.root}" unless chord_definition

          notes.collect { |g| [chord_definition.pitch_names[g.pitch], [g]] }.to_h

        elsif _source && !(name || size || root || notes || pitches)
          _source.notes

        else
          raise ArgumentError, "Can't understand chord definition pattern: try with another parameters combination"
        end

      # Eval adding / droping operations
      #

      if add
        add.each do |to_add|
          case to_add
          when NoteInScale
            @notes << to_add
          when Numeric # pitch increment
            pitch = root.pitch + to_add
            @notes << scale.note_of_pitch(pitch) || scale.chromatic.note_of_pitch(pitch)
          when Symbol # interval name
            pitch = root.pitch + scale.offset_of_interval(to_add)
            @notes << scale.note_of_pitch(pitch)
          else
            raise ArgumentError, "Can't recognize element to add #{to_add}"
          end
        end
      end

      # Eval voice increment operations
      #


    end

    def name(name = nil)
      if name.nil?
        # @name
      else
        Chord.new(_source: self, name: name)
      end
    end

    def root(root = nil)
      if root.nil?
        # @root
      else
        Chord.new(_source: self, root: root)
      end
    end

    def size(size = nil)
      if size.nil?
        # @canonical_pitches.size
      else
        Chord.new(_source: self, size: size)
      end
    end

    alias length size

    # Converts the chord to a specific scale with the notes in the chord
    def as_scale
    end


    def [](position)
    end


    def match(*scales_or_chords)
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