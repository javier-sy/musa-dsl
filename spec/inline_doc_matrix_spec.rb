require 'spec_helper'
require 'musa-dsl'

RSpec.describe 'Matrix Inline Documentation Examples' do
  include Musa::All
  using Musa::Extension::Matrix

  context 'Musa::Extension::Matrix module documentation' do
    it '@example Basic matrix conversion' do
      # Matrix: [time, pitch]
      matrix = Matrix[[0, 60], [1, 62], [2, 64]]
      p_sequences = matrix.to_p(time_dimension: 0)

      # Returns an array with one P:
      #   [[60], 1, [62], 1, [64]].extend(P)
      # Where [60], [62], [64] are arrays extended with V module

      expect(p_sequences).to be_an(Array)
      expect(p_sequences.size).to eq(1)

      first_p = p_sequences[0]
      expect(first_p).to be_a(Array)
      expect(first_p).to be_kind_of(Musa::Datasets::P)

      # Check structure: [value1, duration1, value2, duration2, value3]
      expect(first_p.size).to eq(5)
      expect(first_p[0]).to eq([60])
      expect(first_p[0]).to be_kind_of(Musa::Datasets::V)
      expect(first_p[1]).to eq(1)
      expect(first_p[2]).to eq([62])
      expect(first_p[2]).to be_kind_of(Musa::Datasets::V)
      expect(first_p[3]).to eq(1)
      expect(first_p[4]).to eq([64])
      expect(first_p[4]).to be_kind_of(Musa::Datasets::V)
    end

    it '@example Multi-dimensional musical parameters' do
      # Matrix: [time, pitch, velocity]
      matrix = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
      p_sequences = matrix.to_p(time_dimension: 0, keep_time: false)

      # Returns an array with one P:
      #   [[60, 100], 0.5, [62, 110], 0.5, [64, 120]].extend(P)
      # Time dimension removed, used only for duration calculation

      expect(p_sequences).to be_an(Array)
      expect(p_sequences.size).to eq(1)

      first_p = p_sequences[0]
      expect(first_p).to be_kind_of(Musa::Datasets::P)

      # Check structure: [value1, duration1, value2, duration2, value3]
      expect(first_p.size).to eq(5)
      expect(first_p[0]).to eq([60, 100])
      expect(first_p[0]).to be_kind_of(Musa::Datasets::V)
      expect(first_p[1]).to eq(0.5)
      expect(first_p[2]).to eq([62, 110])
      expect(first_p[2]).to be_kind_of(Musa::Datasets::V)
      expect(first_p[3]).to eq(0.5)
      expect(first_p[4]).to eq([64, 120])
      expect(first_p[4]).to be_kind_of(Musa::Datasets::V)
    end

    it '@example Condensing connected matrices' do
      # Two phrases that connect at [1, 62]
      phrase1 = Matrix[[0, 60], [1, 62]]
      phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]

      result = [phrase1, phrase2].to_p(time_dimension: 0)

      # Returns an array with one P (merged):
      #   [[60], 1, [62], 1, [64], 1, [65]].extend(P)
      # Both phrases merged into one continuous sequence

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)

      # Result is an array containing a P object
      first_element = result[0]
      expect(first_element).to be_an(Array)

      # The first element itself is the P sequence
      expect(first_element).to eq([[[60], 1, [62], 1, [64], 1, [65]]])
    end
  end

  context 'Array#indexes_of_values (line 98)' do

    it 'handles single occurrences' do
      result = [1, 2, 3].indexes_of_values

      expect(result).to eq({ 1 => [0], 2 => [1], 3 => [2] })
    end

    it 'handles all same values' do
      result = [5, 5, 5].indexes_of_values

      expect(result).to eq({ 5 => [0, 1, 2] })
    end

    it 'handles empty array' do
      result = [].indexes_of_values

      expect(result).to eq({})
    end
  end

  context 'Array#to_p (line 123)' do
    it 'converts array of matrices with time dimension' do
      matrices = [
        Matrix[[0, 60], [1, 62]],
        Matrix[[2, 64], [3, 65]]
      ]

      result = matrices.to_p(time_dimension: 0)

      # One entry per condensed matrix, and each entry is itself the array of P
      # that Matrix#to_p returns -- one per directional segment. So the result is
      # Array<Array<P>>, not Array<P>.
      expect(result).to eq [[[[60], 1, [62]]], [[[64], 1, [65]]]]

      expect(result.size).to eq 2
      expect(result[0]).not_to be_a Musa::Datasets::P
      expect(result[0][0]).to be_a Musa::Datasets::P
    end

    it 'supports keep_time parameter' do
      matrices = [Matrix[[0, 60, 100], [1, 62, 110]]]

      result = matrices.to_p(time_dimension: 0, keep_time: true)

      # The time stays inside each value, and is still what the delta is
      # computed from.
      expect(result).to eq [[[[0, 60, 100], 1, [1, 62, 110]]]]
    end
  end

  context 'Array#condensed_matrices (line 146)' do
    it '@example Matrices that share a boundary are merged' do
      # Matrix A ends where Matrix B begins -> they merge
      a = Matrix[[0, 60], [1, 62]]
      b = Matrix[[1, 62], [2, 64]]
      result = [a, b].condensed_matrices

      # => [Matrix[[0, 60], [1, 62], [2, 64]]]
      expect(result.size).to eq(1)
      expect(result[0].to_a).to eq([[0, 60], [1, 62], [2, 64]])
    end

    it 'handles matrices with matching first rows' do
      # Both start at same point
      a = Matrix[[1, 62], [0, 60]]
      b = Matrix[[1, 62], [2, 64]]

      result = [a, b].condensed_matrices

      expect(result.size).to eq(1)
      # Matrices should be merged
    end

    it 'handles matrices with matching last rows' do
      # A ends where B ends
      a = Matrix[[0, 60], [1, 62]]
      b = Matrix[[2, 64], [1, 62]]

      result = [a, b].condensed_matrices

      expect(result.size).to eq(1)
      # Matrices should be merged
    end

    it 'keeps separate matrices when no boundaries match' do
      a = Matrix[[0, 60], [1, 62]]
      b = Matrix[[10, 70], [11, 72]]

      result = [a, b].condensed_matrices

      expect(result.size).to eq(2)
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
  end

  context 'Matrix#to_p (line 225)' do

    it '@example Keeping time dimension' do
      matrix = Matrix[[0, 60, 100], [1, 62, 110], [2, 64, 120]]
      result = matrix.to_p(time_dimension: 0, keep_time: true)

      # => Array with one P object:
      #    [[0, 60, 100], 1, [1, 62, 110], 1, [2, 64, 120]].extend(P)
      # Time dimension kept in each value array

      expect(result).to be_an(Array)
      expect(result.size).to eq(1)

      first_p = result[0]
      expect(first_p).to be_kind_of(Musa::Datasets::P)
      expect(first_p[0]).to eq([0, 60, 100])
      expect(first_p[0]).to be_kind_of(Musa::Datasets::V)
      expect(first_p[1]).to eq(1)
      expect(first_p[2]).to eq([1, 62, 110])
      expect(first_p[4]).to eq([2, 64, 120])
    end

    it 'calculates durations correctly from time differences' do
      # Varying time intervals
      matrix = Matrix[[0, 60], [0.25, 62], [1, 64], [2.5, 65]]
      result = matrix.to_p(time_dimension: 0)

      expect(result.size).to eq(1)
      first_p = result[0]

      # Check durations: 0.25, 0.75, 1.5
      expect(first_p[1]).to eq(0.25)
      expect(first_p[3]).to eq(0.75)
      expect(first_p[5]).to eq(1.5)
    end

    it 'handles multi-parameter matrices' do
      # [time, pitch, velocity, pan]
      matrix = Matrix[[0, 60, 100, 0.5], [1, 62, 110, 0.6]]
      result = matrix.to_p(time_dimension: 0, keep_time: false)

      expect(result.size).to eq(1)
      first_p = result[0]

      # First value: [60, 100, 0.5] (time removed)
      expect(first_p[0]).to eq([60, 100, 0.5])
      expect(first_p[1]).to eq(1)
      expect(first_p[2]).to eq([62, 110, 0.6])
    end

    it 'handles single row matrix' do
      matrix = Matrix[[0, 60]]
      result = matrix.to_p(time_dimension: 0)

      # Nothing: a segment needs two points to have a direction, and `decompose`
      # keeps only runs of more than one row. A lone point is not a gesture.
      expect(result).to eq []
    end
  end

  context 'Matrix#_rows (line 258)' do
    it 'provides access to internal rows array' do
      matrix = Matrix[[0, 60], [1, 62]]

      rows = matrix._rows

      expect(rows).to be_an(Array)
      expect(rows.size).to eq(2)
      expect(rows[0].to_a).to eq([0, 60])
      expect(rows[1].to_a).to eq([1, 62])
    end

    it 'returns modifiable array for condensed_matrices' do
      matrix = Matrix[[0, 60], [1, 62]]

      rows = matrix._rows

      # Not a copy: it is the matrix's own storage, which is why condensing can
      # shift rows off it. Any Array responds to shift; what matters is that
      # shifting this one changes the matrix.
      expect(rows).to eq([[0, 60], [1, 62]])
      expect(matrix._rows).to equal(matrix._rows)

      rows.shift

      expect(matrix.to_a).to eq([[1, 62]])
    end
  end

  context 'Matrix#decompose (line 305)' do
    it 'Decomposes into directional segments' do
      # Time goes 0, 1, then back to 0.5, then 2: not monotonic, which is the
      # whole reason `decompose` exists.
      points = [[0, 10], [1, 20], [0.5, 15], [2, 30]]
      matrix = Matrix.rows(points)

      # Note: decompose is private, so we test it indirectly through to_p
      result = matrix.to_p(time_dimension: 0)

      # Three segments out of four points, and the points are SHARED between
      # them. From the valley at time 0.5 the scan goes both ways -- back to the
      # point at time 1, and on to the one at time 2 -- so [20] ends the first
      # segment and also ends the second, and [15] starts two.
      expect(result).to eq [[[10], 1, [20]],
                            [[15], 0.5, [20]],
                            [[15], 1.5, [30]]]
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
  end

  context 'Integration tests' do
    it 'handles complete workflow from matrix to sequencer format' do
      # Create a musical gesture matrix
      gesture = Matrix[
        [0, 60, 100],      # time=0, pitch=60, velocity=100
        [0.5, 62, 110],    # time=0.5, pitch=62, velocity=110
        [1.0, 64, 120],    # time=1.0, pitch=64, velocity=120
        [1.5, 65, 100]     # time=1.5, pitch=65, velocity=100
      ]

      p_sequences = gesture.to_p(time_dimension: 0, keep_time: false)

      expect(p_sequences).to be_an(Array)
      expect(p_sequences.size).to eq(1)

      first_p = p_sequences[0]
      expect(first_p).to be_kind_of(Musa::Datasets::P)

      # Verify structure
      expect(first_p[0]).to eq([60, 100])
      expect(first_p[1]).to eq(0.5)
      expect(first_p[2]).to eq([62, 110])
      expect(first_p[3]).to eq(0.5)
      expect(first_p[4]).to eq([64, 120])
      expect(first_p[5]).to eq(0.5)
      expect(first_p[6]).to eq([65, 100])
    end

    it 'merges multiple gesture fragments' do
      # Create fragmented gesture
      phrase1 = Matrix[[0, 60], [1, 62], [2, 64]]
      phrase2 = Matrix[[2, 64], [3, 65], [4, 67]]
      phrase3 = Matrix[[4, 67], [5, 69]]

      merged = [phrase1, phrase2, phrase3].to_p(time_dimension: 0)

      expect(merged).to be_an(Array)
      expect(merged.size).to eq(1)

      # Result structure is nested
      first_element = merged[0]
      expect(first_element).to be_an(Array)

      # The merged sequence should have all the notes
      # Expected: [[[60], 1, [62], 1, [64], 1, [65], 1, [67], 1, [69]]]
      expect(first_element).to be_an(Array)
      expect(first_element[0]).to be_an(Array)
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
  end

  context 'Edge cases and robustness' do
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
  end

  context 'Documentation consistency checks' do
    it 'verifies module description matches implementation' do
      # The module should refine Array and Matrix
      expect(Array.instance_methods(false)).not_to include(:to_p)

      # Only available with 'using'
      # Within this context, 'using' is active
      # The refinement should add to_p to arrays of matrices
      test_array = [Matrix[[0, 60], [1, 62]]]
      # Note: refinements work in the lexical scope where 'using' is declared
      # This test verifies the refinement is properly scoped
      expect(defined?(Musa::Extension::Matrix)).to be_truthy
    end

    it 'verifies P and V module dependencies exist' do
      expect(defined?(Musa::Datasets::P)).to be_truthy
      expect(defined?(Musa::Datasets::V)).to be_truthy
    end

    it 'verifies examples match documented behavior' do
      # From docs/subsystems/matrix.md
      melody_matrix = Matrix[[0, 60], [1, 62], [2, 64]]
      p_sequence = melody_matrix.to_p(time_dimension: 0)

      # Should match documentation: [[[60], 1, [62], 1, [64]]]
      expect(p_sequence.size).to eq(1)
      expect(p_sequence[0]).to eq([[60], 1, [62], 1, [64]])
    end

    it 'verifies multi-parameter example from documentation' do
      # From docs/subsystems/matrix.md
      gesture = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
      p_with_velocity = gesture.to_p(time_dimension: 0)

      # Should match: [[[60, 100], 0.5, [62, 110], 0.5, [64, 120]]]
      expect(p_with_velocity.size).to eq(1)
      expect(p_with_velocity[0]).to eq([[60, 100], 0.5, [62, 110], 0.5, [64, 120]])
    end

    it 'verifies condensing example from documentation' do
      # From docs/subsystems/matrix.md
      phrase1 = Matrix[[0, 60], [1, 62]]
      phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]
      merged = [phrase1, phrase2].to_p(time_dimension: 0)

      # One condensed matrix, so one entry -- and that entry is the array of P
      # that Matrix#to_p returns, which is why there are two levels here. See
      # Array#to_p's @return.
      expect(merged.size).to eq(1)
      expect(merged[0]).to eq([[[60], 1, [62], 1, [64], 1, [65]]])
    end
  end
end
