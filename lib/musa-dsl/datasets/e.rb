require_relative 'dataset'

module Musa::Datasets
  module E
    include Dataset

    NaturalKeys = [].freeze

    # TODO implement valid? in all 'subclasses'. This implies recollecting from other places where validations are done and refactoring
    # TODO should valid? and validate! be on Dataset instead of E? P dataset inherits from Dataset but probably it could be validated
    #
    def valid?
      true
    end

    def validate!
      raise RuntimeError, "Invalid dataset #{self}" unless valid?
    end
  end

  module Abs
    include E
  end

  module Delta
    include E
  end

  module AbsI
    include Abs
  end

  module TimedAbsI
    include AbsI

    NaturalKeys = (NaturalKeys + [:time]).freeze
  end

  module DeltaI
    include Delta
  end

  module AbsD
    include Abs

    NaturalKeys = (NaturalKeys +
                   [:duration, # duration of the process (note reproduction, dynamics evolution, etc)
                    :note_duration, # duration of the note (a staccato note is effectvely shorter than elapsed duration until next note)
                    :forward_duration # duration to wait until next event (if 0 means the next event should be executed at the same time than this one)
                   ]).freeze

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
      thing.is_a?(AbsD) || thing.is_a?(Hash) && thing.has_key?(:duration)
    end

    def self.to_AbsD(thing)
      if thing.is_a?(AbsD)
        thing
      elsif thing.is_a?(Hash) && thing.has_key?(:duration)
        thing.clone.extend(AbsD)
      else
        raise ArgumentError, "Cannot convert #{thing} to AbsD dataset"
      end
    end
  end
end