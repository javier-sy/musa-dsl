require 'spec_helper'

require 'musa-dsl'

using Musa::Extension::Matrix

RSpec.describe Musa::Matrix do
  context 'Multidim matrix processing' do
    it 'Multidim matrix to set of P' do
      m = Matrix[[0,0], [2,2], [3,4], [4,3], [5,5], [7,6], [8,5], [9,6], [10,4], [12,2], [13,3], [14,2], [14,0]]

      expect(m.to_p(0)).to eq \
        [[[0, 0], 2, [2, 2], 1, [3, 4], 1, [4, 3], 1, [5, 5], 2, [7, 6], 1,
          [8, 5], 1, [9, 6], 1, [10, 4], 2, [12, 2], 1, [13, 3], 1,
          [14, 2], 0, [14, 0]]]
    end

    it 'Multidim matrix rotated to set of P' do
      m = Matrix[[0,0], [2,2], [3,4], [4,3], [5,5], [7,6], [8,5], [9,6], [10,4], [12,2], [13,3], [14,2], [14,0]]

      a = -(Math::PI / 180) * 90
      r = Matrix[[Math.cos(a), -Math.sin(a)], [Math.sin(a), Math.cos(a)]]

      d = Matrix.rows([[6, 0]] * m.row_count)

      mr = (m * r + d).map { |v| v.round(Float::DIG - 1) }
      mr = mr.to_p(0)

      expect(mr).to eq \
        [[[0.0, 7.0], 1.0, [1.0, 5.0], 2.0, [3.0, 4.0]],
         [[0.0, 7.0], 1.0, [1.0, 8.0]],
         [[0.0, 9.0], 1.0, [1.0, 8.0]],
         [[0.0, 9.0], 2.0, [2.0, 10.0], 2.0, [4.0, 12.0]],
         [[2.0, 3.0], 2.0, [4.0, 2.0], 2.0, [6.0, 0.0]],
         [[2.0, 3.0], 1.0, [3.0, 4.0]],
         [[3.0, 13.0], 1.0, [4.0, 12.0]],
         [[3.0, 13.0], 1.0, [4.0, 14.0], 2.0, [6.0, 14.0]]]
    end

    it 'Multidim matrix set of 2 condensing begin-end' do

      mm = [ Matrix[[0,0], [2,2], [3,4], [4,3]],
             Matrix[[3,1], [2,3], [1,2], [0,0]] ].condensed_matrices

      expect(mm.collect(&:to_a)).to eq [[[3, 1], [2, 3], [1, 2], [0, 0], [2, 2], [3, 4], [4, 3]]]

      expect(mm.to_p(0)).to eq \
        [[[[0, 0], 1, [1, 2], 1, [2, 3], 1, [3, 1]],
          [[0, 0], 2, [2, 2], 1, [3, 4], 1, [4, 3]]]]
    end

    it 'Multidim matrix set of 2 condensing begin-begin' do

      mm = [ Matrix[[0,0], [2,2], [3,4], [4,3]],
             Matrix[[0,0], [3,1], [2,3], [1,2]] ].condensed_matrices

      expect(mm.collect(&:to_a)).to eq [[[1, 2], [2, 3], [3, 1], [0, 0], [2, 2], [3, 4], [4, 3]]]

      expect(mm.to_p(0)).to eq \
        [[[[0, 0], 3, [3, 1]],
          [[0, 0], 2, [2, 2], 1, [3, 4], 1, [4, 3]],
          [[1, 2], 1, [2, 3], 1, [3, 1]]]]
    end

    it 'Multidim matrix set of 2 condensing end-begin' do

      mm = [ Matrix[[0,0], [2,2], [3,4], [4,3]],
             Matrix[[4,3], [3,1], [2,3], [1,2]] ].condensed_matrices

      expect(mm.collect(&:to_a)).to eq [[[0, 0], [2, 2], [3, 4], [4, 3], [3, 1], [2, 3], [1, 2]]]

      expect(mm.to_p(0)).to eq \
        [[[[0, 0], 2, [2, 2], 1, [3, 4], 1, [4, 3]],
          [[1, 2], 1, [2, 3], 1, [3, 1], 1, [4, 3]]]]

    end

    it 'Multidim matrix set of 2 condensing end-end' do

      mm = [ Matrix[[0,0], [2,2], [3,4], [4,3]],
             Matrix[[1,1], [3,1], [2,3], [4,3]] ].condensed_matrices

      expect(mm.collect(&:to_a)).to eq [[[0, 0], [2, 2], [3, 4], [4, 3], [2, 3], [3, 1], [1, 1]]]

      expect(mm.to_p(0)).to eq \
        [[[[0, 0], 2, [2, 2], 1, [3, 4], 1, [4, 3]],
          [[1, 1], 2, [3, 1]],
          [[2, 3], 2, [4, 3]],
          [[2, 3], 1, [3, 1]]]]
    end

    it 'Multidim matrix set of 3 condensing begin-end' do

      mm = [ Matrix[[0,0], [2,2], [3,4], [4,3]],
             Matrix[[3,1], [2,3], [1,2], [0,0]],
             Matrix[[1,9], [2,5], [0,0], [3, 1]]].condensed_matrices

      expect(mm.collect(&:to_a)).to eq [[[1, 9], [2, 5], [0, 0], [3, 1], [2, 3], [1, 2], [0, 0], [2, 2], [3, 4], [4, 3]]]
    end

    it 'Multidim matrix set of 3, 2 condensing begin-end, 1 standalone' do

      mm = [ Matrix[[0,0], [2,2], [3,4], [4,3]],
             Matrix[[3,1], [2,3], [1,2], [0,0]],
             Matrix[[1,9], [2,5], [0,0], [3, 2]]].condensed_matrices

      expect(mm.collect(&:to_a)).to eq \
        [[[3, 1], [2, 3], [1, 2], [0, 0], [2, 2], [3, 4], [4, 3]],
         [[1, 9], [2, 5], [0, 0], [3, 2]]]
    end
  end
end
