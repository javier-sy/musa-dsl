# PS event processing for MusicXML export.
#
# Converts {PS} (Pitch Series) events to MusicXML dynamics markings.
# Handles crescendo, diminuendo wedges (hairpins), and static dynamics markings.
#
# ## Processing Steps
#
# 1. Extract dynamics type (:crescendo, :diminuendo, or :dynamics)
# 2. For wedges: determine if it's the start or end of the marking
# 3. Add dynamics marking at wedge start/end if level changed
# 4. Add wedge element with appropriate type and niente attribute
# 5. Track last dynamics to avoid redundant markings
#
# ## Dynamics Types Supported
#
# - **:crescendo** → crescendo wedge (hairpin opening)
#   - Uses :from attribute for starting dynamics level
#   - Uses :to attribute for ending dynamics level
#   - Supports niente (from silence) when :from == 0
#
# - **:diminuendo** → diminuendo wedge (hairpin closing)
#   - Uses :from attribute for starting dynamics level
#   - Uses :to attribute for ending dynamics level
#   - Supports niente (to silence) when :to == 0
#
# - **:dynamics** → static dynamics marking (pp, mf, ff, etc.)
#   - Uses :from attribute for dynamics level
#   - No wedge created, only dynamics text
#
# ## Dynamics Levels
#
# Dynamics levels are numeric indices (0-10) converted to standard markings:
# - 0: silence (niente)
# - 1-3: ppp range
# - 4-5: pp-p range
# - 6: mp
# - 7: mf
# - 8-9: f-ff range
# - 10: fff
#
# ## Context Tracking
#
# Uses DynamicsContext to track the last dynamics marking, preventing
# duplicate markings when consecutive events have the same level.
#
# @api private
module Musa::Datasets::Score::ToMXML
  using Musa::Extension::InspectNice

  # Context for tracking dynamics state across events.
  #
  # @api private
  DynamicsContext = Struct.new(:last_dynamics)
  private_constant :DynamicsContext

  # Processes PS event to MusicXML dynamics marking.
  #
  # Converts a single PS event to one or more MusicXML dynamics/wedge elements.
  # Handles crescendo/diminuendo wedges and static dynamics markings. Tracks
  # context to avoid redundant markings.
  #
  # @param measure [Musa::MusicXML::Builder::Measure] target measure
  # @param element [Hash] event hash from score query
  #   Contains :dataset (PS event), :change (:start/:finish for wedges)
  # @param context [DynamicsContext, nil] dynamics tracking context
  # @param logger [Musa::Logger::Logger] logger for debugging
  # @param do_log [Boolean] enable logging
  #
  # @return [DynamicsContext] updated context with last dynamics
  #
  # @example Crescendo from pp to ff
  #   element_start = {
  #     dataset: { type: :crescendo, from: 4, to: 9, duration: 2r }.extend(Musa::Datasets::PS),
  #     change: :start
  #   }
  #   context = process_ps(measure, element_start, nil, logger, false)
  #   # Adds "pp" dynamics and crescendo wedge start
  #
  #   element_finish = {
  #     dataset: { type: :crescendo, from: 4, to: 9, duration: 2r }.extend(Musa::Datasets::PS),
  #     change: :finish
  #   }
  #   context = process_ps(measure, element_finish, context, logger, false)
  #   # Adds wedge stop and "ff" dynamics
  #
  # @example Diminuendo to silence (niente)
  #   element_start = {
  #     dataset: { type: :diminuendo, from: 7, to: 0, duration: 1r }.extend(Musa::Datasets::PS),
  #     change: :start
  #   }
  #   process_ps(measure, element_start, nil, logger, false)
  #   # Adds "mf" dynamics and diminuendo wedge start
  #
  #   element_finish = {
  #     dataset: { type: :diminuendo, from: 7, to: 0, duration: 1r }.extend(Musa::Datasets::PS),
  #     change: :finish
  #   }
  #   process_ps(measure, element_finish, context, logger, false)
  #   # Adds wedge stop with niente=true (diminuendo to silence)
  #
  # @example Crescendo from silence (niente)
  #   element_start = {
  #     dataset: { type: :crescendo, from: 0, to: 6, duration: 1r }.extend(Musa::Datasets::PS),
  #     change: :start
  #   }
  #   process_ps(measure, element_start, nil, logger, false)
  #   # Adds crescendo wedge with niente=true (from silence)
  #
  # @example Static dynamics marking
  #   element = {
  #     dataset: { type: :dynamics, from: 8, duration: 0r }.extend(Musa::Datasets::PS),
  #     change: :start
  #   }
  #   process_ps(measure, element, nil, logger, false)
  #   # Adds "f" dynamics marking only
  #
  # @api private
  private def process_ps(measure, element, context, logger, do_log)
    context ||= DynamicsContext.new

    logger.debug ''
    logger.debug('process_ps') { "processing #{element.inspect}" } if do_log

    case element[:dataset][:type]
    when :crescendo, :diminuendo
      if element[:change] == :start
        dynamics = dynamics_to_string(element[:dataset][:from])

        if dynamics != context.last_dynamics
          if dynamics
            if element[:dataset][:from] < 0
              logger.warn { "dynamics #{element[:dataset][:from]} not renderizable" } if do_log
            elsif element[:dataset][:from] > 0
              measure.add_dynamics dynamics, placement: 'below'
            end
          end

          context.last_dynamics = dynamics
        end

        measure.add_wedge element[:dataset][:type],
                          niente: element[:dataset][:type] == :crescendo && element[:dataset][:from] == 0,
                          placement: 'below'
      else
        measure.add_wedge 'stop',
                          niente: element[:dataset][:type] == :diminuendo && element[:dataset][:to] == 0,
                          placement: 'below'

        dynamics = dynamics_to_string(element[:dataset][:to])

        if dynamics != context.last_dynamics
          if dynamics
            if element[:dataset][:to] < 0
              logger.warn { "dynamics #{element[:dataset][:to]} not renderizable" } if do_log
            elsif element[:dataset][:to] > 0
              measure.add_dynamics dynamics, placement: 'below'
            end
          end
        end

        context.last_dynamics = dynamics
      end

    when :dynamics
      dynamics = dynamics_to_string(element[:dataset][:from])

      if dynamics != context.last_dynamics


        if dynamics
          if element[:dataset][:from] < 0
            logger.warn { "dynamics #{element[:dataset][:to]} not renderizable" } if do_log
          elsif element[:dataset][:from] > 0
            measure.add_dynamics dynamics, placement: 'below'
          end
        end

        context.last_dynamics = dynamics
      end

    else
      # ignored
    end

    context
  end

end
