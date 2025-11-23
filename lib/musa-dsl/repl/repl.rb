require 'socket'
require 'pathname'
require 'stringio'

module Musa
  # REPL (Read-Eval-Print Loop) infrastructure for live coding.
  #
  # The REPL module provides a TCP-based server that enables live coding by accepting
  # Ruby code over the network, executing it in the DSL context, and returning results
  # or errors to the client.
  #
  # ## Architecture
  #
  # The REPL acts as a bridge between code editors (via MusaLCE clients) and the
  # running Musa DSL environment:
  #
  #     Editor → MusaLCE Client → TCP (port 1327) → REPL Server → DSL Context
  #                                                       ↓
  #                                                 Results/Errors
  #
  # ## Protocol Details
  #
  # The REPL uses a line-based protocol over TCP:
  #
  # ### Client to Server
  #
  # - **#path**: Start path block (optional)
  # - *file path*: Path to the user's file being edited
  # - **#begin**: Start code block
  # - *code lines*: Ruby code to execute (literal `#begin`/`#end` must be escaped as `##begin`/`##end`)
  # - **#end**: Execute accumulated code block
  #
  # ### Server to Client
  #
  # - **//echo**: Start echo block (code about to be executed)
  # - **//error**: Start error block
  # - **//backtrace**: Start backtrace section within error block
  # - **//end**: End current block
  # - *regular lines*: Output from code execution (puts, etc.)
  # - **//*text***: Escaped lines starting with // (clients remove one `//`)
  #
  # ### Example Session
  #
  #     Client → Server:
  #       #path
  #       /Users/me/composition.rb
  #       #begin
  #       puts "Starting..."
  #       at 0 { play :C4 }
  #       #end
  #
  #     Server → Client:
  #       //echo
  #       puts "Starting..."
  #       at 0 { play :C4 }
  #       //end
  #       Starting...
  #
  # ## Integration with MusaLCE
  #
  # The REPL is designed to work seamlessly with MusaLCE (Musa Live Coding Environment)
  # clients for various editors:
  #
  # - **MusaLCEClientForVSCode**: Visual Studio Code extension
  # - **MusaLCEClientForAtom**: Atom editor plugin
  # - **musalce-server**: Server integrating with DAWs (Bitwig, Ableton Live)
  #
  # ## File Path Injection
  #
  # When a client sends a file path via the `#path` command, the REPL injects it
  # as `@user_pathname` (Pathname object) into the execution context. This allows
  # the DSL to implement relative `require_relative` calls based on the editor's
  # current file location.
  #
  # ## Use Cases
  #
  # - Live coding performances with real-time code evaluation
  # - Interactive composition development with DAW synchronization
  # - Remote control of running compositions
  # - Educational demonstrations and workshops
  #
  # @see REPL Main REPL server class
  # @see CustomizableDSLContext Mixin for DSL contexts
  # @see https://github.com/javier-sy/musa-dsl-examples/tree/master/musalce-server Production server integrating REPL with DAWs
  module REPL
    # TCP-based REPL server for live coding.
    #
    # The REPL class implements a multi-threaded TCP server that accepts connections
    # from live coding clients (like MusaLCE for VSCode/Atom), receives Ruby code,
    # executes it in a bound DSL context, and sends back results or exceptions.
    #
    # ## Threading Model
    #
    # - **Main thread**: Accepts client connections
    # - **Client threads**: One per connected client, handles requests
    # - **Mutex protection**: Serializes code execution for safety (@@repl_mutex)
    #
    # ## Binding Options
    #
    # The REPL can be bound to a DSL context in two ways:
    #
    # 1. **DynamicProxy**: For transparent method delegation (recommended for complex DSLs)
    # 2. **Direct Binding**: Pass a Ruby Binding object directly for inline context setup
    #
    # ## Protocol Flow
    #
    # 1. **Optional path**: `#path\n/path/to/file\n#begin\n` (injects @user_pathname)
    # 2. **Code block**: `#begin\ncode\nmore code\n#end\n`
    # 3. **Server responses**:
    #
    #    - Echo: `//echo\ncode\n//end\n`
    #    - Error: `//error\nerror details\n//backtrace\nstack\n//end\n`
    #    - Output: Regular lines (from puts calls)
    #
    # ## Error Handling
    #
    # Errors are captured and formatted with:
    #
    # - Source code context (3 lines: before, error line, after)
    # - Error class and message
    # - Filtered backtrace (shows only REPL-executed code)
    # - Optional ANSI syntax highlighting (via highlight_exception parameter)
    #
    # ## Integration with Sequencer
    #
    # If the bound context has a sequencer with on_error support, the REPL
    # automatically hooks into it to report async errors during playback.
    #
    # @example With DynamicProxy (complex DSL)
    #   class MyDSL
    #     include Musa::REPL::CustomizableDSLContext
    #     # ... DSL methods ...
    #   end
    #
    #   repl = Musa::REPL::REPL.new(
    #     bind: Musa::Extension::DynamicProxy::DynamicProxy.new(MyDSL.new),
    #     port: 1327
    #   )
    #
    # @example With direct Binding (musalce-server pattern)
    #   sequencer.with(keep_block_context: false) do
    #     # Define DSL methods in this context
    #     def play(note); end
    #     def at(pos, &block); end
    #
    #     # Create REPL with this binding
    #     @repl = Musa::REPL::REPL.new(binding, highlight_exception: false)
    #   end
    #
    # @example With after_eval callback
    #   dsl_context = MyDSL.new
    #   context_proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context)
    #   repl = REPL.new(
    #     bind: context_proxy,
    #     after_eval: -> (source) { log_execution(source) }
    #   )
    #
    # @see CustomizableDSLContext For binding DSL contexts with DynamicProxy
    # @see Musa::Extension::DynamicProxy::DynamicProxy Proxy wrapper for DSL contexts
    # @see https://github.com/javier-sy/musa-dsl-examples/tree/master/musalce-server Production example using direct binding
    class REPL
      # Class-level mutex for serializing code execution.
      #
      # Ensures only one code block executes at a time across all clients.
      @@repl_mutex = Mutex.new

      # Creates a new REPL server.
      #
      # The server starts immediately in a background thread, listening for connections
      # on the specified port (default 1327).
      #
      # ## Binding Patterns
      #
      # The first parameter can be:
      #
      # - **Binding**: Ruby binding object (inline DSL setup, see musalce-server)
      # - **DynamicProxy**: Proxy object wrapping a DSL context
      # - **nil**: Binding can be set later via {#bind=}
      #
      # ## Parameter Options
      #
      # Named parameters provide additional configuration:
      #
      # - **port**: TCP port (default: 1327)
      # - **after_eval**: Callback for successful executions
      # - **logger**: Custom logger (creates default if nil)
      # - **highlight_exception**: ANSI colors in errors (default: true, musalce-server uses false)
      #
      # @param bind [Binding, DynamicProxy, nil] execution context (can be set later)
      # @param port [Integer, nil] TCP port to listen on (default: 1327)
      # @param after_eval [Proc, nil] callback invoked after successful code execution
      # @param logger [Logger, nil] logger instance (creates default if nil)
      # @param highlight_exception [Boolean] enable ANSI color in exception output (default: true)
      #
      # @yield [source] Called via after_eval after successful execution
      # @yieldparam source [String] the executed source code
      #
      # @example With DynamicProxy and named parameters
      #   dsl_context = MyDSL.new
      #   custom_logger = Musa::Logger::Logger.new
      #   REPL.new(
      #     bind: Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context),
      #     port: 1327,
      #     after_eval: -> (src) { log_execution(src) },
      #     logger: custom_logger
      #   )
      #
      # @example With direct Binding (musalce-server pattern)
      #   # Inside a context setup block:
      #   @repl = REPL.new(binding, highlight_exception: false)
      #
      # @example Deferred binding
      #   repl = REPL.new  # Start server without binding
      #   # ... later ...
      #   context = MyDSL.new
      #   repl.bind = Musa::Extension::DynamicProxy::DynamicProxy.new(context)
      def initialize(bind = nil, port: nil, after_eval: nil, logger: nil, highlight_exception: true)

        self.bind = bind

        port ||= 1327

        @logger = logger || Musa::Logger::Logger.new
        @highlight_exception = highlight_exception

        @block_source = nil

        @client_threads = []
        @run = true

        # Start main server thread
        @main_thread = Thread.new do
          @server = TCPServer.new(port)
          begin
            # Accept client connections
            while (@connection = @server.accept) && @run
              # Spawn thread for each client
              @client_threads << Thread.new do
                buffer = nil

                begin
                  # Process lines from client
                  while (line = @connection.gets) && @run

                    @logger.warn('REPL') { 'input line is nil; will close connection...' } if line.nil?

                    line.chomp!
                    case line
                    when '#path'
                      # Start path block
                      buffer = StringIO.new

                    when '#begin'
                      # Save path (if provided), start code block
                      user_path = buffer&.string
                      @bind.receiver.instance_variable_set(:@user_pathname, Pathname.new(user_path)) if user_path

                      buffer = StringIO.new

                    when '#end'
                      # Execute accumulated code block
                      @@repl_mutex.synchronize do
                        @block_source = buffer.string

                        begin
                          # Echo code to client
                          send_echo @block_source, output: @connection

                          # Execute in DSL context
                          @bind.receiver.execute @block_source, '(repl)', 1

                        rescue StandardError, ScriptError => e
                          # Handle execution errors
                          @logger.warn('REPL') { 'code execution error' }
                          @logger.warn('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }

                          send_exception e, output: @connection
                        else
                          # Success: invoke callback
                          after_eval.call @block_source if after_eval
                        end
                      end
                    else
                      # Accumulate code lines
                      buffer.puts line
                    end
                  end

                rescue IOError, Errno::ECONNRESET, Errno::EPIPE => e
                  # Connection errors
                  @logger.warn('REPL') { 'lost connection' }
                  @logger.warn('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }

                ensure
                  # Clean up connection
                  @logger.debug('REPL') { "closing connection (running #{@run})" }
                  @connection.close
                end

              end
            end
          rescue Errno::ECONNRESET, Errno::EPIPE => e
            # Server socket errors - retry
            @logger.warn('REPL') { 'connection failure while getting server port; will retry...' }
            @logger.warn('REPL') { e.full_message(highlight: @highlight_exception, order: :top) }
            retry

          end
        end
      end

      # Sets or updates the binding context.
      #
      # The binding context is where code will be executed. The REPL accesses
      # the execution context via `bind.receiver.execute(source, file, line)`:
      #
      # - **Binding**: Uses Ruby's `Binding#receiver` (returns the binding's self)
      # - **DynamicProxy**: Uses `DynamicProxy#receiver` (returns wrapped object)
      #
      # ## Requirements
      #
      # The `bind.receiver` object must implement:
      #
      # - `execute(source, file, line)`: Evaluates source code
      # - Optionally `sequencer.on_error`: For async error reporting
      #
      # ## Sequencer Integration
      #
      # If `bind.receiver` has a sequencer with `on_error` support, the REPL
      # automatically hooks into it to report sequencer errors to the client
      # during playback.
      #
      # @param bind [Binding, DynamicProxy, Object] binding context with `receiver`
      # @return [Object] the bind object
      #
      # @raise [RuntimeError] if bind is already set
      #
      # @note Can only be set once
      # @note Automatically hooks into `bind.receiver.sequencer.on_error` if available
      #
      # @example With Ruby Binding
      #   # binding.receiver returns the DSLContext instance
      #   repl.bind = binding  # Inside DSL context
      #
      # @example With DynamicProxy
      #   # proxy.receiver returns the wrapped object
      #   dsl_context = MyDSL.new
      #   repl.bind = Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context)
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

      # Stops the REPL server and cleans up all threads.
      #
      # This method terminates both the main server thread and all client threads,
      # ensuring a clean shutdown. It's safe to call even if the server is already
      # stopped.
      #
      # ## Shutdown Process
      #
      # 1. Sets run flag to false (stops accepting new connections)
      # 2. Terminates main server thread
      # 3. Terminates all client threads
      # 4. Clears thread tracking
      #
      # @return [void]
      #
      # @note After stopping, the REPL cannot be restarted (would need new instance)
      # @note Uses Thread.pass to ensure thread scheduling
      #
      # @example
      #   repl = REPL.new(bind: context)
      #   # ... later
      #   repl.stop  # Clean shutdown
      def stop
        @run = false

        @main_thread.terminate
        Thread.pass

        @main_thread = nil

        @client_threads.each { |t| t.terminate; Thread.pass }
        @client_threads.clear
      end

      # Sends messages to the connected REPL client.
      #
      # This method allows code running in the REPL to send output back to the
      # client (editor). It's designed to be called from within evaluated code,
      # typically as a replacement for standard Kernel#puts.
      #
      # ## Behavior
      #
      # - If client is connected: sends all messages via TCP
      # - If no client connected: logs warning and ignores messages
      # - Always returns nil (like Kernel#puts)
      #
      # ## Use in DSL Context
      #
      # The DSL context can override Kernel#puts to redirect output to the client:
      #
      #     def puts(*args)
      #       repl.puts(*args)
      #     end
      #
      # This allows code like `puts "Debug: #{value}"` to appear in the editor.
      #
      # @param messages [Array<Object>] messages to send (converted to strings)
      # @return [nil] always returns nil like Kernel#puts
      #
      # @note Thread-safe for multi-threaded code execution
      # @note Messages sent via {#send} with proper escaping
      #
      # @example From evaluated code
      #   # In REPL-evaluated code:
      #   puts "Starting sequence..."
      #   sequencer.at 4 { puts "Bar 4!" }
      #   # Output appears in editor
      #
      # @example Multiple messages
      #   repl.puts("Line 1", "Line 2", "Line 3")
      #   # Sends three separate lines to client
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

      # Sends code echo to the client.
      #
      # After receiving and before executing a code block, the REPL echoes it back
      # to the client. This allows the editor to confirm what code will be executed
      # and potentially display it differently from the original input.
      #
      # ## Protocol Format
      #
      #     //echo
      #     <source code lines>
      #     //end
      #
      # @param e [String] source code to echo
      # @param output [TCPSocket] client connection to send to
      # @return [void]
      #
      # @api private
      def send_echo(e, output:)
        send output: output, command: '//echo'
        send output: output, content: e
        send output: output, command: '//end'
      end

      # Sends formatted exception information to the client.
      #
      # When code execution fails, this method formats the exception with context
      # and sends it to the client in a structured format. The formatting varies
      # based on the exception type and whether it occurred in REPL-executed code.
      #
      # ## Protocol Format
      #
      #     //error
      #     <error context and message>
      #     //backtrace
      #     <backtrace lines>
      #     <blank line>
      #     //end
      #
      # ## Error Formatting Strategies
      #
      # ### ScriptError (SyntaxError, etc.)
      # - Class name
      # - Message (contains syntax details)
      # - No source context (parser-level error)
      #
      # ### Errors outside REPL code
      # - "ClassName: message"
      # - First backtrace location (likely in library)
      #
      # ### Errors in REPL code (most common)
      # - Source context: 3 lines (before, error, after)
      # - Line numbers for orientation
      # - Error marker: "<<< ERROR !!!"
      # - Exception class and message
      # - Filtered backtrace (only REPL-executed code)
      #
      # ## Source Context Example
      #
      #     ***
      #     [5] some_variable = 42
      #     [6] result = divide_by_zero()  		<<< ERROR !!!
      #     [7] puts result
      #     ***
      #     ZeroDivisionError
      #     divided by 0
      #
      # @param e [Exception] the exception to format and send
      # @param output [TCPSocket] client connection to send to
      # @return [void]
      #
      # @note Also logs the full exception to the logger
      # @note Backtrace is filtered to show only '(repl)' locations
      #
      # @api private
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

      # Sends content and/or command to the client.
      #
      # Low-level method for sending data over TCP to the client. Handles
      # optional content (with escaping) and protocol commands.
      #
      # @param output [TCPSocket] client connection to send to
      # @param content [String, nil] text content to send (will be escaped)
      # @param command [String, nil] protocol command to send (e.g., '//echo')
      # @return [void]
      #
      # @note Content is escaped via {#escape} to handle lines starting with '//'
      # @note Commands are sent unmodified
      #
      # @api private
      def send(output:, content: nil, command: nil)
        output.puts escape(content) if content
        output.puts command if command
      end

      # Escapes text lines that start with '//' to prevent protocol confusion.
      #
      # Since the REPL protocol uses lines starting with '//' as commands
      # (//echo, //error, //end, etc.), any user content that starts with '//'
      # must be escaped by doubling the slashes.
      #
      # ## Escaping Rule
      #
      # - `"//something"` → `"///something"` (escaped)
      # - `"normal text"` → `"normal text"` (unchanged)
      #
      # The client is responsible for unescaping by removing one '//' prefix
      # from any line starting with '///' (assuming it's not a known command).
      #
      # @param text [String] text to potentially escape
      # @return [String] escaped text (or original if no escaping needed)
      #
      # @example
      #   escape("//comment")  # => "///comment"
      #   escape("Hello")      # => "Hello"
      #
      # @api private
      def escape(text)
        if text.start_with? '//'
          "//#{text}"
        else
          text
        end
      end
    end

    # Mixin for DSL contexts that can be bound to a REPL.
    #
    # This module provides the interface required for a DSL context to work
    # with the REPL server. Classes that include this module can execute
    # REPL-sent code in their own context, making their DSL methods available
    # to live coding clients.
    #
    # ## Requirements
    #
    # Classes that include this module must implement the {#binder} method,
    # which should return a Ruby Binding object representing the execution context.
    #
    # ## Integration with DynamicProxy
    #
    # Typically used with `Musa::Extension::DynamicProxy::DynamicProxy`:
    #
    #     class MyDSL
    #       include CustomizableDSLContext
    #
    #       def initialize
    #         @repl = REPL.new(bind: Musa::Extension::DynamicProxy::DynamicProxy.new(self))
    #       end
    #
    #       protected def binder
    #         @__binder ||= binding
    #       end
    #
    #       # DSL methods available in REPL:
    #       def play(note)
    #         # ...
    #       end
    #     end
    #
    # ## Execution Context
    #
    # Code sent via REPL is evaluated in the binding returned by {#binder},
    # giving it access to:
    #
    # - Instance variables of the DSL context
    # - All DSL methods (public and private)
    # - Local variables captured in the binding
    #
    # @example Basic implementation
    #   class LiveCodingEnvironment
    #     include Musa::REPL::CustomizableDSLContext
    #
    #     def initialize
    #       @sequencer = Musa::Sequencer::Sequencer.new(4, 24)
    #       @repl = REPL.new(bind: Musa::Extension::DynamicProxy::DynamicProxy.new(self))
    #     end
    #
    #     protected def binder
    #       @__binder ||= binding
    #     end
    #
    #     # DSL methods accessible from REPL:
    #     def at(position, &block)
    #       @sequencer.at(position, &block)
    #     end
    #   end
    #
    # @example From REPL client
    #   # Code sent by editor:
    #   at 0 { play C4 }
    #   at 4 { play D4 }
    #   # Executes in LiveCodingEnvironment instance context
    #
    # @see REPL The REPL server that uses this interface
    # @see Musa::Extension::DynamicProxy::DynamicProxy Wraps contexts for transparent method access
    module CustomizableDSLContext
      # Returns the binding for code execution.
      #
      # Subclasses must implement this method to provide a Ruby Binding object
      # in which REPL code will be evaluated. The binding determines what variables,
      # methods, and constants are accessible to executed code.
      #
      # ## Implementation Pattern
      #
      # The recommended pattern is to cache the binding in an instance variable:
      #
      #     protected def binder
      #       @__binder ||= binding
      #     end
      #
      # This captures the binding at the point of first call, including the
      # instance context (`self`) and any local variables in scope.
      #
      # @return [Binding] the execution context binding
      # @raise [NotImplementedError] if not implemented by including class
      #
      # @note Protected visibility prevents external access while allowing REPL use
      #
      # @example
      #   class MyDSL
      #     include CustomizableDSLContext
      #
      #     protected def binder
      #       @__binder ||= binding
      #     end
      #   end
      protected def binder
        raise NotImplementedError, 'Binder method should be implemented in target namespace as def binder; @__binder ||= binding; end'
      end

      # Executes source code in the DSL context.
      #
      # Called by the REPL to evaluate received code blocks. Delegates to
      # Binding#eval with the binding provided by {#binder}.
      #
      # ## Parameters
      #
      # - **source_block**: Ruby code as string
      # - **file**: Filename for error reporting (typically '(repl)')
      # - **line**: Starting line number for error reporting
      #
      # ## Error Handling
      #
      # Exceptions raised during evaluation propagate to the caller (REPL),
      # which formats them and sends them to the client.
      #
      # @param source_block [String] Ruby code to execute
      # @param file [String] filename for backtrace (usually '(repl)')
      # @param line [Integer] starting line number for backtrace
      # @return [Object] result of evaluating the source code
      #
      # @raise [Exception] any exception raised by the executed code
      #
      # @example Internal usage by REPL
      #   # REPL calls this internally:
      #   context.execute("sequencer.at 0 { puts 'tick' }", "(repl)", 1)
      #
      # @see REPL#bind= Where this method is called during code execution
      def execute(source_block, file, line)
        binder.eval source_block, file, line
      end
    end
  end
end
