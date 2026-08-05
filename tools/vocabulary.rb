# Keeps the conceptual documentation and the public API in correspondence, and
# writes that correspondence out as `docs/vocabulary.md`.
#
# WHY THIS EXISTS. Knowing what a method does is a lookup; knowing that it exists
# at all is not. A reader -- or an assistant -- who has never heard of `HC` or
# `play_timed` cannot ask about them, and no amount of good reference material
# fixes that: you cannot look up a word you do not have. What is missing is the
# vocabulary itself, on one page.
#
# The trap is that CURATING such a page is authorial work, and an authored
# summary of something else is exactly the layer that drifts (see
# tools/doc-examples.rb). So nothing here is curated: the selection was already
# made, by the thirteen subsystem documents, when they decided what was worth
# naming. This tool only reads that decision back.
#
# HOW. Two sets, both already verified by other means:
#
#   published    what YARD emits under this project's own `.yardopts` -- the same
#                set rubydoc shows, held to its signatures by the suite. Note that
#                `--no-private` filters the `@private` tag and private visibility,
#                and does NOT filter `@api private`: that tag is an annotation
#                here, not a publication rule, and 105 names the documents teach
#                carry it. Reported below, because a guide that teaches what the
#                source calls private is a disagreement even when it is inert.
#   named        every identifier the subsystem documents mention, whose prose
#                and examples tools/doc-examples.rb executes
#
# Their INTERSECTION is the vocabulary. Their two differences are a lint that is
# worth having on its own:
#
#   named but not public    the documentation is describing something that is not
#                           there -- an invented method, or one that was removed
#                           and left behind. This is not hypothetical: a pass over
#                           core-extensions.md found most of an API invented.
#
#   public but never named  a gap: something the framework offers and no
#                           conceptual document mentions, so nobody arrives at it
#                           except by reading the source.
#
# Two entries in that first report are known and benign: `add_item` is the name a
# macro GENERATES, described rather than called, and `d(n)` belongs to a demo. A
# third entry is a signal.
#
# Neither difference fails the build by itself -- a framework is allowed to have
# more surface than its guides cover, and prose legitimately mentions names from
# Ruby and from other gems. They are reported, and the spec asserts only that the
# generated file is current.
#
#   ruby tools/vocabulary.rb            # rewrite docs/vocabulary.md, report
#   ruby tools/vocabulary.rb --check    # fail if it would change (used by the spec)
#   ruby tools/vocabulary.rb --gaps     # also list what no document names

require 'yard'
require 'pathname'

