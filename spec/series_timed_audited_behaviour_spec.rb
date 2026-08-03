# Behaviours of the series subsystem that the documentation does not claim.
#
# WHY THIS FILE EXISTS, AND WHY IT IS NOT CALLED inline_doc_*. It was: a
# hand-written transcription of the `@example` blocks in `lib/`, written to
# verify them. `tools/doc-examples.rb` now runs every one of those where it is
# written and checks every output it declares, so transcribing them here was
# duplicating a mechanism -- and a transcription drifts from its original in
# silence, which is how a spec came to carry a `.extend` the document lacked.
#
# What survived the audit is what the doctest cannot do:
#
#   * a claim the documentation does not make. If the example says nothing
#     about what it produces and this file knows, the fix is to promote it: the
#     `# =>` goes in the example, the doctest takes over, and the spec goes.
#     Eight did during the audit, and promoting them found `anticipate`
#     documented with two block parameters when it takes three -- an error no
#     doctest could see, because an example that declares nothing is never
#     compared with anything;
#
#   * an output that CANNOT be declared. `.randomize` has no value to write
#     down, so what is checkable is the invariant -- same elements, different
#     order -- and asserting a property is the only possible check. These stay
#     here for good;
#
#   * behaviour reached through the documentation but never stated in it.
#
# The rule, so this does not grow back: a spec file does not transcribe
# documentation. What a spec knows and the document does not say is a
# documentation gap, not a test asset.

require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Series Timed Serie Inline Documentation Examples' do
  include Musa::All

  context 'TIMED_UNION constructor' do

  end

  context 'flatten_timed operation' do

  end

  context 'compact_timed operation' do

  end

  context 'union_timed method' do

  end
end
