require_relative 'dataset'

module Musa::Datasets
  module D
    include Dataset

    NaturalKeys = [:duration, # duration of the process (note reproduction, dynamics evolution, etc)
                   :note_duration, # duration of the note (a staccato note is effectvely shorter than elapsed duration until next note)
                   :forward_duration # duration to wait until next event (if 0 means the next event should be executed at the same time than this one)
    ].freeze

    def forward_duration
      self[:forward_duration] || self[:duration]
    end

    def note_duration
      self[:note_duration] || self[:duration]
    end

    def duration
      self[:duration]
    end

    def self.is_compatible?(thing)
      thing.is_a?(D) || thing.is_a?(Hash) && thing.has_key?(:duration)
    end

    def self.to_D(thing)
      if thing.is_a?(D)
        thing
      elsif thing.is_a?(Hash) && thing.has_key?(:duration)
        thing.clone.extend(D)
      else
        raise ArgumentError, 'Cannot convert #{thing} to D dataset'
      end
    end
  end
end