module Musa
  module Tools
    class Vocabulary
      ROOT = Pathname.new(File.expand_path('..', __dir__))
      SUBSYSTEMS = ROOT / 'docs' / 'subsystems'
      TARGET = ROOT / 'docs' / 'vocabulary.md'

      # A backticked span is the only place a document names something on
      # purpose. Prose that says "the sequencer" is talking; `play_timed` is
      # naming.
      SPAN = /`([^`\n]+)`/

      # Inside a span, what looks like something you could write: a constant, a
      # method, a method with a receiver. Punctuation, arguments and the rest of
      # the expression are dropped -- `Scales.et12[440.0].major[60]` names
      # `Scales`, `et12`, `major`.
      TOKEN = /[A-Za-z_][A-Za-z0-9_]*[?!]?/

      # Words that appear in spans constantly and are not this framework's
      # vocabulary. Ruby's own, and the handful of foreign names the documents
      # legitimately mention.
      FOREIGN = %w[
        def end do if else elsif unless while until case when then return next break yield
        class module self nil true false and or not in for begin rescue ensure raise
        require require_relative include extend using attr_reader attr_writer attr_accessor
        lambda proc new call each map collect select reject to_a to_s to_i to_h inspect puts
        Array Hash String Symbol Integer Float Rational Range Proc Thread Mutex Comparable
        Enumerable Struct Set Math Random Time Kernel Object Module Class Exception
        StandardError ArgumentError TypeError NameError NoMethodError ThreadError RuntimeError
        MIDICommunications MIDIEvents Nokogiri YARD RSpec trap sleep rand srand loop
        Musa clone dup is_a? keys p
      ].to_set

      def initialize
        YARD::Registry.clear
        YARD.parse(Dir[(ROOT / 'lib' / '**' / '*.rb').to_s], [], YARD::Logger::ERROR)
      end

      # Everything this project publishes: public visibility, not tagged
      # `@private`, not one of the `_`-prefixed internals. Deliberately NOT
      # filtered by `@api private` -- see the note at the top of this file.
      def published
        @published ||= YARD::Registry.all(:method, :class, :module, :constant).select do |o|
          o.visibility == :public &&
            !o.tag(:private) &&
            !o.name.to_s.start_with?('_')
        end
      end

      def published_names
        @published_names ||= published.collect { |o| o.name.to_s }.to_set
      end

      # Taught by a document and annotated `@api private` in every place it is
      # defined. Inert today and a disagreement all the same.
      def taught_but_annotated_private
        all_named = named_by_document.values.flatten.to_set

        YARD::Registry.all(:method, :class, :module, :constant)
                      .group_by { |o| o.name.to_s }
                      .select { |name, objects| all_named.include?(name) && objects.all? { |o| o.tag(:api)&.text == 'private' } }
                      .keys.sort
      end

      # What each subsystem document names, in the order the document names it.
      def named_by_document
        @named_by_document ||= Dir[(SUBSYSTEMS / '*.md').to_s].sort.to_h do |path|
          text = File.read(path)
          names = text.scan(SPAN).flatten
                      .flat_map { |span| span.scan(TOKEN) }
                      .reject { |name| FOREIGN.include?(name) }
                      .uniq
          [Pathname.new(path).basename('.md').to_s, names]
        end
      end

      def vocabulary
        @vocabulary ||= named_by_document.transform_values do |names|
          names.select { |name| published_names.include?(name) }.sort
        end
      end

      # Named as if it were API and not found in the public API. Only spans that
      # commit to being a call are reported -- `foo(`, `.foo` -- because a bare
      # word inside backticks is as likely to be a value, a file or an English
      # word as a method.
      def named_but_absent
        Dir[(SUBSYSTEMS / '*.md').to_s].sort.to_h do |path|
          spans = File.read(path).scan(SPAN).flatten
          suspects = spans.flat_map { |span| span.scan(/(?:\.|\b)([a-z_][a-z0-9_]*[?!]?)\s*\(/) }
                          .flatten
                          .reject { |name| FOREIGN.include?(name) }
                          .reject { |name| published_names.include?(name) }
                          .uniq
          [Pathname.new(path).basename('.md').to_s, suspects]
        end.reject { |_, suspects| suspects.empty? }
      end

      def never_named
        all_named = named_by_document.values.flatten.to_set
        published.reject { |o| all_named.include?(o.name.to_s) }
                  .collect { |o| "#{o.type} #{o.path}" }
                  .sort
      end

      def render
        lines = []
        lines << '# Vocabulary'
        lines << ''
        lines << 'Every name the subsystem documents teach, by subsystem. It answers *what is'
        lines << 'there*, which is the question you cannot look up -- for what each one does,'
        lines << 'follow the document, or the API reference at'
        lines << '[rubydoc](https://www.rubydoc.info/gems/musa-dsl).'
        lines << ''
        lines << 'Generated by `tools/vocabulary.rb` from the public API and the documents'
        lines << 'themselves; the suite fails if it is out of date. A name missing here is'
        lines << 'missing from the documents, and that is where to add it.'
        lines << ''

        vocabulary.each do |document, names|
          next if names.empty?

          lines << "## #{document}"
          lines << ''
          lines << names.collect { |name| "`#{name}`" }.join(' · ')
          lines << ''
        end

        lines.join("\n")
      end

      def report(gaps: false)
        total = vocabulary.values.flatten.uniq.size
        puts "#{total} names taught across #{vocabulary.count { |_, n| n.any? }} subsystem documents"
        puts "#{published.size} published, so #{published.size - total} are never named by a document"

        absent = named_but_absent
        if absent.any?
          puts
          puts 'NAMED AS A CALL AND NOT PUBLISHED'
          puts '  (an invented method, one that was removed, or a call into another gem)'
          absent.each { |document, names| puts "  #{document}: #{names.join(', ')}" }
        end

        annotated = taught_but_annotated_private
        if annotated.any?
          puts
          puts "TAUGHT BY A DOCUMENT AND ANNOTATED `@api private` EVERYWHERE: #{annotated.size}"
          puts '  Inert under this .yardopts, which does not filter on that tag, so rubydoc'
          puts '  shows them. A disagreement between the guides and the source all the same.'
          puts "  #{annotated.join(' ')}"
        end

        return unless gaps

        puts
        puts 'IN THE PUBLIC API AND NAMED BY NO DOCUMENT'
        never_named.each { |entry| puts "  #{entry}" }
      end
    end
  end
end

if $PROGRAM_NAME == __FILE__
  require 'set'

  vocabulary = Musa::Tools::Vocabulary.new
  rendered = vocabulary.render

  if ARGV.delete('--check')
    current = File.exist?(Musa::Tools::Vocabulary::TARGET) ? File.read(Musa::Tools::Vocabulary::TARGET) : nil

    if current == rendered
      puts 'docs/vocabulary.md is current'
      exit 0
    end

    warn 'docs/vocabulary.md is out of date. Run `ruby tools/vocabulary.rb`.'
    exit 1
  end

  File.write(Musa::Tools::Vocabulary::TARGET, rendered)
  vocabulary.report(gaps: ARGV.delete('--gaps'))
end
