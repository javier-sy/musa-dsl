require 'socket'

# TODO replantear la salida por $stdout, para que los puts que haya en las acciones programadas a futuro también lleguen hasta el cliente

module Musa
  class REPL
  	def initialize binder, port: nil
  		@binder = binder
  		@port = port || 1327

      @original_stdout = $stdout
      $stdout = PhantomOutput.new $stdout
  		@client_threads = []

  		@main_thread = Thread.new do
  			@server = TCPServer.new(@port)
  			begin
  				while connection = @server.accept
  					@client_threads << Thread.new do
  						$stdout.connection = connection

  						buffer = nil

  						begin
  							while line = connection.gets
  								line.chomp!
  								case line
  								when '#begin'
  									buffer = StringIO.new
  								when '#end'
  									begin
  										@binder.eval buffer.string

  									rescue StandardError, ScriptError => e
  										$stdout.send command: "//error"
  										$stdout.send content: e.inspect
  										$stdout.send command: "//backtrace"
  										e.backtrace.each do |bt|
  											$stdout.send content: bt
  										end
  										$stdout.send command: "//end"
  									end
  								else
  									buffer.puts line
  								end
  							end
  						rescue Errno::ECONNRESET, Errno::EPIPE => e
  							warn e.message
  						end

  						$stdout.connection = nil
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
      #TODO hay que volver a poner $stdout a su valor original
    end

  	class PhantomOutput

  		attr_reader :stdout

  		def initialize stdout
  			@stdout = stdout
  			@connections = {}
  		end

  		def connection= c
  			if c
  				@connections[Thread.current] = c
  			else
  				@connections.delete c
  			end
  		end

  		def send content: nil, command: nil
  			puts escape(content) if content
  			puts command if command
  		end

  		def write string
  			if @connections.key? Thread.current
  				@connections[Thread.current].write string
  			else
  				@stdout.write string
  			end
  		end

  		def flush
  			if @connections.key? Thread.current
  				@connections[Thread.current].flush
  			else
  				@stdout.flush
  			end
  		end

  		private

  		def escape text
  			if text.start_with? '//'
  				"//#{text}"
  			else
  				text
  			end
  		end
  	end

  	private_constant :PhantomOutput
  end
end
