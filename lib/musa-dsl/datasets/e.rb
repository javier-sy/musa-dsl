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
  # A passage written as deltas says nothing about where it starts, so it can be
  # replayed from any other starting point: the same movement from another note,
  # in another register, at another dynamic. That is what it is for, rather than
  # any saving in size.
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
  # ## What a duration is measured in
  #
  # **A BAR.** `1r` is one bar, `1/4r` is a quarter of a bar, `2r` is two bars.
  # That is what the sequencer counts -- position 1 is bar 1, position 2 is bar
  # 2 -- and every duration in the library is a fraction of it.
  #
  # It is NOT a fraction of a whole note, and that distinction only shows itself
  # outside 4/4, where a bar and a whole note stop being the same length:
  #
  # - in 4/4, `1/4r` lasts a quarter note, and `1r` a whole one;
  # - in 3/4, `1/4r` lasts three quarters of a beat, and a quarter note is
  #   `1/3r`; the bar, `1r`, is a dotted half;
  # - in 6/8, a beat is `1/6r` and is written as an eighth.
  #
  # So "1/4r is a quarter note" is true of 4/4 and of nothing else. It is the
  # meter's coincidence rather than a definition, and the documentation of this
  # library stated it as a rule for a long time.
  #
  # The only place that needs to know about whole notes is {Score::ToMXML},
  # which has to name figures, and it converts there.
  #
  # ## Natural Keys
  #
  # - **:duration**: Total duration of the event process
  # - **:note_duration**: Actual note duration (may differ for staccato, etc.)
  # - **:forward_duration**: Time until next event (may be 0 for simultaneous events)
  #
  # None of the three is required: an event belongs here as soon as it declares
  # ANY of them. `:duration` and `:forward_duration` are what make it occupy
  # time, and either one alone is enough -- an impulse (a click, a percussive
  # attack that frees itself) has no sounding length of its own and does have a
  # distance to the next event, and that is a well formed event of the domain.
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
  #   event = { pitch: 60, duration: 1.0 }.extend(AbsD)
  #   event.duration          # => 1.0
  #   event.note_duration     # => 1.0 (defaults to duration)
  #   event.forward_duration  # => 1.0 (defaults to duration)
  #
  # @example Staccato note
  #   staccato = { pitch: 60, duration: 1.0, note_duration: 0.5 }.extend(AbsD)
  #   staccato.note_duration     # => 0.5 (sounds shorter)
  #   staccato.forward_duration  # => 1.0 (the next event still waits a full beat)
  #
  # @example Simultaneous events
  #   chord_note = { pitch: 60, duration: 1.0, forward_duration: 0 }.extend(AbsD)
  #   chord_note.forward_duration  # => 0 (the next event starts at the same time)
  #
  # @example An impulse: spacing without a length of its own
  #   click = { forward_duration: 1/4r }.extend(AbsD)
  #   click.forward_duration  # => (1/4)
  #   click.duration          # => nil
  #   click.note_duration     # => nil
  #
  #   # `duration` does not fall back on `forward_duration`, and should not: the
  #   # click does not sound for the whole gap. Nil is the honest answer.
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
    # Defaults to `:duration` if `:forward_duration` not specified. This is the
    # value `play` waits on in `:wait` mode, so it is what advances a serie.
    #
    # @return [Numeric] forward duration
    #
    # @example
    #   { pitch: 60, duration: 1.0 }.extend(AbsD).forward_duration  # => 1.0
    #
    # @example The fallback runs one way only
    #   { forward_duration: 1/2r }.extend(AbsD).forward_duration  # => (1/2)
    #   { forward_duration: 1/2r }.extend(AbsD).duration          # => nil
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
    #   { pitch: 60, duration: 1.0, note_duration: 0.5 }.extend(AbsD).note_duration  # => 0.5
    def note_duration
      self[:note_duration] || self[:duration]
    end

    # Returns event duration.
    #
    # @return [Numeric] duration
    #
    # @example
    #   { pitch: 60, duration: 1.0 }.extend(AbsD).duration  # => 1.0
    def duration
      self[:duration]
    end

    # Checks if thing can be converted to AbsD.
    #
    # Either duration key is enough: what makes an event occupy time is that it
    # declares how long it lasts, or how long until the next one, and it need
    # not declare both.
    #
    # @param thing [Object] object to check
    # @return [Boolean] true if compatible
    #
    # @example AbsD compatibility check
    #   AbsD.is_compatible?({ duration: 1.0 })          # => true
    #   AbsD.is_compatible?({ forward_duration: 1.0 })  # => true
    #   AbsD.is_compatible?({ pitch: 60 })              # => false
    def self.is_compatible?(thing)
      thing.is_a?(AbsD) ||
        thing.is_a?(Hash) && (thing.has_key?(:duration) || thing.has_key?(:forward_duration))
    end

    # Converts thing to AbsD if possible.
    #
    # @param thing [Object] object to convert
    # @return [AbsD] AbsD dataset
    # @raise [ArgumentError] if thing cannot be converted
    #
    # @example Convert to AbsD
    #   AbsD.to_AbsD({ duration: 1.0 }).is_a?(AbsD)          # => true
    #   AbsD.to_AbsD({ forward_duration: 1.0 }).is_a?(AbsD)  # => true
    def self.to_AbsD(thing)
      if thing.is_a?(AbsD)
        thing
      elsif thing.is_a?(Hash) && (thing.has_key?(:duration) || thing.has_key?(:forward_duration))
        thing.clone.extend(AbsD)
      else
        raise ArgumentError, "Cannot convert #{thing} to AbsD dataset"
      end
    end
  end
end