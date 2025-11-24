require_relative 'dataset'

module Musa::Datasets
  # Base module for musical events.
  #
  # E (Event) is the base module for all dataset types representing musical events.
  # It provides validation interface and defines the concept of "natural keys" -
  # keys that are inherent to the dataset type.
  #
  # ## Natural Keys
  #
  # Each dataset type defines which keys are "natural" to it (i.e., semantically
  # meaningful for that type). Keys not in NaturalKeys are considered modifiers
  # or extensions.
  #
  # ## Validation
  #
  # Events can be validated to ensure they contain required keys and valid values.
  # Subclasses should override {#valid?} to implement type-specific validation.
  #
  # @example Basic validation
  #   event = { pitch: 60, duration: 1.0 }.extend(Musa::Datasets::E)
  #   event.valid?     # => true
  #   event.validate!  # Returns if valid, raises if not
  #
  # @see Abs Absolute value events
  # @see Delta Delta (incremental) events
  module E
    include Dataset

    # Natural keys for base events (empty).
    # @return [Array<Symbol>]
    NaturalKeys = [].freeze

    # Checks if event is valid.
    #
    # Base implementation always returns true. Subclasses should override
    # to implement specific validation logic.
    #
    # @return [Boolean] true if valid
    #
    # @example
    #   event.valid?  # => true
    def valid?
      true
    end

    # Validates event, raising if invalid.
    #
    # @raise [RuntimeError] if event is not valid
    # @return [void]
    #
    # @example
    #   event.validate!  # Raises if invalid
    def validate!
      raise RuntimeError, "Invalid dataset #{self}" unless valid?
    end
  end

  # Events with absolute values.
  #
  # Abs (Absolute) represents events where all values are absolute (not relative).
  # Examples: actual MIDI pitch 60, duration 1.0 seconds, velocity 64.
  #
  # Contrast with {Delta} where values are incremental.
  #
  # @see Delta Incremental events
  # @see AbsI Absolute indexed (arrays)
  # @see AbsTimed Absolute with time
  # @see AbsD Absolute with duration
  module Abs
    include E
  end

  # Events with delta (incremental) values.
  #
  # Delta represents events where values are incremental changes from a previous
  # state. Examples: pitch +2 semitones, duration +0.5 beats, velocity -10.
  #
  # Delta encoding is efficient for sequences where consecutive events have
  # similar values.
  #
  # @example Delta vs Absolute
  #   # Absolute encoding (3 events)
  #   { pitch: 60, duration: 1.0 }
  #   { pitch: 62, duration: 1.0 }
  #   { pitch: 64, duration: 1.0 }
  #
  #   # Delta encoding (same 3 events)
  #   { abs_pitch: 60, abs_duration: 1.0 }  # First event absolute
  #   { delta_pitch: +2 }                    # Duration unchanged
  #   { delta_pitch: +2 }                    # Duration unchanged
  #
  # @see Abs Absolute events
  # @see DeltaD Delta with duration
  module Delta
    include E
  end

  # Absolute indexed events (array-based).
  #
  # AbsI represents absolute events stored in indexed structures (arrays).
  # Used by {V} and {PackedV} modules.
  #
  # @see Abs Parent absolute module
  # @see V Value arrays
  # @see PackedV Packed value hashes
  module AbsI
    include Abs
  end

  # Absolute events with time component.
  #
  # AbsTimed represents absolute events that occur at a specific time point.
  # The `:time` key indicates when the event occurs.
  #
  # ## Natural Keys
  #
  # - **:time**: Absolute time position
  #
  # @example Timed event
  #   { time: 0.0, value: { pitch: 60 } }.extend(AbsTimed)
  #   { time: 1.0, value: { pitch: 64 } }.extend(AbsTimed)
  #
  # @see Abs Parent absolute module
  # @see P Pitch series (produces AbsTimed)
  module AbsTimed
    include Abs

    # Natural keys including time.
    # @return [Array<Symbol>]
    NaturalKeys = (NaturalKeys + [:time]).freeze
  end

  # Delta indexed events (array-based deltas).
  #
  # DeltaI represents delta events stored in indexed structures.
  #
  # @see Delta Parent delta module
  module DeltaI
    include Delta
  end

  # Absolute events with duration.
  #
  # AbsD represents absolute events that have duration - they occupy a time span
  # rather than occurring at a single instant.
  #
  # ## Natural Keys
  #
  # - **:duration**: Total duration of the event process
  # - **:note_duration**: Actual note duration (may differ for staccato, etc.)
  # - **:forward_duration**: Time until next event (may be 0 for simultaneous events)
  #
  # ## Duration Types
  #
  # **duration**: How long the event process lasts (note playing, dynamics change, etc.)
  #
  # **note_duration**: Actual note length. For staccato, this is shorter than duration.
  # Defaults to duration if not specified.
  #
  # **forward_duration**: Time to wait before next event. Can be:
  #
  # - Same as duration (default): next event starts when this one ends
  # - Less than duration: events overlap
  # - Zero: next event starts simultaneously
  # - More than duration: gap/rest before next event
  #
  # @example Basic duration
  #   { pitch: 60, duration: 1.0 }.extend(AbsD)
  #   event.duration          # => 1.0
  #   event.note_duration     # => 1.0 (defaults to duration)
  #   event.forward_duration  # => 1.0 (defaults to duration)
  #
  # @example Staccato note
  #   { pitch: 60, duration: 1.0, note_duration: 0.5 }.extend(AbsD)
  #   # Note sounds for 0.5, but next event waits 1.0
  #
  # @example Simultaneous events
  #   { pitch: 60, duration: 1.0, forward_duration: 0 }.extend(AbsD)
  #   # Next event starts immediately (chord)
  #
  # @see Abs Parent absolute module
  # @see PS Pitch series with duration
  # @see PDV Pitch/Duration/Velocity
  # @see GDV Grade/Duration/Velocity
  module AbsD
    include Abs

    # Natural keys including duration variants.
    # @return [Array<Symbol>]
    NaturalKeys = (NaturalKeys +
                   [:duration, # duration of the process (note reproduction, dynamics evolution, etc)
                    :note_duration, # duration of the note (a staccato note is effectively shorter than elapsed duration until next note)
                    :forward_duration # duration to wait until next event (if 0 means the next event should be executed at the same time than this one)
                   ]).freeze

    # Returns forward duration (time until next event).
    #
    # Defaults to `:duration` if `:forward_duration` not specified.
    #
    # @return [Numeric] forward duration
    #
    # @example
    #   event.forward_duration  # => 1.0
    def forward_duration
      self[:forward_duration] || self[:duration]
    end

    # Returns actual note duration.
    #
    # Defaults to `:duration` if `:note_duration` not specified.
    #
    # @return [Numeric] note duration
    #
    # @example
    #   event.note_duration  # => 0.5 (staccato)
    def note_duration
      self[:note_duration] || self[:duration]
    end

    # Returns event duration.
    #
    # @return [Numeric] duration
    #
    # @example
    #   event.duration  # => 1.0
    def duration
      self[:duration]
    end

    # Checks if thing can be converted to AbsD.
    #
    # @param thing [Object] object to check
    # @return [Boolean] true if compatible
    #
    # @example
    #   AbsD.is_compatible?({ duration: 1.0 })  # => true
    #   AbsD.is_compatible?({ pitch: 60 })      # => false
    def self.is_compatible?(thing)
      thing.is_a?(AbsD) || thing.is_a?(Hash) && thing.has_key?(:duration)
    end

    # Converts thing to AbsD if possible.
    #
    # @param thing [Object] object to convert
    # @return [AbsD] AbsD dataset
    # @raise [ArgumentError] if thing cannot be converted
    #
    # @example
    #   AbsD.to_AbsD({ duration: 1.0 })  # => AbsD dataset
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