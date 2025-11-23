require 'logger'
require_relative '../core-ext/inspect-nice'

module Musa
  # Logging utilities for Musa DSL.
  #
  # Provides a specialized logger that integrates with the sequencer to display
  # musical position information alongside standard log messages.
  #
  # ## Purpose
  #
  # When working with sequenced musical compositions, it's crucial to know at
  # what point in musical time events occur. This logger automatically prepends
  # the sequencer's current position (in bars) to each log entry, making
  # debugging and monitoring much more intuitive.
  #
  # ## Integration with Sequencer
  #
  # The logger reads the sequencer's position at the moment each log message
  # is generated. Since positions are typically Rational numbers representing
  # bars (e.g., 4/4 = 1 bar), the InspectNice refinement ensures they display
  # in a readable decimal format.
  #
  # ## Common Use Cases
  #
  # - Debugging sequencer timing issues
  # - Monitoring MIDI output events with their musical timestamps
  # - Tracking series evaluation progress
  # - Logging voice state changes during playback
  # - Performance analysis and timing verification
  #
  # @example Complete workflow
  #   require 'musa-dsl'
  #
  #   # Setup
  #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
  #   logger = Musa::Logger::Logger.new(sequencer: sequencer)
  #   logger.level = Logger::INFO
  #
  #   # In your composition
  #   sequencer.at 0 do
  #     logger.info "Composition started"
  #   end
  #
  #   sequencer.at 4 do
  #     logger.info "First phrase complete"
  #   end
  #
  #   sequencer.run
  #
  #   # Output:
  #   #  0.000: [INFO] Composition started
  #   #  4.000: [INFO] First phrase complete
  #
  # @see Musa::Logger::Logger
  # @see Musa::Sequencer::Sequencer
  # @see Musa::Extension::InspectNice
  module Logger
    # Custom logger that displays sequencer position with log messages.
    #
    # This logger extends Ruby's standard Logger class to prepend the current
    # sequencer position to each log message, making it easy to track events
    # in musical time during composition and playback.
    #
    # ## Features
    #
    # - Automatic sequencer position formatting in log output
    # - Configurable position precision (integer and decimal digits)
    # - Conditional formatting (position only shown when sequencer is provided)
    # - Uses InspectNice refinements for better Rational display
    # - Defaults to STDERR output with WARN level
    #
    # ## Log Format
    #
    # The formatted log output follows this pattern:
    #
    #     [position]: [LEVEL] [progname] message
    #
    # Where:
    # - `position` is the sequencer position (only if sequencer provided)
    # - `LEVEL` is the severity level (omitted for DEBUG)
    # - `progname` is the program/module name (optional)
    # - `message` is the actual log message
    #
    # @example Basic usage without sequencer
    #   require 'musa-dsl'
    #
    #   logger = Musa::Logger::Logger.new
    #   logger.warn "Something happened"
    #   # Output: [WARN] Something happened
    #
    # @example With sequencer integration
    #   require 'musa-dsl'
    #
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    #   logger = Musa::Logger::Logger.new(sequencer: sequencer)
    #
    #   sequencer.at 4.5r do
    #     logger.info "Note played"
    #   end
    #
    #   sequencer.run
    #
    #   # Output:  4.500: [INFO] Note played
    #
    # @example With custom position format
    #   require 'musa-dsl'
    #
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    #
    #   # 5 integer digits, 2 decimal places
    #   logger = Musa::Logger::Logger.new(
    #     sequencer: sequencer,
    #     position_format: 5.2
    #   )
    #   logger.level = Logger::DEBUG
    #
    #   # At position 123.456:
    #   sequencer.at 123.456r do
    #     logger.debug "Debugging info"
    #   end
    #
    #   sequencer.run
    #
    #   # Output:  123.46: Debugging info
    #
    # @example With program name
    #   require 'musa-dsl'
    #
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    #   logger = Musa::Logger::Logger.new(sequencer: sequencer)
    #   logger.level = Logger::INFO
    #
    #   sequencer.at 4.5r do
    #     logger.info('MIDIVoice') { "Playing note 60" }
    #   end
    #
    #   sequencer.run
    #
    #   # Output:  4.500: [INFO] [MIDIVoice] Playing note 60
    #
    # @example Real-world scenario with multiple components
    #   require 'musa-dsl'
    #
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    #   logger = Musa::Logger::Logger.new(sequencer: sequencer)
    #   logger.level = Logger::DEBUG
    #
    #   # Different components log at different times
    #   sequencer.at 0 do
    #     logger.info('Transport') { "Starting playback" }
    #   end
    #
    #   sequencer.at 1.5r do
    #     logger.debug('Series') { "Evaluating next value" }
    #   end
    #
    #   sequencer.at 2.25r do
    #     logger.warn('MIDIVoice') { "Note overflow detected" }
    #   end
    #
    #   sequencer.run
    #
    #   # Output:
    #   #  0.000: [INFO] [Transport] Starting playback
    #   #  1.500: [Series] Evaluating next value
    #   #  2.250: [WARN] [MIDIVoice] Note overflow detected
    #
    # @example Changing log level dynamically
    #   require 'musa-dsl'
    #
    #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    #   logger = Musa::Logger::Logger.new(sequencer: sequencer)
    #   logger.level = Logger::DEBUG  # Show all messages
    #
    #   # Later, reduce verbosity
    #   logger.level = Logger::WARN  # Only warnings and errors
    #
    # @see Musa::Sequencer::Sequencer
    # @see Musa::Extension::InspectNice
    # @note The logger inherits all standard Ruby Logger methods (debug, info, warn, error, fatal).
    # @note Position values are formatted as floating point for readability, even though
    #   the sequencer internally uses Rational numbers.
    class Logger < ::Logger
      using Musa::Extension::InspectNice

      # Creates a new logger with optional sequencer integration.
      #
      # @param sequencer [Musa::Sequencer::Sequencer, nil] sequencer whose position
      #   will be displayed in log messages. When nil, position is not shown.
      # @param position_format [Numeric, nil] format specification for position display.
      #   The integer part specifies the number of digits before the decimal point,
      #   and the decimal part (×10) specifies digits after the decimal point.
      #   Defaults to 3.3 (3 integer digits, 3 decimal places).
      #
      # @example Position format examples
      #   require 'musa-dsl'
      #
      #   sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      #
      #   # Different formats for position display:
      #   # 3.3 => "  4.500" (3 digits, 3 decimals) - default
      #   # 5.2 => "  123.46" (5 digits, 2 decimals)
      #   # 2.0 => "  4" (2 digits, no decimals)
      #   # 4.4 => "   4.5000" (4 digits, 4 decimals)
      #
      #   logger_compact = Musa::Logger::Logger.new(sequencer: sequencer, position_format: 2.0)
      #   logger_precise = Musa::Logger::Logger.new(sequencer: sequencer, position_format: 4.4)
      #
      # @note The logger outputs to STDERR by default with level set to WARN.
      # @note Uses InspectNice refinements for better formatting of Rationals and Hashes.
      # @note The sequencer's position is read at log time, not at event scheduling time.
      #   This means the position reflects when the log message is actually generated.
      def initialize(sequencer: nil, position_format: nil)
        super STDERR, level: WARN

        # Store sequencer reference for position queries in formatter
        @sequencer = sequencer

        # Store position format specification
        @position_format = position_format || 3.3

        # Custom formatter that integrates sequencer position with log messages.
        #
        # This proc is called by Ruby's Logger for each log entry. It captures
        # @sequencer and @position_format from the enclosing scope to format
        # messages with musical timing information.
        #
        # The formatter constructs messages in the format:
        #   [position]: [LEVEL] [progname] message
        #
        # Position calculation:
        # - Splits position_format into integer and decimal parts
        # - Example: 3.3 => 3 integer digits + 3 decimal digits
        # - Formats sequencer position with calculated precision
        # - Right-aligns position in the allocated width
        #
        # Severity handling:
        # - DEBUG level: severity not shown in output
        # - Other levels: shown as [WARN], [INFO], [ERROR], [FATAL]
        #
        # Spacing:
        # - Adds separator space only if position, level, or progname are present
        # - Empty messages output just a newline
        #
        # @param severity [String] log level (DEBUG, INFO, WARN, ERROR, FATAL)
        # @param time [Time] timestamp of the log event (not used in current implementation)
        # @param progname [String, nil] program/component name
        # @param msg [String, nil] the actual log message
        # @return [String] formatted log line with newline
        self.formatter = proc do |severity, time, progname, msg|
          # Omit severity label for DEBUG level
          level = "[#{severity}] " unless severity == 'DEBUG'

          if msg
            # Calculate and format sequencer position if available
            position = if @sequencer
                         # Extract integer and decimal digit counts from position_format
                         # e.g., 3.3 => integer_digits=3, decimal_digits=3
                         integer_digits = @position_format.to_i
                         decimal_digits = ((@position_format - integer_digits) * 10).round

                         # Format position: total width includes digits + decimal point + ': '
                         # Right-aligned to keep positions visually aligned in logs
                         "%#{integer_digits + decimal_digits + 1}s: " % ("%.#{decimal_digits}f" % @sequencer.position.to_f)
                       end

            # Wrap progname in brackets if provided
            progname = "[#{progname}]" if progname

            # Construct final message with conditional spacing
            "#{position}#{level}#{progname}#{' ' if position || level || progname}#{msg}\n"
          else
            # Empty message case
            "\n"
          end
        end
      end

      # Override level getter to handle encoding compatibility issues.
      #
      # Ruby's Logger (>= 1.7.0) has an encoding bug in level_override that causes
      # Encoding::CompatibilityError when mixing UTF-8 strings from Musa with
      # Logger's BINARY (ASCII-8BIT) internal strings.
      #
      # This override catches the encoding error and returns the level directly
      # from the instance variable, bypassing the buggy level_override method.
      #
      # @return [Integer] current log level (DEBUG=0, INFO=1, WARN=2, ERROR=3, FATAL=4)
      def level
        super
      rescue Encoding::CompatibilityError
        # Bypass level_override and return raw level
        @level
      end
    end
  end
end
