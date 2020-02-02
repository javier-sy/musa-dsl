require_relative 'musa-dsl/core-ext'

require_relative 'musa-dsl/series'
require_relative 'musa-dsl/dataset'

require_relative 'musa-dsl/neumalang'
require_relative 'musa-dsl/neumas'

require_relative 'musa-dsl/transport'
require_relative 'musa-dsl/sequencer'
require_relative 'musa-dsl/repl'

require_relative 'musa-dsl/midi'
require_relative 'musa-dsl/musicxml'

require_relative 'musa-dsl/music'

require_relative 'musa-dsl/generative'

module Musa
  VERSION = '0.15.2'

  module All
    include Musa::Clock
    include Musa::Transport
    include Musa::Sequencer

    include Musa::Scales
    include Musa::Chords
    include Musa::Dataset

    include Musa::Neumalang
    include Musa::Neumas

    include Musa::Series

    include Musa::Darwin
    include Musa::Markov
    include Musa::Rules
    include Musa::Variatio

    include Musa::MIDIRecorder
    include Musa::MIDIVoices

    include Musa::MusicXML

    include Musa::REPL
  end
end
