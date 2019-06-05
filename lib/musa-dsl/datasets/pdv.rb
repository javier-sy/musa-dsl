require 'musa-dsl/neuma'

module Musa::Datasets
  module PDV
    include Musa::Neumalang::Dataset

    NaturalKeys = [:pitch, :duration, :velocity].freeze

    attr_accessor :base_duration

    def to_gdv(scale)
      r = {}.extend Musa::Datasets::GDV
      r.base_duration = @base_duration

      if self[:pitch]
        if self[:pitch] == :silence
          r[:grade] = :silence
        else
          note = scale.note_of_pitch(self[:pitch], allow_chromatic: true)

          if background_note = note.background_note
            r[:grade] = background_note.grade
            r[:octave] = background_note.octave
            r[:sharps] = note.background_sharps
          else
            r[:grade] = note.grade
            r[:octave] = note.octave
          end
        end
      end

      r[:duration] = self[:duration] if self[:duration]

      if self[:velocity]
        # ppp = 16 ... fff = 127
        r[:velocity] = [0..16, 17..32, 33..48, 49..64, 65..80, 81..96, 97..112, 113..127].index { |r| r.cover? self[:velocity] } - 3
      end

      (keys - NaturalKeys).each { |k| r[k] = self[k] }

      r
    end
  end
end
