require 'socket'

module Musa
  class REPL
    @@repl_mutex = Mutex.new

  	def initialize binder, port: nil, redirect_stderr: nil
  		port ||= 1327
      redirect_stderr ||= false

      if binder.respond_to?(:on_error_block)
        binder.on_error_block do |e|
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

    									begin
  					            binder.eval buffer.string

    									rescue StandardError, ScriptError => e
                        send_exception e
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
      #TODO
    end

    private

    def send_exception e
      send command: "//error"
      send content: e.inspect
      send command: "//backtrace"
      e.backtrace.each do |bt|
        send content: bt
      end
      send command: "//end"
    end

    def send content: nil, command: nil
      puts escape(content) if content
      puts command if command
    end

    def escape text
      if text.start_with? '//'
        "//#{text}"
      else
        text
      end
    end
  end
end
