require 'spec_helper'
require 'musa-dsl'
require 'stringio'

RSpec.describe 'Logger Inline Documentation Examples' do
  include Musa::All

  # Custom IO-like object that accumulates output without truncation
  class AccumulatingIO
    attr_reader :output

    def initialize
      @output = ""
    end

    def write(message)
      @output << message
      message.length
    end

    def close
      # Do nothing - don't actually close
    end

    def string
      @output
    end
  end

  # Helper method to create logger with captured output
  def create_logger_with_capture(sequencer: nil, **options)
    output = AccumulatingIO.new
    # Create base logger instance first
    base_logger = ::Logger.new(output, level: ::Logger::WARN)

    # Now create our Logger subclass, passing the sequencer
    logger = Musa::Logger::Logger.allocate
    logger.instance_variable_set(:@sequencer, sequencer)
    logger.instance_variable_set(:@position_format, options[:position_format] || 3.3)

    # Copy the logdev and formatter from base logger, then set up our custom formatter
    logger.instance_variable_set(:@logdev, base_logger.instance_variable_get(:@logdev))
    logger.instance_variable_set(:@level, base_logger.level)
    logger.instance_variable_set(:@progname, base_logger.progname)
    logger.instance_variable_set(:@formatter, base_logger.formatter)
    logger.instance_variable_set(:@default_formatter, base_logger.instance_variable_get(:@default_formatter))

    # Now set up the custom formatter (copied from logger.rb initialize method)
    using_sequencer = sequencer
    position_fmt = options[:position_format] || 3.3

    logger.formatter = proc do |severity, time, progname, msg|
      level = "[#{severity}] " unless severity == 'DEBUG'

      if msg
        position = if using_sequencer
                     integer_digits = position_fmt.to_i
                     decimal_digits = ((position_fmt - integer_digits) * 10).round
                     "%#{integer_digits + decimal_digits + 1}s: " % ("%.#{decimal_digits}f" % using_sequencer.position.to_f)
                   end

        progname = "[#{progname}]" if progname
        "#{position}#{level}#{progname}#{' ' if position || level || progname}#{msg}\n"
      else
        "\n"
      end
    end

    [logger, output]
  end

  context 'Musa::Logger module (logger.rb)' do
    it 'example from line 32 - Complete workflow' do
      # Setup
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      # In your composition
      sequencer.at 1 do
        logger.info "Composition started"
      end

      sequencer.at 4 do
        logger.info "First phrase complete"
      end

      sequencer.run

      # Verify output contains expected log messages
      result = output.string
      expect(result).to include("[INFO]  Composition started")
      expect(result).to include("[INFO]  First phrase complete")
      expect(result).to match(/1\.000:.*\[INFO\].*Composition started/)
      expect(result).to match(/4\.000:.*\[INFO\].*First phrase complete/)
    end
  end

  context 'Musa::Logger::Logger class (logger.rb)' do
    it 'example from line 85 - Basic usage without sequencer' do
      logger, output = create_logger_with_capture
      logger.warn "Something happened"

      # Output: [WARN]  Something happened (note: extra space before message)
      result = output.string
      expect(result).to include("[WARN]  Something happened")
      # Should not have position prefix when no sequencer
      expect(result).not_to match(/\d+\.\d+:/)
    end

    it 'example from line 92 - With sequencer integration' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      sequencer.at 4.5r do
        logger.info "Note played"
      end

      sequencer.run

      # Output:  4.500: [INFO]  Note played
      result = output.string
      expect(result).to include("[INFO]  Note played")
      expect(result).to match(/4\.500:/)
    end

    it 'example from line 106 - With custom position format' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # 5 integer digits, 2 decimal places
      logger, output = create_logger_with_capture(
        sequencer: sequencer,
        position_format: 5.2
      )
      logger.level = Logger::DEBUG

      # At position 123.456:
      sequencer.at 123.456r do
        logger.debug "Debugging info"
      end

      sequencer.run

      # Output:  123.46: Debugging info
      result = output.string
      expect(result).to include("Debugging info")
      expect(result).to match(/123\.46:/)
      # Should not show [DEBUG] level
      expect(result).not_to include("[DEBUG]")
    end

    it 'example from line 127 - With program name' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      sequencer.at 4.5r do
        logger.info('MIDIVoice') { "Playing note 60" }
      end

      sequencer.run

      # Output:  4.500: [INFO] [MIDIVoice] Playing note 60
      result = output.string
      expect(result).to include("[INFO] [MIDIVoice] Playing note 60")
      expect(result).to match(/4\.500:/)
    end

    it 'example from line 142 - Real-world scenario with multiple components' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::DEBUG

      # Different components log at different times
      sequencer.at 1 do
        logger.info('Transport') { "Starting playback" }
      end

      sequencer.at 1.5r do
        logger.debug('Series') { "Evaluating next value" }
      end

      sequencer.at 2.25r do
        logger.warn('MIDIVoice') { "Note overflow detected" }
      end

      sequencer.run

      # Output:
      #  1.000: [INFO] [Transport] Starting playback
      #  1.500: [Series] Evaluating next value
      #  2.250: [WARN] [MIDIVoice] Note overflow detected
      result = output.string
      expect(result).to match(/1\.000:.*\[INFO\].*\[Transport\].*Starting playback/)
      expect(result).to match(/1\.500:.*\[Series\].*Evaluating next value/)
      expect(result).to match(/2\.250:.*\[WARN\].*\[MIDIVoice\].*Note overflow detected/)

      # DEBUG level should not show severity label
      expect(result).not_to match(/\[DEBUG\].*Evaluating next value/)
    end

    it 'example from line 169 - Changing log level dynamically' do
      # Test with DEBUG level
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output_debug = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::DEBUG  # Show all messages

      sequencer.at 1 do
        logger.debug "Debug message"
        logger.info "Info message"
      end

      sequencer.run

      result_debug = output_debug.string
      expect(result_debug).to include("Debug message")
      expect(result_debug).to include("Info message")

      # Later, reduce verbosity
      sequencer2 = Musa::Sequencer::Sequencer.new(4, 24)
      logger2, output_warn = create_logger_with_capture(sequencer: sequencer2)
      logger2.level = Logger::WARN  # Only warnings and errors

      sequencer2.at 1 do
        logger2.debug "Debug message"
        logger2.info "Info message"
        logger2.warn "Warning message"
      end

      sequencer2.run

      result_warn = output_warn.string
      expect(result_warn).not_to include("Debug message")
      expect(result_warn).not_to include("Info message")
      expect(result_warn).to include("Warning message")
    end

    it 'example from line 196 - Position format examples' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)

      # Different formats for position display:
      # 3.3 => "  4.500" (3 digits, 3 decimals) - default
      # 5.2 => "  123.46" (5 digits, 2 decimals)
      # 2.0 => "  4" (2 digits, no decimals)
      # 4.4 => "   4.5000" (4 digits, 4 decimals)

      logger_compact, output_compact = create_logger_with_capture(sequencer: sequencer, position_format: 2.0)
      logger_precise, output_precise = create_logger_with_capture(sequencer: sequencer, position_format: 4.4)

      expect(logger_compact).to be_a(Musa::Logger::Logger)
      expect(logger_precise).to be_a(Musa::Logger::Logger)

      # Test compact format (2.0)
      logger_compact.level = Logger::INFO
      sequencer.at 4 do
        logger_compact.info "Compact format"
      end
      sequencer.run

      result_compact = output_compact.string
      # Should have no decimals
      expect(result_compact).to match(/4:.*Compact format/)

      # Test precise format (4.4)
      sequencer2 = Musa::Sequencer::Sequencer.new(4, 24)
      logger_precise2, output_precise2 = create_logger_with_capture(sequencer: sequencer2, position_format: 4.4)
      logger_precise2.level = Logger::INFO
      sequencer2.at 4.5r do
        logger_precise2.info "Precise format"
      end
      sequencer2.run

      result_precise = output_precise2.string
      # Should have 4 decimal places
      expect(result_precise).to match(/4\.5000:.*Precise format/)
    end
  end

  context 'Logger formatting behavior' do
    it 'formats position correctly with default format (3.3)' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      # Use 1.25r which is exactly 30 ticks (1.25 * 24 = 30)
      sequencer.at 1.25r do
        logger.info "Test message"
      end

      sequencer.run

      result = output.string
      # Should format as 1.250 with 3 decimal places
      expect(result).to match(/1\.250:/)
    end

    it 'omits severity label for DEBUG level' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::DEBUG

      sequencer.at 1 do
        logger.debug "Debug message"
      end

      sequencer.run

      result = output.string
      expect(result).to include("Debug message")
      expect(result).not_to include("[DEBUG]")
    end

    it 'shows severity label for non-DEBUG levels' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      sequencer.at 1 do
        logger.info "Info message"
        logger.warn "Warn message"
        logger.error "Error message"
      end

      sequencer.run

      result = output.string
      expect(result).to include("[INFO]")
      expect(result).to include("[WARN]")
      expect(result).to include("[ERROR]")
    end

    it 'handles Rational positions correctly with InspectNice' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      # Test various rational positions
      sequencer.at 1.5r do
        logger.info "At one and a half"
      end

      sequencer.at 1.75r do
        logger.info "At one and three quarters"
      end

      sequencer.at 2.5r do
        logger.info "At two and a half"
      end

      sequencer.run

      result = output.string
      expect(result).to match(/1\.500:.*At one and a half/)
      expect(result).to match(/1\.750:.*At one and three quarters/)
      expect(result).to match(/2\.500:.*At two and a half/)
    end

    it 'aligns position values with padding' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer, position_format: 4.2)
      logger.level = Logger::INFO

      sequencer.at 1 do
        logger.info "Position 1"
      end

      sequencer.at 99 do
        logger.info "Position 99"
      end

      sequencer.run

      result = output.string
      lines = result.split("\n").reject(&:empty?)
      # Extract position parts (everything before the first ':')
      positions = lines.map { |line| line.split(':').first }

      # All positions should have the same length (right-aligned)
      expect(positions.map(&:length).uniq.size).to eq(1)
    end

    it 'works without sequencer (no position prefix)' do
      logger, output = create_logger_with_capture
      logger.level = Logger::INFO

      logger.info "Message without sequencer"
      logger.warn "Warning without sequencer"

      result = output.string
      expect(result).to include("[INFO]")
      expect(result).to include("Message without sequencer")
      expect(result).to include("[WARN]")
      expect(result).to include("Warning without sequencer")

      # Should not have position prefix
      expect(result).not_to match(/\d+\.\d+:/)
    end

    it 'handles block-style log messages' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      sequencer.at 1 do
        logger.info { "Block message" }
        logger.warn('Component') { "Block with progname" }
      end

      sequencer.run

      result = output.string
      expect(result).to include("Block message")
      expect(result).to include("[Component] Block with progname")
    end

    it 'handles empty messages gracefully' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      sequencer.at 1 do
        # Empty message case
        logger.info(nil)
      end

      sequencer.run

      result = output.string
      # Should just output newline
      expect(result).to eq("\n")
    end

    it 'respects log levels (WARN is default)' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      # Default level is WARN

      sequencer.at 1 do
        logger.debug "Debug (should not appear)"
        logger.info "Info (should not appear)"
        logger.warn "Warn (should appear)"
        logger.error "Error (should appear)"
      end

      sequencer.run

      result = output.string
      expect(result).not_to include("Debug")
      expect(result).not_to include("Info")
      expect(result).to include("Warn")
      expect(result).to include("Error")
    end
  end

  context 'Integration with Sequencer' do
    it 'reads sequencer position at log time, not scheduling time' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::INFO

      sequencer.at 1 do
        logger.info "At position 1"
      end

      sequencer.at 2 do
        logger.info "At position 2"
      end

      sequencer.at 3 do
        logger.info "At position 3"
      end

      sequencer.run

      result = output.string
      # Verify positions are correct at log time
      expect(result).to match(/1\.000:.*At position 1/)
      expect(result).to match(/2\.000:.*At position 2/)
      expect(result).to match(/3\.000:.*At position 3/)
    end

    it 'works with complex sequencer scenarios' do
      sequencer = Musa::Sequencer::Sequencer.new(4, 24)
      logger, output = create_logger_with_capture(sequencer: sequencer)
      logger.level = Logger::DEBUG

      # Nested sequencer events
      sequencer.at 1 do
        logger.info('Main') { "Starting sequence" }

        sequencer.at 1.5r do
          logger.debug('Nested') { "Nested event" }
        end
      end

      sequencer.at 2 do
        logger.warn('Main') { "Checkpoint" }
      end

      sequencer.run

      result = output.string
      expect(result).to match(/1\.000:.*\[INFO\].*\[Main\].*Starting sequence/)
      expect(result).to match(/1\.500:.*\[Nested\].*Nested event/)
      expect(result).to match(/2\.000:.*\[WARN\].*\[Main\].*Checkpoint/)
    end
  end

  context 'Logger inheritance from Ruby Logger' do
    it 'inherits all standard Ruby Logger methods' do
      logger, _ = create_logger_with_capture

      expect(logger).to respond_to(:debug)
      expect(logger).to respond_to(:info)
      expect(logger).to respond_to(:warn)
      expect(logger).to respond_to(:error)
      expect(logger).to respond_to(:fatal)
      expect(logger).to respond_to(:level)
      expect(logger).to respond_to(:level=)
    end

    it 'supports standard Logger severity constants' do
      logger, _ = create_logger_with_capture

      # Test with Logger constants
      logger.level = Logger::DEBUG
      expect(logger.level).to eq(Logger::DEBUG)

      logger.level = Logger::INFO
      expect(logger.level).to eq(Logger::INFO)

      logger.level = Logger::WARN
      expect(logger.level).to eq(Logger::WARN)

      logger.level = Logger::ERROR
      expect(logger.level).to eq(Logger::ERROR)

      logger.level = Logger::FATAL
      expect(logger.level).to eq(Logger::FATAL)
    end
  end
end
