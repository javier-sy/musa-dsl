require_relative 'scales'

module Musa
  class Chord
    def initialize(root_or_name_or_size = nil, # root | name | size | [notes_in_scale] | [pitches]
                   name: nil,
                   root: nil,
                   notes: nil,
                   scale: nil, scale_system: nil,
                   size: nil,
                   add: nil,
                   inversion: nil, state: nil,
                   position: nil,
                   duplicate: nil,
                   move: nil,
                   drop: nil)
    end

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

    # { :major, 3, [0, 4, 7] }
    # { :major, 4, [0, 4, 7, 11] }

    # { :minor, 3, [0, 3, 7] }
    # { [:minor, :diminished], 3, [0, 3, 6] }


    def scale; end

    # Converts the chord to a specific scale with the notes in the chord
    def as_scale; end

    def fundamental; end

    def [](position); end

    def features; end

    def size; end

    def match(cosas); end

    alias length size

    private

    # minor, major, ...? features?

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