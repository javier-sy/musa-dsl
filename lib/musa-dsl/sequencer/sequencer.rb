# Sequencer module aggregator and entry point.
#
# This file loads all sequencer components in correct dependency order,
# providing the complete sequencer system for musical event scheduling.
#
# ## Architecture Overview
#
# The sequencer system consists of several layers:
#
# ### Core Layer
#
# - **BaseSequencer** (`base-sequencer.rb`): Core sequencer class defining
#   interface and lifecycle
# - **Timeslots** (`timeslots.rb`): Sorted time-indexed event storage
#
# ### Timing Implementations
#
# - **TickBasedTiming** (`base-sequencer-tick-based.rb`): Quantized timing
#   with fixed tick increments
# - **TicklessBasedTiming** (`base-sequencer-tickless-based.rb`): Continuous
#   timing without quantization
#
# ### Implementation Layer
#
# - **Core Implementation** (`base-sequencer-implementation.rb`): Event
#   scheduling, execution, and error handling
# - **Every** (`base-sequencer-implementation-every.rb`): Recurring loops
# - **Move** (`base-sequencer-implementation-move.rb`): Value animation
# - **Play** (`base-sequencer-implementation-play.rb`): Series playback
# - **Play Timed** (`base-sequencer-implementation-play-timed.rb`): Explicit
#   timing playback
# - **Play Helper** (`base-sequencer-implementation-play-helper.rb`): Play
#   evaluation modes
#
# ### DSL Layer
#
# - **Sequencer** (`sequencer-dsl.rb`): High-level DSL wrapper with block
#   context management
#
# ## Usage
#
# For high-level composition, use Musa::Sequencer::Sequencer (DSL wrapper):
#
# ```ruby
# require 'musa-dsl/sequencer/sequencer'
#
# seq = Musa::Sequencer::Sequencer.new(4, 96) do
#   at(1r) { puts "Bar 1" }
#   every(1r, duration: 4r) { puts "Beat" }
# end
#
# seq.run
# ```
#
# For low-level control, use Musa::Sequencer::BaseSequencer directly:
#
# ```ruby
# seq = Musa::Sequencer::BaseSequencer.new(4, 96)
# seq.at(1r) { puts "Bar 1" }
# seq.run
# ```
#
# ## File Load Order
#
# Files are loaded in dependency order:
# 1. BaseSequencer (core class definition)
# 2. Core implementation (scheduling logic)
# 3. Feature implementations (every, move, play, play_timed)
# 4. DSL wrapper (user-friendly interface)
#
# @see Musa::Sequencer::Sequencer High-level DSL interface
# @see Musa::Sequencer::BaseSequencer Low-level sequencer core
#
require_relative 'base-sequencer'

require_relative 'base-sequencer-implementation'

require_relative 'base-sequencer-implementation-every'
require_relative 'base-sequencer-implementation-move'
require_relative 'base-sequencer-implementation-play'
require_relative 'base-sequencer-implementation-play-timed'

require_relative 'sequencer-dsl'
