require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'REPL Inline Documentation Examples' do
  include Musa::All

  context 'REPL module (repl.rb)' do

    it 'From evaluated code (puts redirection)' do
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

    # The real method, not a copy of it. This used to build a lambda "as
    # implemented in REPL" and assert against that -- which passes whatever the
    # library does.
    #
    # `__send__` and not `send`: REPL defines an instance method `send` of its
    # own, for the protocol, and it shadows Object#send.
    it 'escapes a line that would otherwise look like a protocol command' do
      repl = Musa::REPL::REPL.allocate

      expect(repl.__send__(:escape, '//comment')).to eq '////comment'
      expect(repl.__send__(:escape, 'Hello')).to eq 'Hello'
    end

    it 'From REPL client execution' do
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

    it 'binder implementation pattern' do
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

  end

  context 'REPL protocol concepts (from docs_repl_spec.rb)' do
  end

end
