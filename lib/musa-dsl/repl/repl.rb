require 'socket'
require 'pathname'

module Musa
  module REPL
    class REPL
      @@repl_mutex = Mutex.new

      def initialize(bind = nil, port: nil, after_eval: nil, logger: nil, highlight_exception: true)

        self.bind = bind

        port ||= 1327

        @logger = logger || Musa::Logger::Logger.new
        @highlight_exception = highlight_exception

        @block_source = nil

        @client_threads = []
        @run = true

        @main_thread = Thread.new do
          @server = TCPServer.new(port)
          begin
            while (@connection = @server.accept) && @run
              @client_threads << Thread.new do
                buffer = nil

                begin
                  while (line = @connection.gets) && @run

                    @logger.warn('REPL') { 'input line is nil; will close connection...' } if line.nil?

                    line.chomp!
                    case line
                    when '#path'
                      buffer = StringIO.new

                    when '#begin'
                      user_path = buffer&.string
                      @bind.receiver.instance_variable_set(:@user_pathname, Pathname.new(user_path)) if user_path

                      buffer = StringIO.new

                    when '#end'
                      @@repl_mutex.synchronize do
                        @block_source = buffer.string

                        begin
                          send_echo @block_source, output: @connection
                          @bind.receiver.execute @block_source, '(repl)', 1

                        rescue StandardError, ScriptError => e
                          @logger.warn('REPL') { 'code execution error' }
                          @logger.warn('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }

                          send_exception e, output: @connection
                        else
                          after_eval.call @block_source if after_eval
                        end
                      end
                    else
                      buffer.puts line
                    end
                  end

                rescue IOError, Errno::ECONNRESET, Errno::EPIPE => e
                  @logger.warn('REPL') { 'lost connection' }
                  @logger.warn('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }

                ensure
                  @logger.debug('REPL') { "closing connection (running #{@run})" }
                  @connection.close
                end

              end
            end
          rescue Errno::ECONNRESET, Errno::EPIPE => e
            @logger.warn('REPL') { 'connection failure while getting server port; will retry...' }
            @logger.warn('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }
            retry

          end
        end
      end

      def bind=(bind)
        raise 'Already binded' if @bind

        @bind = bind

        return unless @bind

        if @bind.receiver.respond_to?(:sequencer) &&
           @bind.receiver.sequencer.respond_to?(:on_error)

          @bind.receiver.sequencer.on_error do |e|
            send_exception e, output: @connection
          end
        end
      end

      def stop
        @run = false

        @main_thread.terminate
        Thread.pass

        @main_thread = nil

        @client_threads.each { |t| t.terminate; Thread.pass }
        @client_threads.clear
      end

      def puts(*messages)
        if @connection
          messages.each do |message|
            send output: @connection, content: message&.to_s
          end
        else
          @logger.warn('REPL') do
            "trying to print a message in MusaLCE but the client is not connected. Ignoring message \'#{message} \'."
          end
        end

        nil
      end

      private

      def send_echo(e, output:)
        send output: output, command: '//echo'
        send output: output, content: e
        send output: output, command: '//end'
      end

      def send_exception(e, output:)

        @logger.error('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }

        send output: output, command: '//error'

        selected_backtrace_locations = e.backtrace_locations.select { |bt| bt.path == '(repl)' }

        if e.is_a?(ScriptError)
          send output: output, content: e.class.name
          send output: output, command: '//backtrace'
          send output: output, content: e.message

        elsif selected_backtrace_locations.empty?
          send output: output, content: "#{e.class.name}: #{e.message}"
          send output: output, command: '//backtrace'
          send output: output, content: e.backtrace_locations.first.to_s

        else
          lines = @block_source.split("\n")

          lineno = selected_backtrace_locations.first.lineno

          source_before = lines[lineno - 2] if lineno >= 2
          source_error = lines[lineno - 1]
          source_after = lines[lineno]

          send output: output, content: '***'
          send output: output, content: "[#{lineno - 1}] #{source_before}" if source_before
          send output: output, content: "[#{lineno}] #{source_error} \t\t<<< ERROR !!!"
          send output: output, content: "[#{lineno + 1}] #{source_after}" if source_after
          send output: output, content: '***'
          send output: output, content: e.class.name
          send output: output, content: e.message
          send output: output, command: '//backtrace'
          selected_backtrace_locations.each do |bt|
            send output: output, content: bt.to_s
          end
        end
        send output: output, content: ' '
        send output: output, command: '//end'
      end

      def send(output:, content: nil, command: nil)
        output.puts escape(content) if content
        output.puts command if command
      end

      def escape(text)
        if text.start_with? '//'
          "//#{text}"
        else
          text
        end
      end
    end

    module CustomizableDSLContext
      protected def binder
        raise NotImplementedError, 'Binder method should be implemented in target namespace as def binder; @__binder ||= binding; end'
      end

      def execute(source_block, file, line)
        binder.eval source_block, file, line
      end
    end
  end
end
