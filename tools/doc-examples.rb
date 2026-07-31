# Runs the @example blocks of the inline documentation and checks every output
# they declare with `# =>`.
#
# WHY THIS EXISTS. Documentation about behaviour that nobody executes drifts, and
# in a stack of derived layers -- source, YARD, docs/, condensed references -- the
# drift does not merely survive the journey, it is amplified: condensing is also
# editorialising, and editorialising a falsehood turns it into a rule. Several
# were found that way, among them an @example claiming FIBO() started at 0 when
# it has always started at 1, which a condensed reference then restated as a
# warning "not 1, 1, 2, 3...".
#
# The examples are the part people copy. They must be the part that runs.
#
# HOW. Each @example block is extracted whole -- not line by line -- because its
# lines depend on each other, and executed in a forked child so that `using`
# refinements, monkey-patched modes and registered definitions cannot leak from
# one example into the next. Statements are accumulated until they parse, then
# evaluated in order; wherever a statement declares an output, the value is
# compared against it.
#
# Declared outputs that are prose ("E (in scale)", "the chromatic scale") are
# counted apart: they are not claims a test can contradict, and that is worth
# knowing on its own.
#
#   ruby tools/doc-examples.rb            # everything
#   ruby tools/doc-examples.rb series     # only paths matching "series"
#   ruby tools/doc-examples.rb -v         # list every mismatch in full

require 'json'
require 'stringio'
require 'timeout'
require 'tmpdir'
require_relative '../lib/musa-dsl'

