require 'musa-dsl/core-ext'

require 'musa-dsl/series'
require 'musa-dsl/neuma'
require 'musa-dsl/datasets'

require 'musa-dsl/neumalang'

require 'musa-dsl/transport'
require 'musa-dsl/sequencer'
require 'musa-dsl/repl'

require 'musa-dsl/midi'

require 'musa-dsl/music'

require 'musa-dsl/generative'

module Musa
  VERSION = '0.15.2'

  module All
    include Musa::Clock
    include Musa::Transport
    include Musa::Sequencer

    include Musa::Scales
    include Musa::Chords
    include Musa::Neumalang
    include Musa::Datasets

    include Musa::Series

    include Musa::Darwin
    include Musa::Markov
    include Musa::Rules
    include Musa::Variatio

    include Musa::MIDIRecorder
    include Musa::MIDIVoices

    include Musa::REPL
  end
end
