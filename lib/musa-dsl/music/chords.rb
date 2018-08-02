module Musa
  class Chord
    attr_accessor :fundamental, :third, :fifth, :duplicated, :duplicate_on

    def initialize fundamental = nil
      @fundamental = fundamental
      @third = nil
      @fifth = nil
      @duplicated = nil
      @duplicate_on = nil
    end

    def soprano
      notes[3]
    end

    def alto
      notes[2]
    end

    def tenor
      notes[1]
    end

    def bass
      notes[0]
    end

    def ordered
      [bass, tenor, alto, soprano]
    end

    def to_s
      "Chord<#{@fundamental}, #{@third}, #{@fifth}, dup #{@duplicated} on #{duplicated_note}>"
    end

    alias :inspect :to_s

    private

    def notes
      [@fundamental, @third, @fifth, duplicated_note].compact.sort
    end

    def duplicated_note
      @duplicate_on + send(@duplicated) if @duplicated
    end
  end
end
