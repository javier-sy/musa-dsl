# Boundary behaviour of the matrix subsystem.
#
# WHY THIS FILE EXISTS. `spec/matrix_spec.rb` is the original spec and covers
# what the subsystem is for: the four ways two matrices can share a boundary,
# three-matrix condensing, keep_time, and a 3D bugfix. What it does not cover --
# and what an `@example` cannot show without ceasing to teach -- is the edges: a
# matrix with no rows, one with no dimension left after dropping time, times
# that run backwards or repeat, durations of zero.
#
# These came out of `spec/inline_doc_matrix_spec.rb` when it was audited. The
# rest of that file either transcribed an example -- now declared in
# `lib/musa-dsl/matrix/matrix.rb` and verified there by tools/doc-examples.rb --
# or was a "documentation consistency check", which is a spec asserting that a
# document says what it says. That is the doctest's job, and it does it by
# running the document rather than by restating it.

require 'spec_helper'
require 'musa-dsl'

using Musa::Extension::Matrix

RSpec.describe 'Matrix: boundaries and degenerate cases' do
  include Musa::All

  it 'handles empty matrix' do
    matrix = Matrix.empty(0, 2)
    result = matrix.to_p(time_dimension: 0)
  
    expect(result).to eq []
  end

  it 'handles single column matrix' do
    # Just time, no other parameters
    matrix = Matrix[[0], [1], [2]]
    result = matrix.to_p(time_dimension: 0, keep_time: false)
  
    # Degenerate, and worth knowing: dropping the only dimension leaves the
    # durations with nothing to carry. The deltas are right, the values empty.
    expect(result).to eq [[[], 1, [], 1, []]]
  end

  it 'handles large time gaps' do
    # Very large durations
    matrix = Matrix[[0, 60], [1000, 62]]
    result = matrix.to_p(time_dimension: 0)
  
    expect(result.size).to eq(1)
    expect(result[0][1]).to eq(1000)  # Large duration
  end

  it 'handles negative time values' do
    # Time can be negative (relative to some reference)
    matrix = Matrix[[-2, 60], [-1, 62], [0, 64]]
    result = matrix.to_p(time_dimension: 0)
  
    # Only the differences matter, so where the origin sits does not.
    expect(result).to eq [[[60], 1, [62], 1, [64]]]
  end

  it 'handles zero duration intervals' do
    # Simultaneous events
    matrix = Matrix[[0, 60], [0, 62], [0, 64]]
    result = matrix.to_p(time_dimension: 0)
  
    # A chord: three values, no time between them.
    expect(result).to eq [[[60], 0, [62], 0, [64]]]
  end

  it 'handles fractional/rational time values' do
    # Musical time in rationals
    matrix = Matrix[[0r, 60], [Rational(1,4), 62], [Rational(1,2), 64]]
    result = matrix.to_p(time_dimension: 0)
  
    # Exact, not 0.25: nothing along the way turns the rationals into floats.
    expect(result).to eq [[[60], 1/4r, [62], 1/4r, [64]]]
    expect(result[0][1]).to be_a Rational
  end

  it 'handles duplicate time values' do
    # Multiple events at same time
    matrix = Matrix[[0, 10], [0, 20], [1, 30]]
    result = matrix.to_p(time_dimension: 0)
  
    # Simultaneity is a zero delta, not a dropped row.
    expect(result).to eq [[[10], 0, [20], 1, [30]]]
  end

  it 'handles time dimension other than 0' do
    # Time in second column: [pitch, time]
    matrix = Matrix[[60, 0], [62, 1], [64, 2]]
    result = matrix.to_p(time_dimension: 1)
  
    expect(result).to eq [[[60], 1, [62], 1, [64]]]
  end

  it 'handles matrices with different parameter counts' do
    # Simple 2D: [time, pitch]
    simple = Matrix[[0, 60], [1, 62]]
    simple_result = simple.to_p(time_dimension: 0)
  
    # Complex 4D: [time, pitch, velocity, pan]
    complex = Matrix[[0, 60, 100, 0.5], [1, 62, 110, 0.6]]
    complex_result = complex.to_p(time_dimension: 0)
  
    expect(simple_result[0][0].size).to eq(1)  # Just [pitch]
    expect(complex_result[0][0].size).to eq(3)  # [pitch, velocity, pan]
  end

  it 'preserves V module extension on all values' do
    matrix = Matrix[[0, 60], [1, 62], [2, 64]]
    result = matrix.to_p(time_dimension: 0)
  
    first_p = result[0]
  
    expect(first_p).to eq [[60], 1, [62], 1, [64]]
  
    # Every value carries V; the deltas between them do not.
    (0...first_p.size).step(2) { |i| expect(first_p[i]).to be_kind_of(Musa::Datasets::V) }
    (1...first_p.size).step(2) { |i| expect(first_p[i]).not_to be_kind_of(Musa::Datasets::V) }
  end

  it 'preserves P module extension on result' do
    matrix = Matrix[[0, 60], [1, 62]]
    result = matrix.to_p(time_dimension: 0)
  
    expect(result).to eq [[[60], 1, [62]]]
  
    # The segments carry P; the array holding them does not.
    expect(result).not_to be_kind_of(Musa::Datasets::P)
    result.each { |p| expect(p).to be_kind_of(Musa::Datasets::P) }
  end

  it 'handles empty array' do
    result = [].indexes_of_values
  
    expect(result).to eq({})
  end

  it 'handles empty array' do
    result = [].condensed_matrices
  
    expect(result).to eq([])
  end

  it 'handles single matrix' do
    a = Matrix[[0, 60], [1, 62]]
    result = [a].condensed_matrices
  
    expect(result.size).to eq(1)
    expect(result[0].to_a).to eq([[0, 60], [1, 62]])
  end

  it 'handles single row matrix' do
    matrix = Matrix[[0, 60]]
    result = matrix.to_p(time_dimension: 0)
  
    # Nothing: a segment needs two points to have a direction, and `decompose`
    # keeps only runs of more than one row. A lone point is not a gesture.
    expect(result).to eq []
  end

  it 'handles monotonic increasing sequence' do
    # Simple forward progression
    matrix = Matrix[[0, 10], [1, 20], [2, 30], [3, 40]]
    result = matrix.to_p(time_dimension: 0)
  
    # One continuous segment
    expect(result).to eq [[[10], 1, [20], 1, [30], 1, [40]]]
  end

  it 'handles monotonic decreasing sequence' do
    # Backward time progression
    matrix = Matrix[[3, 40], [2, 30], [1, 20], [0, 10]]
    result = matrix.to_p(time_dimension: 0)
  
    # The rows are in descending time and come back as ONE segment in
    # ascending time: `decompose` starts from the lowest time value and scans
    # in both index directions, so a matrix written backwards is a gesture
    # read forwards, not a reversed one.
    expect(result).to eq [[[10], 1, [20], 1, [30], 1, [40]]]
  end
end
