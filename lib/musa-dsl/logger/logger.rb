require 'logger'

module Musa; module Logger
  class Logger < ::Logger
    def initialize(sequencer: nil, position_format: nil)
      super STDERR, level: WARN

      @sequencer = sequencer
      @position_format = position_format || 3.3


      self.formatter = proc do |severity, time, progname, msg|
        level = "[#{severity}] " unless severity == 'DEBUG'

        if msg
          position = if @sequencer
                       integer_digits = @position_format.to_i
                       decimal_digits = ((@position_format - integer_digits) * 10).round

                       "%#{integer_digits + decimal_digits + 1}s: " % ("%.#{decimal_digits}f" % sequencer.position.to_f)
                     end

          progname = "[#{progname}] " if progname

          "#{position}#{level}#{progname} #{msg}\n"
        else
          "\n"
        end
      end
    end
  end
end; end
