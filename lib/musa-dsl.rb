module Musa
  VERSION = '0.18.0'
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
  include Musa::Logger

  include Musa::Clock
  include Musa::Transport
  include Musa::Sequencer

  include Musa::Scales
  include Musa::Chords
  include Musa::Datasets

  include Musa::Neumalang
  include Musa::Neumas
  include Musa::Matrix

  include Musa::Series

  include Musa::Darwin
  include Musa::Markov
  include Musa::Backboner
  include Musa::Variatio

  include Musa::MIDIRecorder
  include Musa::MIDIVoices

  include Musa::MusicXML

  include Musa::Transcription
  include Musa::Transcriptors

  include Musa::REPL
end
