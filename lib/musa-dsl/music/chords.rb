require_relative 'scales'


=begin
c = Chord.new root: 60, # root: major.tonic,
              scale_system: nil, # scale_system[:major],
              scale: nil, # major,
              notes: [1, 2, 3],
              add: [],
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
    def initialize(name = nil, **pitch_offsets, &block)
      @name = name
      @pitch_offsets = pitch_offsets
      @block = block
    end

    attr_reader :name, :pitches

    def chord_pitches(scale = nil, root_grade_or_symbol = nil, size = nil)
      case

        ... seguir aqui: root_grade_or_symbol es incoherente con el uso de root en {|offset| root + offset }
      ... qué debe llegar aquí? un pitch cromático o un grade_or_symbol???

      when root_grade_or_symbol && @name && @pitch_offsets && !(scale || size || @block)
        @pitch_offsets.transform_values { |offset| root + offset }

      when root && scale && !(@name || @pitch_offsets || @block)
        size ||= 3

        raise ArgumentError, "Don't know how to create a chord with root #{root} and size #{size} on scale #{scale.kind.id} based on #{scale.root}" unless scale.kind.grades == 7
        scale.grade_of root

      else

      end
    end

    def matches(pitches)
      octave_reduce(pitches).sort == @pitches.sort
    end

    protected

    def octave_reduce(pitches)
      pitches.collect { |p| p % 12 }
    end
  end

  class Chord
    class << self
      def register(chord_definition)
        @chord_definitions ||= {}
        @chord_definitions[chord_definition.name] = chord_definition
        self
      end
    end

    def initialize(name_or_size_or_notes_or_pitches = nil, # name | size | [notes] | [pitches]
                   # definitory
                   name: nil,
                   root: nil,
                   notes: nil, pitches: nil,
                   size: nil,
                   # target scale (or scale reference)
                   scale: nil,
                   # operations
                   add: nil,
                   inversion: nil, state: nil,
                   position: nil,
                   duplicate: nil,
                   move: nil,
                   drop: nil,
                   #
                   _source: nil)

      # Parse name_or_size_or_notes_or_pitches to name, size, notes, pitches
      #
      case name_or_size_or_notes_or_pitches
      when Symbol
        raise ArgumentError, "Duplicate parameter #{name_or_size_or_notes_or_pitches} and name: #{name}." if name
        name = name_or_size_or_notes_or_pitches
      when Integer
        raise ArgumentError, "Duplicate parameter #{name_or_size_or_notes_or_pitches} and size: #{size}." if size
        size = name_or_size_or_notes_or_pitches
      when Array
        name_or_size_or_notes_or_pitches.each do |note_or_pitch|
          case note_or_pitch
          when Musa::NoteInScale
            notes ||= [] << note_or_pitch
          when Numeric
            pitches ||= [] << note_or_pitch
          else
            raise ArgumentError, "Cannot recognize #{note_or_pitch} in parameter list #{name_or_size_or_notes_or_pitches}." if size
          end
        end
      when nil
      else
        raise ArgumentError, "Cannot recognize #{name_or_size_or_notes_or_pitches}."
      end

      # Eval atributes
      #
      case
      when name && root && !(notes || pitches || size)
      when (notes || pitches) && !(name || size || root)
      when scale && !(name || notes || pitches)
      end
    end

    def name(name = nil)
      if name.nil?
        @name
      else
        Chord.new(_source: self, name: name)
      end
    end

    def root(root = nil)
      if root.nil?
        @root
      else
        Chord.new(_source: self, root: root)
      end
    end

    def size(size = nil)
      if size.nil?
        @canonical_pitches.size
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