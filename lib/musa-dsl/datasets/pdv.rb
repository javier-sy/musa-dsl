require_relative 'e'
require_relative 'gdv'

require_relative 'helper'

module Musa::Datasets
  module PDV
    include AbsD

    include Helper

    NaturalKeys = (NaturalKeys + [:pitch, :velocity]).freeze

    attr_accessor :base_duration

    def to_gdv(scale)
      gdv = {}.extend GDV
      gdv.base_duration = @base_duration

      if self[:pitch]
        if self[:pitch] == :silence
          gdv[:grade] = :silence
        else
          note = scale.note_of_pitch(self[:pitch], allow_chromatic: true)

          if background_note = note.background_note
            gdv[:grade] = background_note.grade
            gdv[:octave] = background_note.octave
            gdv[:sharps] = note.background_sharps
          else
            gdv[:grade] = note.grade
            gdv[:octave] = note.octave
          end
        end
      end

      gdv[:duration] = self[:duration] if self[:duration]

      if self[:velocity]
        # ppp = 16 ... fff = 127
        # TODO create a customizable MIDI velocity to score dynamics bidirectional conversor
        gdv[:velocity] = [1..1, 2..8, 9..16, 17..33, 34..49, 49..64, 65..80, 81..96, 97..112, 113..127].index { |r| r.cover? self[:velocity] } - 5
      end

      (keys - NaturalKeys).each { |k| gdv[k] = self[k] }

      gdv
    end
  end
end
