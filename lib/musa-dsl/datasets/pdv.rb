require 'musa-dsl/neuma'

module Musa::Datasets
  module PDV # pitch duration velocity
    include Musa::Neuma::Dataset

    attr_accessor :base_duration

    def to_gdv(scale)
      r = {}.extend Musa::Datasets::GDV
      r.base_duration = @base_duration

      if self[:pitch]
        if self[:pitch] == :silence
          r[:grade] = :silence
        else
          note = scale.note_of_pitch(self[:pitch])
          r[:grade] = note.grade
          r[:octave] = note.octave
        end
      end

      r[:duration] = self[:duration] if self[:duration]

      if self[:velocity]
        # ppp = 16 ... fff = 127
        r[:velocity] = [0..16, 17..32, 33..48, 49..64, 65..80, 81..96, 97..112, 113..127].index { |r| r.cover? self[:velocity] } - 3
      end

      r
    end
  end
end
