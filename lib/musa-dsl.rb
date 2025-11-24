require_relative 'musa-dsl/version'

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

# Convenience module that includes all Musa DSL components in a single namespace.
#
# This module provides a convenient way to include all Musa DSL functionality
# into your code with a single `include Musa::All` statement, rather than
# including each component individually.
#
# ## Included Components
#
# ### Core Functionality
# - {Musa::Logger} - Logging utilities
# - {Musa::Clock} - Timing and clock management
# - {Musa::Transport} - Transport control (play, stop, tempo)
# - {Musa::Sequencer} - Event sequencing and scheduling
# - {Musa::Series} - Series operations and transformations
# - {Musa::Datasets} - Musical dataset management
# - {Musa::REPL} - Read-Eval-Print Loop for live coding
#
# ### Notation and Language
# - {Musa::Neumalang} - Neuma language parser
# - {Musa::Neumas} - Neuma notation system
#
# ### Musical Theory
# - {Musa::Scales} - Scale definitions and operations
# - {Musa::Chords} - Chord construction and manipulation
#
# ### Data Structures
# - {Musa::Matrix} - Matrix operations for musical data
#
# ### Generative Algorithms
# - {Musa::Darwin} - Evolutionary/genetic algorithms
# - {Musa::Markov} - Markov chain generation
# - {Musa::Rules} - Rule-based generative system
# - {Musa::Variatio} - Combinatorial variation generator
#
# ### Input/Output
# - {Musa::MIDIRecorder} - MIDI event recording
# - {Musa::MIDIVoices} - MIDI voice management
# - {Musa::MusicXML} - MusicXML score generation
# - {Musa::Transcription} - Event transcription system
# - {Musa::Transcriptors} - Transcriptor implementations
#
# ## Usage
#
# @example Include all Musa DSL components
#   require 'musa-dsl'
#   include Musa::All
#
#   # Now you have access to all Musa DSL methods and classes
#   score = S.with(pitches: [60, 62, 64, 65])
#   sequencer = Sequencer.new
#
# @example Selective inclusion (alternative)
#   # Instead of Musa::All, you can include only what you need:
#   include Musa::Series
#   include Musa::Sequencer
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

  # Note: Musa::Extension::Matrix is a refinement and cannot be included
  # Use: using Musa::Extension::Matrix

  include Musa::Darwin
  include Musa::Markov
  include Musa::Rules
  include Musa::Variatio

  include Musa::MIDIRecorder
  include Musa::MIDIVoices

  include Musa::MusicXML

  include Musa::Transcriptors
end
