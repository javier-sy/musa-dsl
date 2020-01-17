require 'socket'

module Musa
  module REPL
    class REPL
      @@repl_mutex = Mutex.new

      def initialize(binder, port: nil, redirect_stderr: nil, after_eval: nil)
        port ||= 1327
        redirect_stderr ||= false

        @block_source = nil

        if binder.receiver.respond_to?(:sequencer) &&
            binder.receiver.sequencer.respond_to?(:on_block_error)

          binder.receiver.sequencer.on_block_error do |e|
            send_exception e
          end
        end

        @client_threads = []
        @run = true

        @main_thread = Thread.new do
          @server = TCPServer.new(port)
          begin
            while (connection = @server.accept) && @run
              @client_threads << Thread.new do
                buffer = nil

                begin
                  while (line = connection.gets) && @run
                    line.chomp!
                    case line
                    when '#begin'
                      buffer = StringIO.new
                    when '#end'
                      @@repl_mutex.synchronize do
                        original_stdout = $stdout
                        original_stderr = $stderr

                        $stdout = connection
                        $stderr = connection if redirect_stderr

                        @block_source = buffer.string

                        begin
                          send_echo @block_source

                          binder.eval @block_source, "(repl)", 1
                        rescue StandardError, ScriptError => e
                          send_exception e
                        else
                          after_eval.call @block_source if after_eval
                        end

                        $stdout = original_stdout
                        $stderr = original_stderr if redirect_stderr
                      end
                    else
                      buffer.puts line
                    end
                  end
                rescue IOError, Errno::ECONNRESET, Errno::EPIPE => e
                  warn e.message
                end

                connection.close
              end
            end
          rescue Errno::ECONNRESET, Errno::EPIPE => e
            warn e.message
            retry
          end
        end
      end

      def stop
        @run = false

        @main_thread.terminate
        @client_threads.each { |t| t.terminate }

        @main_thread = nil
        @client_threads.clear
      end

      private

      def send_echo(e)
        send command: '//echo'
        send content: e
        send command: '//end'
      end

      def send_exception(e)

        send command: '//error'

        selected_backtrace_locations = e.backtrace_locations.select { |bt| bt.path == '(repl)' }

        if e.is_a?(ScriptError)
          send content: e.class.name
          send command: '//backtrace'
          send content: e.message

        elsif selected_backtrace_locations.empty?
          send content: "#{e.class.name}: #{e.message}"
          send command: '//backtrace'
          send content: e.backtrace_locations.first.to_s

        else
          lines = @block_source.split("\n")

          lineno = selected_backtrace_locations.first.lineno

          source_before = lines[lineno - 2] if lineno >= 2
          source_error = lines[lineno - 1]
          source_after = lines[lineno]

          send content: '***'
          send content: "[#{lineno - 1}] #{source_before}" if source_before
          send content: "[#{lineno}] #{source_error} \t\t<<< ERROR !!!"
          send content: "[#{lineno + 1}] #{source_after}" if source_after
          send content: '***'
          send content: e.class.name
          send content: e.message
          send command: '//backtrace'
          selected_backtrace_locations.each do |bt|
            send content: bt.to_s
          end
        end
        send content: ' '
        send command: '//end'
      end

      def send(content: nil, command: nil)
        puts escape(content) if content
        puts command if command
      end

      def escape(text)
        if text.start_with? '//'
          "//#{text}"
        else
          text
        end
      end
    end
  end
end
