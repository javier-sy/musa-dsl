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
  VERIFIED_FLOOR = 518

  # Spec examples named `@example <title>` whose title no longer appears in the
  # documentation. At zero, and it stays there: an example that loses its
  # reference has either been renamed -- follow it -- or removed, in which case
  # the spec should stop claiming to come from one.
  ORPHANED_REFERENCES = 0

  # Examples that do not run: raise, block until killed, or need a gem this
  # project does not depend on. Counted together because which of the three a
  # given example falls into depends on the machine -- with midi-communications
  # installed but no hardware, "needs a gem" becomes "raises" -- and the sum is
  # what stays stable. MAY ONLY GO DOWN.
  UNRUNNABLE_CEILING = 10

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
