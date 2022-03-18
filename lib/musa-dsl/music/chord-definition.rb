require 'set'

module Musa
  module Chords
    class ChordDefinition
      def self.[](name)
        @definitions[name]
      end

      def self.register(name, offsets:, **features)
        definition = ChordDefinition.new(name, offsets: offsets, **features)

        @definitions ||= {}
        @definitions[definition.name] = definition

        @features_by_value ||= {}
        definition.features.each { |k, v| @features_by_value[v] = k }

        @feature_keys ||= Set[]
        features.keys.each { |feature_name| @feature_keys << feature_name }

        self
      end

      def self.find_by_pitches(pitches)
        @definitions.values.find { |d| d.matches(pitches) }
      end

      def self.features_from(values = nil, hash = nil)
        values ||= []
        hash ||= {}

        features = hash.dup
        values.each { |v| features[@features_by_value[v]] = v }

        features
      end

      def self.find_by_features(*values, **hash)
        features = features_from(values, hash)
        @definitions.values.select { |d| features <= d.features }
      end

      def self.feature_key_of(feature_value)
        @features_by_value[feature_value]
      end

      def self.feature_values
        @features_by_value.keys
      end

      def self.feature_keys
        @feature_keys
      end

      def initialize(name, offsets:, **features)
        @name = name.freeze
        @features = features.transform_values(&:dup).transform_values(&:freeze).freeze
        @pitch_offsets = offsets.dup.freeze
        @pitch_names = offsets.collect { |k, v| [v, k] }.to_h.freeze
        freeze
      end

      attr_reader :name, :features, :pitch_offsets, :pitch_names

      def pitches(root_pitch)
        @pitch_offsets.values.collect { |offset| root_pitch + offset }
      end

      def in_scale?(scale, chord_root_pitch:)
        !pitches(chord_root_pitch).find { |chord_pitch| scale.note_of_pitch(chord_pitch).nil? }
      end

      def named_pitches(elements_or_pitches, &block)
        pitches = elements_or_pitches.collect do |element_or_pitch|
          [if block_given?
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
          [@pitch_names[pitch - root_pitch], [element]]
        end.to_h
      end

      def matches(pitches)
        reduced_pitches = octave_reduce(pitches).uniq

        !!reduced_pitches.find do |candidate_root_pitch|
          reduced_pitches.sort == octave_reduce(pitches(candidate_root_pitch)).uniq.sort
        end
      end

      def inspect
        "<ChordDefinition: name = #{@name} features = #{@features} pitch_offsets = #{@pitch_offsets}>"
      end

      alias to_s inspect

      private

      def octave_reduce(pitches)
        pitches.collect { |p| p % 12 }
      end
    end
  end
end
