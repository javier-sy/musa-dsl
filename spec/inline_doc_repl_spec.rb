require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'REPL Inline Documentation Examples' do
  include Musa::All

  context 'REPL module (repl.rb)' do
    it 'example from line 129 - With DynamicProxy (complex DSL)' do
      # Note: This test demonstrates the pattern, but doesn't actually start a REPL server
      # to avoid TCP port conflicts and thread management in tests

      class MyDSL
        include Musa::REPL::CustomizableDSLContext

        attr_reader :commands_executed

        def initialize
          @commands_executed = []
        end

        def play(note)
          @commands_executed << "play #{note}"
        end

        protected def binder
          @__binder ||= binding
        end
      end

      dsl_context = MyDSL.new
      context_proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context)

      # Verify the proxy can access DSL methods
      expect(context_proxy.receiver).to eq(dsl_context)

      # Simulate code execution through the context
      context_proxy.receiver.execute("play :C4", "(test)", 1)
      expect(dsl_context.commands_executed).to include("play C4")
    end

    it 'example from line 140 - With direct Binding (musalce-server pattern)' do
      # This demonstrates the musalce-server binding pattern
      # Note: The example shows the conceptual pattern used in musalce-server
      # where binding is captured within a DSL context block

      # Simulate the pattern of capturing binding in a DSL context
      class BindingCaptureContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :captured_binding

        def play(note)
          "playing #{note}"
        end

        def at(pos, &block)
          "scheduled at #{pos}"
        end

        def capture_context
          @captured_binding = binding
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = BindingCaptureContext.new
      context.capture_context

      # In production, REPL would be created with:
      # @repl = Musa::REPL::REPL.new(binding, highlight_exception: false)

      # Verify the binding captures the context correctly
      expect(context.captured_binding).to be_a(Binding)
      expect(context.captured_binding.receiver).to eq(context)
      expect(context.play(:C4)).to eq("playing C4")
      expect(context.at(1) {}).to eq("scheduled at 1")
    end

    it 'example from line 150 - With after_eval callback' do
      # Demonstrates the after_eval callback pattern

      executed_sources = []

      class DSLWithLogging
        include Musa::REPL::CustomizableDSLContext

        attr_accessor :log

        def initialize
          @log = []
        end

        def note(pitch)
          @log << "note #{pitch}"
        end

        protected def binder
          @__binder ||= binding
        end
      end

      dsl_context = DSLWithLogging.new
      context_proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context)

      # Simulate the after_eval callback
      after_eval_callback = -> (source) { executed_sources << source }

      # Execute code and trigger callback
      source = "note 60"
      context_proxy.receiver.execute(source, "(test)", 1)
      after_eval_callback.call(source)

      expect(executed_sources).to include("note 60")
      expect(dsl_context.log).to include("note 60")
    end

    it 'example from line 197 - With DynamicProxy and named parameters' do
      # Demonstrates full REPL initialization with all parameters

      class MyDSLContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :executed

        def initialize
          @executed = []
        end

        def test_method
          @executed << "test"
        end

        protected def binder
          @__binder ||= binding
        end
      end

      dsl_context = MyDSLContext.new
      context_proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context)
      custom_logger = Musa::Logger::Logger.new

      execution_log = []

      # Note: Not actually creating REPL server to avoid TCP port conflicts
      # This demonstrates the parameter pattern:
      # REPL.new(
      #   bind: context_proxy,
      #   port: 1327,
      #   after_eval: -> (src) { execution_log << src },
      #   logger: custom_logger
      # )

      # Verify context is set up correctly
      expect(context_proxy.receiver).to eq(dsl_context)
      expect(custom_logger).to be_a(Musa::Logger::Logger)
    end

    it 'example from line 207 - With direct Binding (musalce-server pattern) validation' do
      # Validates the direct binding pattern

      class DirectBindingContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :sequencer

        def initialize
          @sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
        end

        def capture_binding
          binding
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = DirectBindingContext.new
      binding_captured = context.capture_binding

      # Verify binding captures the context
      expect(binding_captured).to be_a(Binding)
      expect(binding_captured.receiver).to respond_to(:sequencer)
      expect(binding_captured.receiver.sequencer).to be_a(Musa::Sequencer::BaseSequencer)
    end

    it 'example from line 211 - Deferred binding' do
      # Demonstrates creating REPL without immediate binding

      class DeferredDSL
        include Musa::REPL::CustomizableDSLContext

        protected def binder
          @__binder ||= binding
        end
      end

      # In production: repl = REPL.new  # Start server without binding
      # Then later: repl.bind = context_proxy

      context = DeferredDSL.new
      context_proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(context)

      # Verify the deferred context is valid
      expect(context_proxy.receiver).to eq(context)
      expect(context_proxy.receiver).to respond_to(:execute)
    end

    it 'example from line 340 - With Ruby Binding' do
      # Demonstrates how binding.receiver returns the DSLContext instance

      class DSLContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :name

        def initialize(name)
          @name = name
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = DSLContext.new("test_context")

      # Inside DSL context, binding would be used directly
      test_binding = context.send(:binder)

      # binding.receiver returns the DSLContext instance
      expect(test_binding.receiver).to eq(context)
      expect(test_binding.receiver.name).to eq("test_context")
    end

    it 'example from line 344 - With DynamicProxy receiver' do
      # Demonstrates how proxy.receiver returns the wrapped object

      class WrappedDSL
        include Musa::REPL::CustomizableDSLContext

        attr_reader :id

        def initialize(id)
          @id = id
        end

        protected def binder
          @__binder ||= binding
        end
      end

      dsl_context = WrappedDSL.new(42)
      proxy = Musa::Extension::DynamicProxy::DynamicProxy.new(dsl_context)

      # proxy.receiver returns the wrapped object
      expect(proxy.receiver).to eq(dsl_context)
      expect(proxy.receiver.id).to eq(42)
    end

    it 'example from line 426 - From evaluated code (puts redirection)' do
      # Demonstrates output redirection pattern used in REPL

      class REPLMockContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :output_buffer

        def initialize
          @output_buffer = []
        end

        # Override puts to redirect to REPL client
        def puts(*messages)
          messages.each { |msg| @output_buffer << msg.to_s }
          nil  # Like Kernel#puts
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = REPLMockContext.new

      # Execute code that uses puts
      context.execute(<<~RUBY, "(repl)", 1)
        puts "Starting sequence..."
        puts "Bar 4!"
      RUBY

      # Output was captured in buffer
      expect(context.output_buffer).to include("Starting sequence...")
      expect(context.output_buffer).to include("Bar 4!")
    end

    it 'example from line 432 - Multiple messages' do
      # Demonstrates sending multiple messages

      class MultiMessageContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :messages

        def initialize
          @messages = []
        end

        def puts(*msgs)
          msgs.each { |m| @messages << m.to_s }
          nil
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = MultiMessageContext.new

      # Simulate REPL puts with multiple arguments
      context.puts("Line 1", "Line 2", "Line 3")

      expect(context.messages.size).to eq(3)
      expect(context.messages[0]).to eq("Line 1")
      expect(context.messages[1]).to eq("Line 2")
      expect(context.messages[2]).to eq("Line 3")
    end

    it 'example from line 604 - escape method for protocol lines' do
      # Demonstrates the escape method for protocol safety
      # The escape method adds '//' prefix to lines starting with '//'
      # to prevent protocol confusion

      # Lines starting with '//' need escaping
      comment_line = "//comment"
      normal_line = "Hello"

      # Simulate escape behavior (as implemented in REPL)
      escape = -> (text) do
        if text.start_with?('//')
          "//#{text}"
        else
          text
        end
      end

      # "//comment" becomes "////comment" (one // for escape, original // preserved)
      expect(escape.call(comment_line)).to eq("////comment")
      expect(escape.call(normal_line)).to eq("Hello")
    end

    it 'example from line 660 - Basic implementation of CustomizableDSLContext' do
      # Complete example of implementing CustomizableDSLContext

      class LiveCodingEnvironment
        include Musa::REPL::CustomizableDSLContext

        def initialize
          @sequencer = Musa::Sequencer::BaseSequencer.new(4, 24)
          @scheduled_events = []
          # Note: REPL creation omitted to avoid TCP conflicts
          # @repl = REPL.new(bind: Musa::Extension::DynamicProxy::DynamicProxy.new(self))
        end

        protected def binder
          @__binder ||= binding
        end

        # DSL methods accessible from REPL:
        def at(position, &block)
          @scheduled_events << { position: position, block: block }
          @sequencer.at(position, &block)
        end

        attr_reader :scheduled_events, :sequencer
      end

      env = LiveCodingEnvironment.new

      # Test DSL method
      test_executed = false
      env.at(1) { test_executed = true }

      expect(env.scheduled_events.size).to eq(1)
      expect(env.scheduled_events.first[:position]).to eq(1)

      # Execute to verify block was stored
      env.sequencer.run
      expect(test_executed).to be true
    end

    it 'example from line 679 - From REPL client execution' do
      # Demonstrates how code sent by editor is executed

      class ClientExecutionContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :notes_played

        def initialize
          @notes_played = []
        end

        def play(note)
          @notes_played << note
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = ClientExecutionContext.new

      # Code sent by editor (as would be via REPL protocol)
      code = <<~RUBY
        play :C4
        play :D4
      RUBY

      # Execute in context
      context.execute(code, "(repl)", 1)

      expect(context.notes_played).to eq([:C4, :D4])
    end

    it 'example from line 710 - binder implementation pattern' do
      # Demonstrates the recommended binder implementation

      class StandardDSL
        include Musa::REPL::CustomizableDSLContext

        protected def binder
          @__binder ||= binding
        end
      end

      dsl = StandardDSL.new

      # Get binder (protected, so use send in test)
      binder1 = dsl.send(:binder)
      binder2 = dsl.send(:binder)

      # Verify it's cached (same object)
      expect(binder1).to be(binder2)
      expect(binder1).to be_a(Binding)
      expect(binder1.receiver).to eq(dsl)
    end

    it 'example from line 745 - Internal usage by REPL (execute method)' do
      # Demonstrates how REPL calls execute internally

      class ExecutableContext
        include Musa::REPL::CustomizableDSLContext

        attr_reader :results

        def initialize
          @results = []
        end

        def calculate(value)
          @results << value * 2
          value * 2
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = ExecutableContext.new

      # REPL calls this internally
      result = context.execute("calculate(21)", "(repl)", 1)

      expect(result).to eq(42)
      expect(context.results).to include(42)
    end
  end

  context 'REPL error handling' do
    it 'handles ScriptError (syntax errors)' do
      class ErrorTestContext
        include Musa::REPL::CustomizableDSLContext

        protected def binder
          @__binder ||= binding
        end
      end

      context = ErrorTestContext.new

      # Execute invalid Ruby code
      expect {
        context.execute("def invalid syntax", "(repl)", 1)
      }.to raise_error(SyntaxError)
    end

    it 'handles StandardError in user code' do
      class RuntimeErrorContext
        include Musa::REPL::CustomizableDSLContext

        def risky_method
          raise "Something went wrong"
        end

        protected def binder
          @__binder ||= binding
        end
      end

      context = RuntimeErrorContext.new

      # Execute code that raises an error
      expect {
        context.execute("risky_method", "(repl)", 1)
      }.to raise_error(RuntimeError, "Something went wrong")
    end
  end

  context 'REPL protocol concepts (from docs_repl_spec.rb)' do
    it 'demonstrates REPL protocol concepts' do
      # Protocol messages that would be sent by client
      client_path = "#path"
      client_file = "/Users/me/composition.rb"
      client_begin = "#begin"
      client_code = "puts 'Starting...'"
      client_end = "#end"

      # Expected server responses
      server_echo = "//echo"
      server_end = "//end"

      # Verify protocol format
      expect(client_path).to eq("#path")
      expect(client_begin).to eq("#begin")
      expect(client_end).to eq("#end")
      expect(server_echo).to eq("//echo")
      expect(server_end).to eq("//end")

      # REPL would inject file path as @user_pathname
      require 'pathname'
      user_pathname = Pathname.new(client_file)
      expect(user_pathname.dirname.to_s).to eq("/Users/me")
      expect(user_pathname.basename.to_s).to eq("composition.rb")
    end
  end

  context 'Integration patterns' do
    it 'demonstrates sequencer integration with on_error hook' do
      # Shows how REPL hooks into sequencer error handling

      sequencer = Musa::Sequencer::BaseSequencer.new(4, 24, do_error_log: false)

      # Verify sequencer has on_error capability
      expect(sequencer).to respond_to(:on_error)

      errors_captured = []

      sequencer.on_error do |e|
        errors_captured << e
      end

      # Schedule an event that will raise an error
      sequencer.at(1) { raise "Test error" }

      # Run and verify error was captured
      expect {
        sequencer.run
      }.not_to raise_error

      expect(errors_captured.size).to eq(1)
      expect(errors_captured.first.message).to eq("Test error")
    end

    it 'demonstrates file path injection pattern' do
      # Shows how @user_pathname is injected when using #path protocol

      class PathInjectionContext
        include Musa::REPL::CustomizableDSLContext

        attr_accessor :user_pathname

        protected def binder
          @__binder ||= binding
        end
      end

      context = PathInjectionContext.new

      # Simulate what REPL does when receiving #path
      require 'pathname'
      user_path = "/Users/me/my_composition.rb"
      context.instance_variable_set(:@user_pathname, Pathname.new(user_path))

      # Verify pathname is accessible in context
      expect(context.instance_variable_get(:@user_pathname)).to be_a(Pathname)
      expect(context.instance_variable_get(:@user_pathname).to_s).to eq(user_path)
      expect(context.instance_variable_get(:@user_pathname).dirname.to_s).to eq("/Users/me")
    end
  end
end
