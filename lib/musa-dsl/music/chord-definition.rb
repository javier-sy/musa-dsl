module Musa
  class ChordDefinition
    class << self
      def [](name)
        @definitions[name]
      end

      def register(name, offsets:, **features)
        definition = ChordDefinition.new(name, offsets: offsets, **features).freeze

        @definitions ||= {}
        @definitions[definition.name] = definition

        @features_by_value ||= {}
        definition.features.each { |k, v| @features_by_value[v] = k }

        self
      end

      def find_by_pitches(pitches)
        @definitions.values.find { |d| d.matches(pitches) }
      end

      def features_from(values = nil, hash = nil)
        values ||= []
        hash ||= {}

        features = hash.dup
        values.each { |v| features[@features_by_value[v]] = v }

        features
      end

      def find_by_features(*values, **hash)
        features = features_from(values, hash)
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
end
