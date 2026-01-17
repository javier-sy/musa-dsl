# frozen_string_literal: true

# Equal temperament 12-tone scale system and scale kinds.
#
# This file loads the complete ET12 scale system including:
# - TwelveSemitonesScaleSystem (base class)
# - EquallyTempered12ToneScaleSystem (concrete implementation)
# - All standard scale kinds (chromatic, major, minor, harmonic minor)
# - All Greek/church modes (dorian, phrygian, lydian, mixolydian, locrian)
# - Pentatonic scales (major, minor)
# - Blues scales (blues, blues major)
# - Symmetric scales (whole tone, diminished)
# - Melodic minor modes (melodic minor, dorian b2, lydian augmented, etc.)
# - Harmonic major
# - Ethnic scales (double harmonic, hungarian minor, phrygian dominant, etc.)
# - Bebop scales (dominant, major, minor)

require_relative 'scales'

# Scale systems
require_relative 'scale_systems/twelve_semitones_scale_system'
require_relative 'scale_systems/equally_tempered_12_tone_scale_system'

# Core scale kinds
require_relative 'scale_kinds/chromatic_scale_kind'
require_relative 'scale_kinds/major_scale_kind'
require_relative 'scale_kinds/minor_natural_scale_kind'
require_relative 'scale_kinds/minor_harmonic_scale_kind'

# Greek/church modes
require_relative 'scale_kinds/modes/dorian_scale_kind'
require_relative 'scale_kinds/modes/phrygian_scale_kind'
require_relative 'scale_kinds/modes/lydian_scale_kind'
require_relative 'scale_kinds/modes/mixolydian_scale_kind'
require_relative 'scale_kinds/modes/locrian_scale_kind'

# Pentatonic scales
require_relative 'scale_kinds/pentatonic/pentatonic_major_scale_kind'
require_relative 'scale_kinds/pentatonic/pentatonic_minor_scale_kind'

# Blues scales
require_relative 'scale_kinds/blues/blues_scale_kind'
require_relative 'scale_kinds/blues/blues_major_scale_kind'

# Symmetric scales
require_relative 'scale_kinds/symmetric/whole_tone_scale_kind'
require_relative 'scale_kinds/symmetric/diminished_hw_scale_kind'
require_relative 'scale_kinds/symmetric/diminished_wh_scale_kind'

# Melodic minor and modes
require_relative 'scale_kinds/melodic_minor/melodic_minor_scale_kind'
require_relative 'scale_kinds/melodic_minor/dorian_b2_scale_kind'
require_relative 'scale_kinds/melodic_minor/lydian_augmented_scale_kind'
require_relative 'scale_kinds/melodic_minor/lydian_dominant_scale_kind'
require_relative 'scale_kinds/melodic_minor/mixolydian_b6_scale_kind'
require_relative 'scale_kinds/melodic_minor/locrian_sharp2_scale_kind'
require_relative 'scale_kinds/melodic_minor/altered_scale_kind'

# Harmonic major
require_relative 'scale_kinds/harmonic_major/harmonic_major_scale_kind'

# Ethnic/exotic scales
require_relative 'scale_kinds/ethnic/double_harmonic_scale_kind'
require_relative 'scale_kinds/ethnic/hungarian_minor_scale_kind'
require_relative 'scale_kinds/ethnic/phrygian_dominant_scale_kind'
require_relative 'scale_kinds/ethnic/neapolitan_minor_scale_kind'
require_relative 'scale_kinds/ethnic/neapolitan_major_scale_kind'

# Bebop scales
require_relative 'scale_kinds/bebop/bebop_dominant_scale_kind'
require_relative 'scale_kinds/bebop/bebop_major_scale_kind'
require_relative 'scale_kinds/bebop/bebop_minor_scale_kind'
