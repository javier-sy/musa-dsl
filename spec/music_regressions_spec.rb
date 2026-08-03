# Behaviours of the music subsystem that its documentation cannot declare.
#
# WHY THIS FILE EXISTS. `spec/scales_spec.rb` and `spec/chords_spec.rb` are the
# original specs, written during development; they are not touched. What lands
# here is what came out of `spec/inline_doc_music_spec.rb` when it was audited
# and turned out not to be documentation at all:
#
#   * regressions anchored to an issue, which say "this must not come back" --
#     a claim about the project's history that no example can make;
#
#   * property sweeps, where the point is the RANGE of inputs. An example
#     teaches with one case; "ties always break downwards" is five cases, and
#     writing five into a document would bury the lesson under the evidence.
#
# Everything else that file held is now declared in the documentation itself and
# verified there by `tools/doc-examples.rb`.

require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Music: regressions and properties' do
  include Musa::All

  let(:c_major) { Musa::Scales::Scales.et12[440.0].major[60] }

  context 'regressions' do
    # They carried `@api private` while being public Ruby methods, which is the
    # worst of both: readers avoided them, or reached them through `send`.
    # wide_grade is not even arguably internal -- GDV and GDVd are written in
    # terms of it -- and the other two are the only way to read grade notation
    # without a scale deciding for you. Pinned so a later `private` is a
    # decision and not a slip.
    it 'keeps grade_of, parse_grade and wide_grade public (issue #68)' do
      expect(c_major.public_methods).to include(:grade_of, :parse_grade)
      expect(c_major.tonic.public_methods).to include(:wide_grade)
    end

    # The no-scale branch asked the tuning for a scale kind called 60 --
    # `tuning[pitch].major` where the library's idiom is `tuning.major[pitch]`,
    # the kind first and the pitch rooting it. It is the only route the @param
    # documents and the only one no example or spec exercised.
    it 'builds a chord on a bare pitch, with no scale in hand (issue #71)' do
      expect(Musa::Chords::Chord.with_root(60, quality: :major, size: :triad).pitches)
        .to eq [60, 64, 67]

      # Re-rooting anywhere is the point: this is what a neo-Riemannian operator
      # needs, and it has no scale to offer.
      expect(Musa::Chords::Chord.with_root(63, quality: :major, size: :triad).pitches)
        .to eq [63, 67, 70]
    end
  end

  context 'properties' do
    # The documentation declares one case of `allow_nearest:` -- 63 resolves to
    # 62 -- and says ties break downwards. Downwards is a claim about every tie
    # there is, and a single example cannot make it.
    it 'breaks every allow_nearest tie downwards' do
      nearest = [61, 63, 66, 68, 70].map { |p| c_major.note_of_pitch(p, allow_nearest: true).pitch }

      expect(nearest).to eq [60, 62, 65, 67, 69]
    end

    # Registering a definition and reading it back is a round trip through
    # global state, which is why it is here and not in an example: an example
    # that registers a chord leaves it registered for whoever runs next.
    it 'registers a chord definition and finds it again' do
      Musa::Chords::ChordDefinition.register :maj_test,
                                             quality: :major, size: :triad,
                                             offsets: { root: 0, third: 4, fifth: 7 }

      definition = Musa::Chords::ChordDefinition[:maj_test]

      expect(definition.name).to eq :maj_test
      expect(definition.features).to eq(quality: :major, size: :triad)
      expect(definition.pitches(60)).to eq [60, 64, 67]
    end

    it 'registers a dominant seventh and finds it again' do
      Musa::Chords::ChordDefinition.register :dom7_test,
                                             quality: :dominant, size: :seventh,
                                             offsets: { root: 0, third: 4, fifth: 7, seventh: 10 }

      definition = Musa::Chords::ChordDefinition[:dom7_test]

      expect(definition.features).to eq(quality: :dominant, size: :seventh)
      expect(definition.pitches(60)).to eq [60, 64, 67, 70]
    end

    after do
      %i[maj_test dom7_test].each do |name|
        Musa::Chords::ChordDefinition.instance_variable_get(:@definitions)&.delete(name)
      end
    end
  end
end