module DocExamples
  Example = Struct.new(:file, :line, :title, :code, :namespace, :block, keyword_init: true)
  Check = Struct.new(:statement, :declared, :actual, :status, keyword_init: true)

  # A declared output we can compare against, as opposed to a description of one.
  LITERAL = /\A(\[.*\]|\{.*\}|-?[\d._\/r]+|true|false|nil|:[a-z_]+[?!]?|".*"|'.*')\z/i

  # An example may declare that a statement FAILS -- `# => ArgumentError: cannot
  # move back` -- and that is how documentation usually describes a guard. Read
  # naively the raise looks like the runner's own failure, so the claim goes
  # unchecked precisely where the documentation is making a promise about
  # rejection.
  EXCEPTION = /\A([A-Z]\w*(?:::\w+)*)\s*(?::.*)?\z/m

  # What closes an @example block. Named explicitly rather than "anything
  # starting with @", because `@melody = (0) (+2)` is neumalang -- a variable in
  # the notation, not a YARD tag -- and cutting the example there truncated a
  # multi-line string in the middle.
  TAG = /\A@!?(param|return|example|api|see|note|raise|yield\w*|option|overload|
              deprecated|since|todo|abstract|attr\w*|author|version|method|
              attribute|visibility|private|scope)\b/x

  module_function

  # Most declared outputs are glossed: `# => 4   (major third)`, `# => 1r (start
  # of bar 1)`. Read whole they are prose and go unchecked -- which is how a
  # value can be wrong and nobody notice, the exact failure this tool exists for.
  # A gloss is separated from the value by a run of spaces, which is what tells
  # it apart from `(1/1)`, a Rational's own inspect.
  def value_of(declared)
    return declared if declared =~ LITERAL

    head = declared.split(/\s{2,}/, 2).first.to_s.strip

    head =~ LITERAL ? head : declared
  end

  # Every @example block in the inline documentation, with its code recovered
  # from the comment, the namespace it is documented inside, and which run of
  # comment lines it belongs to.
  #
  # Both extras exist because the examples are not self-contained, and the
  # documentation itself says how they are meant to be read:
  #
  #   * `namespace` -- an example under `module Musa::MusicXML` writes
  #     `PitchedNote`, not `Musa::MusicXML::PitchedNote`, because that is what
  #     the reader has in scope at that point in the file.
  #   * `block` -- consecutive @examples in ONE comment are a narrative: the
  #     second says `c_major.note_of_pitch(...)` because the first built
  #     `c_major`. Splitting them is what made most of them fail.
  def extract(root = File.expand_path('../lib', __dir__))
    Dir.glob(File.join(root, '**/*.rb')).sort.flat_map do |path|
      lines = File.readlines(path)
      examples = []
      current = nil
      blanks = 0
      namespace = []   # [indent, name] pairs, deepest last
      block = 0

      lines.each_with_index do |line, index|
        if (match = line.match(/^(\s*)(?:module|class)\s+([A-Z][\w:]*)/))
          indent = match[1].length
          namespace.pop while namespace.any? && namespace.last.first >= indent
          namespace << [indent, match[2]]
        elsif (match = line.match(/^(\s*)end\b/))
          indent = match[1].length
          namespace.pop while namespace.any? && namespace.last.first >= indent
        end

        if (match = line.match(/^\s*#\s*@example\s*(.*)$/))
          examples << current if current
          current = Example.new(file: path, line: index + 1, title: match[1].strip,
                                code: [], namespace: namespace.map(&:last), block: [path, block])
          blanks = 0
        elsif current
          # The block continues while the comment stays indented under it; another
          # tag or the end of the comment closes it.
          #
          # A bare `#` does NOT close it. Almost every DSL example in this codebase
          # breathes -- `field :root, ...` <blank> `constructor do ... end` -- and
          # ending the block at the first blank line kept the first two lines of it
          # and threw away the rest, which then failed to parse. Blank lines are
          # held back and only committed when indented content follows them, so a
          # `#` before a `@see` still closes cleanly.
          if line.match?(/^\s*#\s*$/)
            blanks += 1
          elsif (match = line.match(/^\s*#\s{3,}(.*)$/)) && match[1] !~ TAG
            blanks.times { current.code << '' }
            blanks = 0
            current.code << match[1]
          else
            examples << current
            current = nil
          end
        end

        # Anything that is not part of a comment ends the narrative.
        block += 1 unless line.match?(/^\s*(#|$)/)
      end
      examples << current if current

      examples.reject { |example| example.code.join.strip.empty? }
    end
  end

  # The @examples of one comment, in the order they are written. They share a
  # process and a binding, because they share a story.
  def narratives(examples)
    examples.group_by(&:block).values
  end

  # The vocabulary a file's documentation establishes for itself.
  #
  # `c_major.note_of_pitch(64)` appears in scales.rb without `c_major` being
  # bound anywhere near it -- but the file DOES say what it is, at the top, in
  # the `## Usage` block, and again in other examples further down. The reader
  # carries that binding from one example to the next; the runner has to as well,
  # or every example after the first fails for a reason that has nothing to do
  # with what it demonstrates.
  #
  # So: every assignment written anywhere in the file's documentation, in the
  # order it appears, run before the narrative and allowed to fail. It is a
  # preamble, not a test -- what it cannot build simply will not be there.
  ASSIGNMENT = /\A\s*([a-z_][\w]*)\s*=\s*[^=~].*\z/

  # Only what appears BEFORE the example: a reader carries forward what they have
  # already read, and nothing else. Taking the whole file instead binds names to
  # whatever the last assignment in it happened to build, which invents
  # mismatches that are the runner's fault and not the documentation's.
  # An assignment may span several lines -- the vocabulary a file establishes is
  # often a whole DSL block -- so lines are accumulated until they parse, exactly
  # as statements are. RUNAWAY caps that accumulation: a fragment that never
  # parses would otherwise swallow everything after it.
  RUNAWAY = 40

  def preamble(path, before:)
    pending = []

    File.readlines(path).first(before - 1).each_with_object([]) do |line, result|
      match = line.match(/^\s*#\s{2,}(.*)$/)

      unless match
        pending.clear
        next
      end

      code = match[1].sub(/\s*#\s*=>.*\z/, '').rstrip
      next if code.strip.empty? && pending.empty?

      pending << code

      parses = begin
        RubyVM::AbstractSyntaxTree.parse(pending.join("\n"))
      rescue SyntaxError
        false
      end

      pending.clear if pending.size > RUNAWAY
      next unless parses

      result << pending.join("\n") if pending.first =~ ASSIGNMENT
      pending.clear
    end
  end

  # Splits an example into statements, keeping each `# =>` with the statement it
  # belongs to. A statement grows until it parses: examples are full of calls
  # spread over several lines.
  def statements(code)
    result = []
    pending = []

    code.each do |line|
      declared = nil
      source = line

      if (match = line.match(/\A(.*?)\s*#\s*=>\s*(.+)\z/))
        source, declared = match[1], match[2].strip
      elsif (match = line.match(/\A\s*#\s*=>\s*(.+)\z/))
        source, declared = '', match[1].strip
      end

      # A continuation of the previous statement, not a new one. `chord =
      # scale.tonic.chord` parses on its own, so a following `.with_move(...)`
      # would be flushed as an orphan and taken for a syntax error -- and the
      # fluent chains are exactly where the interesting documentation is.
      if pending.empty? && source.strip.start_with?('.') && result.last && result.last[1].nil?
        pending << result.pop.first
      end

      pending << source unless source.strip.empty?

      joined = pending.join("\n")
      parses = begin
        !pending.empty? && RubyVM::AbstractSyntaxTree.parse(joined)
      rescue SyntaxError
        false
      end

      if declared
        # The output may be declared on its own line, after the statement.
        result << [joined.empty? ? result.pop&.first : joined, declared]
        pending = []
      elsif parses
        result << [joined, nil]
        pending = []
      end
    end

    result << [pending.join("\n"), nil] unless pending.empty?
    result.reject { |source, _| source.nil? || source.strip.empty? }
  end

  # How long one example may take before it is presumed hung. Documentation is
  # full of transports that block, clocks that wait and infinite series consumed
  # with `to_a`; without this the runner stops being a tool and becomes a hazard.
  TIMEOUT = 5

  # Runs the examples of one comment in a single process, in order, sharing a
  # binding -- and in isolation from every other comment, so refinements,
  # switched modes and registered definitions cannot leak between narratives.
  def run(narrative)
    read, write = IO.pipe

    pid = fork do
      read.close
      checks = []

      # Nothing the examples say out loud is wanted here: they log, they puts,
      # and Ruby reports a syntax error on stderr before raising it. All of it
      # would drown the report -- and, when this runs as a spec, the failures of
      # the rest of the suite. The findings travel through the pipe, which is a
      # different descriptor, so silencing these two loses nothing.
      $stdout.reopen(File::NULL)
      $stderr.reopen(File::NULL)

      # Somewhere harmless to run: the examples write files (`File.write
      # 'output.xml'`, ...) and a tool that litters the repository it is checking
      # is a hazard, not a check.
      Dir.chdir(Dir.mktmpdir('doc-examples'))

      # The ambient context the examples assume without saying so: nearly every
      # one calls S(), H(), Scales... unqualified. That they are not
      # self-contained is a documentation defect of its own -- said once here
      # rather than several hundred times by the runner.
      eval('include Musa::All', TOPLEVEL_BINDING) # rubocop:disable Security/Eval

      # And the namespace they are written inside, so that unqualified constants
      # resolve the way they do for a reader of that part of the file.
      #
      # By aliasing its constants and EXTENDING it, never `include`-ing it: a
      # comment inside `module AbsD` would otherwise include AbsD into Object,
      # making EVERY object an AbsD and quietly turning the answer to
      # `AbsD.is_compatible?({pitch: 60})` from false into true. Extending gives
      # the reader the module's methods, which is their position in the file,
      # without moving anyone else's ancestry.
      # Deeper levels overwrite shallower ones -- `Musa::Extension::DeepCopy::DeepCopy`
      # is what `DeepCopy` means to someone reading inside it -- but a name that
      # already existed at top level is touched.
      #
      # A module that contains a constant of its own name yields that inner one:
      # `Musa::Transport::Transport` is what `Transport` means to anyone who has
      # done `include Musa::All`, and aliasing the enclosing module over it is how
      # `Transport.new` came to be a call on a module.
      established = Object.constants(false)

      narrative.first.namespace.each_with_object([]) do |name, path|
        path << name
        begin
          scope = eval(path.join('::'), TOPLEVEL_BINDING) # rubocop:disable Security/Eval
          next unless scope.is_a?(Module)

          scope.constants(false).each do |constant|
            next if established.include?(constant)

            value = scope.const_get(constant)
            value = value.const_get(constant) if value.is_a?(Module) && value.const_defined?(constant, false)

            Object.send(:remove_const, constant) if Object.const_defined?(constant, false)
            Object.const_set(constant, value)
          end

          eval('self', TOPLEVEL_BINDING).extend(scope) unless scope.is_a?(Class) # rubocop:disable Security/Eval
        rescue StandardError, ScriptError
          nil # not defined at this point in the file: nothing to alias
        end
      end

      # The file's own vocabulary first, quietly -- minus any name the narrative
      # itself uses as a DSL verb.
      #
      # In Ruby a local variable shadows a method of the same name, so binding
      # `part` from an earlier example turns a later `part :p1, name: "Flute" do`
      # into a syntax error. The runner would then be reporting a defect it had
      # introduced -- and the hazard is real for readers too: name a local `part`
      # and the `part` verb stops being available.
      spoken = narrative.flat_map(&:code)

      preamble(narrative.first.file, before: narrative.first.line).each do |code|
        name = code[ASSIGNMENT, 1]
        next if name && spoken.any? { |line| line.match?(/^\s*#{Regexp.escape(name)}\s+[^=\s]/) }

        eval(code, TOPLEVEL_BINDING) rescue nil # rubocop:disable Security/Eval, Style/RescueModifier
      end

      # Refinements are lexically scoped to the eval that activates them, so a
      # `using` written as the first line of an example switches off again on the
      # next statement -- and the example goes on to demonstrate exactly what the
      # refinement provides. Carrying them forward is what a file does for its own
      # reader, and it is what makes `.to_neumas` and `dup(deep: true)` mean
      # anything after line one.
      usings = []

      statements(narrative.flat_map(&:code)).each do |source, declared|
        example = narrative.first

        claimed = declared && value_of(declared)

        # What the example says it raises, if it says so at all.
        wanted = if claimed && (match = claimed.match(EXCEPTION))
                   begin
                     constant = eval(match[1], TOPLEVEL_BINDING) # rubocop:disable Security/Eval
                     constant if constant.is_a?(Class) && constant <= Exception
                   rescue Exception # rubocop:disable Lint/RescueException
                     nil
                   end
                 end

        # What the statement PRINTS is often what the example declares: `puts
        # seq.empty?  # => false` is about the false on screen, not about puts
        # returning nil, and `clock.tick  # => "Tick 1"` is about what a
        # registered block printed. Read as return values these are all nil.
        printed = StringIO.new
        stdout = $stdout
        $stdout = printed

        begin
          value = eval((usings + [source]).join("\n"), TOPLEVEL_BINDING, example.file, example.line) # rubocop:disable Security/Eval
          usings << source if source.match?(/\A\s*using\s+\S/)
        rescue LoadError => e
          # A gem this project does not depend on -- midi-communications and
          # friends, which also want hardware. The example is not wrong; it
          # cannot run here, and everything after it would fail for the same
          # reason, so the narrative stops rather than reporting the cascade.
          checks << Check.new(statement: source, declared: declared,
                              actual: e.message.lines.first.to_s.strip, status: :external)
          break
        rescue Exception => e # rubocop:disable Lint/RescueException
          checks << Check.new(statement: source, declared: declared,
                              actual: "#{e.class}: #{e.message.lines.first.to_s.strip}",
                              status: wanted ? (e.is_a?(wanted) ? :ok : :mismatch) : :error)
          next
        ensure
          $stdout = stdout
        end

        next unless declared

        output = printed.string.strip
        spoke = value.nil? && !output.empty?

        status =
          if wanted
            :mismatch # it promised to reject this and did not
          elsif claimed !~ LITERAL
            :prose
          else
            expected = begin
              eval(claimed, TOPLEVEL_BINDING) # rubocop:disable Security/Eval
            rescue Exception # rubocop:disable Lint/RescueException
              :__unparseable__
            end

            if expected == :__unparseable__
              :prose
            elsif value == expected || value.inspect.gsub(/\s+/, '') == claimed.gsub(/\s+/, '')
              :ok
            elsif spoke && (output == expected.to_s || output == claimed.strip)
              :ok
            else
              :mismatch
            end
          end

        checks << Check.new(statement: source, declared: declared,
                            actual: spoke ? "printed #{output.inspect}" : value.inspect,
                            status: status)
      end

      write.write(JSON.dump(checks.map(&:to_h)))
      write.close
      exit!(0)
    end

    write.close

    payload = nil
    timed_out = false

    begin
      Timeout.timeout(TIMEOUT) { payload = read.read }
      Process.waitpid(pid)
    rescue Timeout::Error
      timed_out = true
      Process.kill('KILL', pid)
      Process.waitpid(pid)
    ensure
      read.close
    end

    if timed_out
      return [Check.new(statement: narrative.flat_map(&:code).join("\n"), declared: nil,
                        actual: "did not finish in #{TIMEOUT}s", status: :timeout)]
    end

    (JSON.parse(payload, symbolize_names: true) rescue []).map { |h| Check.new(**h.merge(status: h[:status].to_sym)) }
  end
end

if $PROGRAM_NAME == __FILE__
  verbose = ARGV.delete('-v')
  filter = ARGV.first

  examples = DocExamples.extract
  examples = examples.select { |e| e.file.include?(filter) } if filter

  totals = Hash.new(0)
  failures = []

  narratives = DocExamples.narratives(examples)

  narratives.each do |narrative|
    DocExamples.run(narrative).each do |check|
      totals[check.status] += 1
      failures << [narrative.first, check] if %i[mismatch error timeout].include?(check.status)
    end
  end

  root = File.expand_path('../lib/musa-dsl', __dir__)
  puts format('%d @example blocks in %d documentation comments', examples.size, narratives.size)
  puts format('  declared outputs checked: %d ok, %d MISMATCH', totals[:ok], totals[:mismatch])
  puts format('  errors while running:     %d', totals[:error])
  puts format('  hung (killed after %ds):   %d', DocExamples::TIMEOUT, totals[:timeout])
  puts format('  declared as prose (nothing a test can contradict): %d', totals[:prose])
  puts format('  need a gem this project does not depend on:        %d', totals[:external])

  unless failures.empty?
    puts
    puts 'MISMATCHES AND ERRORS'
    (verbose ? failures : failures.first(30)).each do |example, check|
      where = "#{example.file.sub("#{root}/", '')}:#{example.line}"
      puts format('  %-42s %s', where, example.title[0, 40])
      puts format('    %s', check.statement.gsub(/\s*\n\s*/, ' ')[0, 88])
      if %i[error timeout].include?(check.status)
        puts format('    RAISED  %s', check.actual[0, 88])
      else
        puts format('    says    %s', check.declared[0, 76])
        puts format('    is      %s', check.actual[0, 76])
      end
    end
    puts format('  ... and %d more (-v for all)', failures.size - 30) if !verbose && failures.size > 30
  end

  exit(failures.empty? ? 0 : 1)
end
