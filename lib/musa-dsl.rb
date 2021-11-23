module Musa
  VERSION = '0.26.1'.freeze
end

require_relative 'musa-dsl/core-ext'

require_relative 'musa-dsl/series'
require_relative 'musa-dsl/datasets'
require_relative 'musa-dsl/matrix'

require_relative 'musa-dsl/neumalang'
require_relative 'musa-dsl/neumas'

require_relative 'musa-dsl/logger'

require_relative 'musa-dsl/transport'
require_relative 'musa-dsl/sequencer'
require_relative 'musa-dsl/repl'

require_relative 'musa-dsl/midi'
require_relative 'musa-dsl/musicxml'

require_relative 'musa-dsl/transcription'

require_relative 'musa-dsl/music'

require_relative 'musa-dsl/generative'

module Musa::All
  # Core
  #
  include Musa::Logger

  include Musa::Clock
  include Musa::Transport
  include Musa::Sequencer

  include Musa::Series
  include Musa::Datasets

  include Musa::Neumalang
  include Musa::Neumas

  include Musa::Transcription

  include Musa::REPL

  # Extensions: ojo, el nombre extensions ya se usa para algunos paquetes de core-ext que funcionan con Refinements
  #
  include Musa::Scales
  include Musa::Chords

  include Musa::Matrix

  include Musa::Darwin
  include Musa::Markov
  include Musa::Backboner
  include Musa::Variatio

  include Musa::MIDIRecorder
  include Musa::MIDIVoices

  include Musa::MusicXML

  include Musa::Transcriptors
end
