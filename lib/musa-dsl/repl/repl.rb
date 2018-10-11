require 'socket'

module Musa
  class REPL
    @@repl_mutex = Mutex.new

    def initialize(binder, port: nil, redirect_stderr: nil, after_eval: nil)
      port ||= 1327
      redirect_stderr ||= false

      if binder.receiver.respond_to?(:sequencer) &&
         binder.receiver.sequencer.respond_to?(:on_block_error)

        binder.receiver.sequencer.on_block_error do |e|
          send_exception e
        end
      end

      @client_threads = []

      @main_thread = Thread.new do
        @server = TCPServer.new(port)
        begin
          while connection = @server.accept
            @client_threads << Thread.new do
              buffer = nil

              begin
                while line = connection.gets
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

                      block_source = buffer.string

                      begin
                        send_echo block_source

                        binder.eval block_source
                      rescue StandardError, ScriptError => e
                        send_exception e
                      else
                        after_eval.call block_source if after_eval
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
      # TODO
    end

    private

    def send_echo(e)
      send command: '//echo'
      send content: e
      send command: '//end'
    end

    def send_exception(e)
      send command: '//error'
      send content: e.inspect
      send command: '//backtrace'
      e.backtrace.each do |bt|
        send content: bt
      end
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
