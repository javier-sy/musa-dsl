require 'spec_helper'

require_relative '../tools/doc-examples'

# Runs every @example block of the inline documentation and checks every output
# it declares with `# =>`.
#
# WHY THIS IS A SPEC AND NOT A TOOL YOU REMEMBER TO RUN. The whole point of the
# audit this comes from is that a check nobody is forced to run stops being a
# check: `tools/doc-examples.rb` found 21 documented outputs the code
# contradicted and some 460 examples that could not run at all, all of it in
# documentation that had been read many times and executed never. Leaving the
# runner as a command would put the next drift back on someone's memory.
#
# This project has no Rakefile and no CI for tests; `bundle exec rspec` is how
# the suite is run, so this is where the check has to live. It costs about half
# a minute, which is roughly what the rest of the suite costs, and is the price
# of the documentation being true.
#
# WHAT IS ASSERTED. Three things, in decreasing severity:
#
#   1. **No mismatch.** A declared output the code contradicts is a lie in the
#      part of the documentation people copy. The only tolerated ones are listed
#      in KNOWN_LIES, each tied to an open issue.
#
#   2. **A floor on what is verified.** Claims actually checked may not go down.
#      This cannot be satisfied by deleting examples, only by keeping them
#      runnable.
#
#   3. **A ceiling on what cannot be verified.** Examples that fail to run are
#      documentation defects too -- an example nobody can execute teaches
#      nothing -- but there is a backlog of them, so the ceiling ratchets: it
#      may only be lowered, and this spec says so when it can be.
#
# Run it alone, with detail, while working on documentation:
#
#   bundle exec ruby tools/doc-examples.rb series -v
RSpec.describe 'Inline documentation examples', runs_last: true do
  # Declared outputs the code contradicts and that are not fixed yet. Each entry
  # names the issue that will remove it. Nothing else may be added here without
  # an issue: the rule of this audit is that a documentation spec disagreeing
  # with the documentation is a bug report, not an assertion to loosen.
  KNOWN_LIES = {}.freeze

  # Claims verified today. May only grow.
  VERIFIED_FLOOR = 843

  # Spec examples named `@example <title>` whose title no longer appears in the
  # documentation. At zero, and it stays there: an example that loses its
  # reference has either been renamed -- follow it -- or removed, in which case
  # the spec should stop claiming to come from one.
  ORPHANED_REFERENCES = 0

  # The prose documentation, `docs/**/*.md`, measured apart. It is a different
  # corpus with a different failure mode: the inline examples were written next
  # to the code they describe, these were written about it, and being written
  # ABOUT something is what lets a claim drift from it.
  #
  # Claims it verifies today. May only grow.
  DOCS_VERIFIED_FLOOR = 150

  # Blocks that declare an output and still do not run. A block that declares
  # nothing is illustration -- `direction do dynamics 'f' end` shown outside the
  # measure it belongs to -- and is not counted here; a block that makes a claim
  # has to run for the claim to mean anything.
  #
  # At zero, and it stays there: every claim the prose documentation makes is
  # now executed where it is written. What is left unrun claims nothing, which
  # is a different problem and has its own reading -- an illustration teaches by
  # showing shape, and shape is not checkable.
  DOCS_BROKEN_CEILING = 0

  # The documentation specs still to migrate.
  #
  # `inline_doc_*_spec.rb` and `docs_*_spec.rb` were written months ago to
  # verify the `@example` blocks by transcribing them. The doctest now runs
  # every one of those where it is written, so the transcribing half duplicates
  # a mechanism -- and a transcription drifts in silence, which is how one of
  # them came to carry a `.extend` the document lacked and another to note a
  # wrong `@return` beside its assertion instead of reporting it.
  #
  # The migration is per example, not per file:
  #
  #   * asserts what the document already declares -> delete, the doctest has it
  #   * knows what the document does not say -> promote: the `# =>` goes in the
  #     example. Not mechanisable, because most of them assert an expression the
  #     example does not write, so promoting is deciding what the example should
  #     SHOW -- and it is where the value is: doing it for series found
  #     `anticipate` documented with two block parameters when it takes three
  #   * asserts something that cannot be declared -- `.randomize` has no value
  #     to write down, only "same elements, different order" -- stays for good,
  #     renamed for what it is
  #
  # What is left is NOT more of the same. The mechanical part is done: every
  # example asserting what the documentation already declares, every assertion
  # that a hash literal contains what was just written into it, every set of
  # `include` fragments provably inside a string the example now declares. What
  # remains needs authorship, and it was measured rather than guessed:
  #
  #   * ~180 could be promoted -- their spec asserts a value and the example
  #     says nothing about it. Not mechanisable: they assert expressions the
  #     example does not write, so promoting means deciding what the example
  #     should SHOW. Tried twice, mechanically, and it applied to 8 of them in
  #     series and 18 in musicxml because there the expression was already
  #     written down;
  #
  #   * the rest is behaviour an example cannot declare -- threads, callbacks,
  #     clocks, doubles, `raise_error`. transport is 33 of 34 like that, repl
  #     19 of 20, midi 28 of 30. Those files are not pending work: they are
  #     misnamed, and their resolution is the one series got, a name that says
  #     what they hold.
  #
  # MAY ONLY GO DOWN. Series and musicxml are migrated; this counts what is
  # left, and it counts examples rather than files so that renaming a file
  # cannot make the number look better than the work done.
  UNMIGRATED_DOC_SPECS = 329

  # Examples that do not run: raise, block until killed, or need a gem this
  # project does not depend on. Counted together because which of the three a
  # given example falls into depends on the machine -- with midi-communications
  # installed but no hardware, "needs a gem" becomes "raises" -- and the sum is
  # what stays stable. MAY ONLY GO DOWN.
  UNRUNNABLE_CEILING = 8

  # Every narrative is forked and given five seconds -- documentation is full of
  # transports that block and infinite series consumed with to_a -- so a machine
  # under enough load could kill one that normally finishes and move its checks
  # from verified to unrunnable. If this spec ever fails on the two counts at
  # once, and both by the same amount, that is what happened: it is the machine,
  # not the documentation. Raising DocExamples::TIMEOUT is the remedy, at the
  # cost of five seconds per example that blocks by design.
  before(:context) do
    @checks = DocExamples.narratives(DocExamples.extract).flat_map do |narrative|
      DocExamples.run(narrative).collect { |check| [narrative.first, check] }
    end

    @doc_checks = DocExamples.narratives(DocExamples.extract_markdown).flat_map do |narrative|
      claims = narrative.any? { |example| example.code.any? { |line| line.include?('# =>') } }

      DocExamples.run(narrative).collect { |check| [narrative.first, check, claims] }
    end
  end

  def tally(status)
    @checks.count { |_, check| check.status == status }
  end

  def normalise(title)
    title.to_s.strip.downcase.gsub(/[^a-z0-9]+/, ' ').strip
  end

  def where(example)
    example.file.sub(%r{\A.*/lib/musa-dsl/}, '')
  end

  it 'declares no output that the code contradicts' do
    mismatches = @checks.select { |_, check| check.status == :mismatch }
                        .group_by { |example, _| where(example) }

    unexpected = mismatches.reject { |file, found| KNOWN_LIES[file] == found.size }

    detail = unexpected.collect do |file, found|
      found.collect do |example, check|
        "  #{file}:#{example.line}  #{check.statement.gsub(/\s*\n\s*/, ' ')[0, 70]}\n" \
          "    says #{check.declared[0, 60]}\n    is   #{check.actual[0, 60]}"
      end
    end.flatten.join("\n")

    expect(unexpected).to be_empty,
                          "The documentation declares outputs the code does not produce.\n" \
                          "Either the document lies (correct the document) or the code does " \
                          "(open an issue and add it to KNOWN_LIES).\n\n#{detail}"

    # And the known ones may not quietly grow beyond what their issue covers.
    KNOWN_LIES.each do |file, expected|
      found = mismatches[file]&.size || 0

      expect(found).to eq(expected),
                       "#{file} has #{found} contradicted outputs, KNOWN_LIES expects #{expected}. " \
                       'If they were fixed, remove the entry; if there are new ones, they are new bugs.'
    end
  end

  it 'references documentation examples that still exist' do
    documented = @checks.map { |example, _| example }.to_set { |example| normalise(example.title) }
    documented.merge(DocExamples.extract.collect { |example| normalise(example.title) })

    referenced = Dir.glob(File.expand_path('{inline_doc_*,docs_*}.rb', __dir__)).flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        match = line.match(/^\s*it\s+(['"])@example (.+?)\1\s+do/)
        ["#{File.basename(path)}:#{index + 1}", match[2]] if match
      end
    end

    orphans = referenced.reject { |_, title| documented.include?(normalise(title)) }

    detail = orphans.first(12).collect { |where, title| "  #{where}  #{title}" }.join("\n")

    expect(orphans.size).to be <= ORPHANED_REFERENCES,
                            "#{orphans.size} spec examples name an @example the documentation no " \
                            "longer has, above the #{ORPHANED_REFERENCES} already known. Either " \
                            "the example was renamed -- follow it -- or it was removed, and the " \
                            "spec is testing a claim nobody makes.\n\n#{detail}"

    expect(orphans.size).to be >= ORPHANED_REFERENCES,
                            "Only #{orphans.size} orphaned references left. Lower " \
                            "ORPHANED_REFERENCES to #{orphans.size}."
  end

  # A value with a gloss the splitter cannot separate goes through as prose, and
  # prose is compared with nothing. That is where
  # `tonic.up(4, :natural).pitch  # => 71 (4 scale degrees = B)` sat for as long
  # as it existed, wrong by four semitones, in a file with a green suite -- and
  # 107 more declarations were in the same shape.
  #
  # There is no ceiling here on purpose. A masked value is not a quantity to keep
  # under control; it is a claim written so that nothing can contradict it, and
  # the only two honest ways out are to write it so it CAN be checked
  # (`# => 71  (a gloss)`, two spaces, or parentheses) or to write prose that
  # does not open with a value.
  it 'declares no value in a shape that cannot be checked' do
    masked = (DocExamples.extract + DocExamples.extract_markdown).flat_map do |example|
      DocExamples.statements(example.code).filter_map do |source, declared|
        next unless declared

        value = DocExamples.value_of(declared)
        ["#{example.file}:#{example.line}", source.lines.first.to_s.strip, value] if
          DocExamples.masked_value?(value)
      end
    end

    detail = masked.map { |where, source, value| "  #{where}\n    #{source}\n    # => #{value}" }.join("\n")

    expect(masked).to be_empty,
                      "#{masked.size} declared outputs begin as a value and cannot be read as one, " \
                      "so they are filed as prose and verified by nobody:\n\n#{detail}"
  end

  it 'verifies as much of the prose documentation as it used to' do
    verified = @doc_checks.count { |_, check, _| check.status == :ok }

    expect(verified).to be >= DOCS_VERIFIED_FLOOR,
                        "Only #{verified} claims in docs/ are verified, down from " \
                        "#{DOCS_VERIFIED_FLOOR}. Run `bundle exec ruby tools/doc-examples.rb --docs -v`."

    expect(verified).to eq(DOCS_VERIFIED_FLOOR),
                        "docs/ now verifies #{verified} claims. Raise DOCS_VERIFIED_FLOOR to it."
  end

  it 'does not break more of the prose documentation that claims something' do
    broken = @doc_checks.count do |_, check, claims|
      claims && %i[error timeout external].include?(check.status)
    end

    detail = @doc_checks.select { |_, check, claims| claims && check.status == :error }
                        .first(8)
                        .collect { |example, check, _| "  #{File.basename(example.file)}  #{check.actual[0, 70]}" }
                        .join("\n")

    expect(broken).to be <= DOCS_BROKEN_CEILING,
                      "#{broken} blocks in docs/ declare an output and do not run, above the " \
                      "ceiling of #{DOCS_BROKEN_CEILING}.\n\n#{detail}"

    expect(broken).to be >= DOCS_BROKEN_CEILING,
                      "Only #{broken} broken blocks left in docs/. Lower DOCS_BROKEN_CEILING to it."
  end

  it 'does not leave more documentation specs unmigrated than it used to' do
    remaining = Dir.glob(File.expand_path('{inline_doc_*,docs_*}_spec.rb', __dir__)).sum do |path|
      File.readlines(path).count { |line| line.match?(/^\s*it\s+['"]/) }
    end

    expect(remaining).to be <= UNMIGRATED_DOC_SPECS,
                         "#{remaining} examples still transcribe documentation, above the " \
                         "#{UNMIGRATED_DOC_SPECS} already known. They are not new tests: they " \
                         'are a mechanism the doctest replaced.'

    expect(remaining).to be >= UNMIGRATED_DOC_SPECS,
                         "Only #{remaining} left to migrate. Lower UNMIGRATED_DOC_SPECS to it."
  end

  it 'does not verify less than it used to' do
    verified = tally(:ok)

    expect(verified).to be >= VERIFIED_FLOOR,
                        "Only #{verified} declared outputs are verified, down from #{VERIFIED_FLOOR}. " \
                        'Examples have stopped running, or their outputs stopped being declared.'
  end

  it 'does not leave more examples unrunnable than it used to' do
    unrunnable = tally(:error) + tally(:timeout) + tally(:external)

    expect(unrunnable).to be <= UNRUNNABLE_CEILING,
                          "#{unrunnable} examples cannot run, above the ceiling of " \
                          "#{UNRUNNABLE_CEILING}. Run `bundle exec ruby tools/doc-examples.rb -v` " \
                          'to see them.'

    # A ratchet that is never tightened stops catching anything: it would sit
    # above the real number and let that many regressions through unnoticed.
    expect(unrunnable).to be >= UNRUNNABLE_CEILING,
                          "Only #{unrunnable} examples cannot run, below the ceiling of " \
                          "#{UNRUNNABLE_CEILING}. Lower UNRUNNABLE_CEILING to #{unrunnable} " \
                          'so it keeps catching the next one.'
  end
end
