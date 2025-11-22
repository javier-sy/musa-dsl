require_relative 'dataset'
require_relative 'ps'

require_relative '../series'
require_relative '../sequencer'

module Musa::Datasets
  # Point series: sequential points in time with durations.
  #
  # P (Point series) represents sequential points in time as arrays with alternating
  # structure: [point, duration, point, duration, point, ...].
  #
  # ## Structure
  #
  # The array alternates between points and durations:
  #
  #     [point₀, duration₀, point₁, duration₁, point₂]
  #
  # - **Points** (odd positions): Any data (numbers, hashes, complex structures, etc.)
  # - **Durations** (even positions): Time between points (numbers)
  # - **Last point**: Final point has no duration (sequence end)
  #
  # This compact format efficiently represents timed sequences without
  # repeating time information.
  #
  # ## Conversions
  #
  # P can be converted to two different representations:
  #
  # ### 1. Timed Series (to_timed_serie)
  #
  # Converts to series of {AbsTimed} events with absolute time and value.
  # Each value gets a timestamp based on cumulative durations.
  #
  #     p = [60, 4, 64, 8, 67].extend(P)
  #     serie = p.to_timed_serie
  #     # Yields:
  #     # { time: 0, value: 60 }
  #     # { time: 1.0, value: 64 }  (4 * base_duration = 1.0)
  #     # { time: 3.0, value: 67 }  (8 * base_duration = 2.0)
  #
  # ### 2. Parameter Segment Series (to_ps_serie)
  #
  # Converts to series of {PS} (Parameter Segment) objects representing
  # continuous changes between consecutive points.
  #
  #     p = [60, 4, 64, 8, 67].extend(P)
  #     serie = p.to_ps_serie
  #     # Yields PS objects:
  #     # { from: 60, to: 64, duration: 1.0, right_open: true }
  #     # { from: 64, to: 67, duration: 2.0, right_open: false }
  #
  # ## Point Transformation
  #
  # The {#map} method transforms points while preserving durations:
  #
  #     p = [60, 4, 64, 8, 67].extend(P)
  #     p2 = p.map { |point| point + 12 }
  #     # => [72, 4, 76, 8, 79]
  #     # Durations unchanged, points transformed
  #
  # @example Basic point series (MIDI pitches)
  #   # MIDI pitches with durations in quarter notes
  #   p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)
  #   # 60 (C4) for 4 quarters → 64 (E4) for 8 quarters → 67 (G4)
  #
  # @example Hash points (complex data structures)
  #   p = [
  #     { pitch: 60, velocity: 64 }, 4,
  #     { pitch: 64, velocity: 80 }, 8,
  #     { pitch: 67, velocity: 64 }
  #   ].extend(Musa::Datasets::P)
  #
  # @example Convert to timed serie
  #   p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)
  #   serie = p.to_timed_serie(base_duration: 1/4r)
  #   # base_duration: quarter note = 1/4 beat
  #
  # @example Start at specific time
  #   serie = p.to_timed_serie(time_start: 10)
  #   # First event at time 10
  #
  # @example Start time from component
  #   p = [{ time: 100, pitch: 60 }, 4, { time: 200, pitch: 64 }].extend(P)
  #   serie = p.to_timed_serie(time_start_component: :time)
  #   # First event at time 100 (from first point's :time)
  #
  # @example Transform points
  #   p = [60, 4, 64, 8, 67].extend(Musa::Datasets::P)
  #   p2 = p.map { |point| point + 12 }
  #   # Transform each point (e.g., transpose pitches up one octave)
  #
  # @see PS Parameter segments
  # @see AbsTimed Timed events
  # @see Dataset Parent dataset module
  module P
    include Dataset

    # Converts to series of parameter segments.
    #
    # Creates {PS} objects representing continuous changes from each point
    # to the next. Useful for glissandi, parameter sweeps, or any continuous
    # interpolation between points.
    #
    # @param base_duration [Rational] duration unit multiplier (default: 1/4r)
    #   Durations in P are multiplied by this to get actual time
    #
    # @return [Musa::Series::Serie<PS>] series of parameter segments
    #
    # @example Create parameter segments
    #   p = [60, 4, 64, 8, 67].extend(P)
    #   serie = p.to_ps_serie
    #   segment1 = serie.next_value
    #   # => { from: 60, to: 64, duration: 1.0, right_open: true }
    def to_ps_serie(base_duration: nil)
      base_duration ||= 1/4r # TODO review incoherence between neumalang 1/4r base duration for quarter notes and general 1r size of bar

      # TODO if instead of using clone (needed because of p.shift) we use index counter the P elements would be evaluated on the last moment

      Musa::Series::Constructors.E(clone, base_duration) do |p, base_duration|
        (p.size >= 3) ?
          { from: p.shift,
            duration: p.shift * base_duration,
            to: p.first,
            right_open: (p.length > 1) }.extend(PS).tap { |_| _.base_duration = base_duration } : nil
      end
    end

    # Converts to series of timed events (AbsTimed).
    #
    # Creates series yielding {AbsTimed} events with absolute time and value.
    # Each value is emitted at its calculated time point based on cumulative durations.
    #
    # @param time_start [Numeric] starting time offset (default: 0)
    # @param time_start_component [Symbol] key in first value to use as time offset
    #   If provided, adds first[time_start_component] to time_start
    # @param base_duration [Rational] duration unit multiplier (default: 1/4r)
    #
    # @return [PtoTimedSerie] series of timed events
    #
    # @example Basic timed serie
    #   p = [60, 4, 64, 8, 67].extend(P)
    #   serie = p.to_timed_serie
    #   serie.next_value  # => { time: 0, value: 60 }
    #   serie.next_value  # => { time: 1.0, value: 64 }
    #   serie.next_value  # => { time: 3.0, value: 67 }
    #
    # @example Custom start time
    #   serie = p.to_timed_serie(time_start: 10)
    #   # First event at time 10
    #
    # @example Start time from component
    #   p = [{ time: 100, pitch: 60 }, 4, { pitch: 64 }].extend(P)
    #   serie = p.to_timed_serie(time_start_component: :time)
    #   # First event at time 100
    def to_timed_serie(time_start: nil, time_start_component: nil, base_duration: nil)
      time_start ||= 0r
      time_start += self.first[time_start_component] if time_start_component

      base_duration ||= 1/4r # TODO review incoherence between neumalang 1/4r base duration for quarter notes and general 1r size of bar

      PtoTimedSerie.new(self, base_duration, time_start)
    end

    # Maps over points, preserving durations.
    #
    # Transforms each point (odd positions) using the block while
    # keeping durations (even positions) unchanged.
    #
    # @yieldparam point [Object] each point in the series
    # @yieldreturn [Object] transformed point
    #
    # @return [P] new P with transformed points
    #
    # @example Transform points (e.g., transpose pitches)
    #   p = [60, 4, 64, 8, 67].extend(P)
    #   p.map { |point| point + 12 }
    #   # => [72, 4, 76, 8, 79]
    #
    # @example Transform hash points
    #   p = [{ pitch: 60 }, 4, { pitch: 64 }].extend(P)
    #   p.map { |point| point.merge(velocity: 80) }
    #   # Adds velocity to each point
    def map(&block)
      i = 0
      clone.map! do |element|
        # Process with block only the points (points are the alternating elements because P
        # structure is <point> <duration> <point> <duration> <point>)
        #
        if (i += 1) % 2 == 1
          block.call(element)
        else
          element
        end
      end
    end

    # Series adapter for P to AbsTimed conversion.
    #
    # PtoTimedSerie is a {Musa::Series::Serie} that converts a {P} (point series)
    # into a series of {AbsTimed} events. It reads the alternating point/duration
    # structure and emits timed events.
    #
    # This class is created by {P#to_timed_serie} and should not be instantiated
    # directly.
    #
    # @api private
    class PtoTimedSerie
      include Musa::Series::Serie.base

      # Creates new timed serie adapter.
      #
      # @param origin [P] source point series
      # @param base_duration [Rational] duration unit multiplier
      # @param time_start [Numeric] starting time offset
      #
      # @api private
      def initialize(origin, base_duration, time_start)
        @origin = origin
        @base_duration = base_duration
        @time_start = time_start

        init

        mark_as_prototype!
      end

      # Source point series.
      # @return [P]
      attr_accessor :origin

      # Duration unit multiplier.
      # @return [Rational]
      attr_accessor :base_duration

      # Starting time offset.
      # @return [Numeric]
      attr_accessor :time_start

      private def _init
        @index = 0
        @time = @time_start
      end

      private def _next_value
        if value = @origin[@index]
          @index += 1
          r = { time: @time, value: value }.extend(AbsTimed)

          delta_time = @origin[@index]
          @index += 1
          @time += delta_time * @base_duration if delta_time

          r
        end
      end
    end
  end
end