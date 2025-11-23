# Matrix - Sonic Gesture Conversion

Musa::Matrix provides refinements to convert matrix representations to P (point sequences) for sequencer playback. Sonic gestures can be represented as matrices where rows are time steps and columns are sonic parameters.

This opens a world of compositional possibilities by treating sonic gestures as **geometric objects in multidimensional spaces**. Each dimension of the matrix can represent a different sonic parameter (pitch, velocity, timbre, pan, filter cutoff, etc.), allowing you to:

- **Apply mathematical transformations**: Use standard matrix operations (rotation, scaling, translation, shearing) to transform sonic gestures geometrically. A rotation matrix can morph a melodic contour into a completely different shape while maintaining its gestural coherence.

- **Compose in geometric space**: Design sonic trajectories as paths through multidimensional parameter spaces. A straight line in pitch-velocity space becomes a linear glissando with proportional dynamic changes.

- **Interpolate and morph**: Create smooth transitions between sonic states by interpolating matrix points, generating continuous parameter sweeps that move through complex multidimensional spaces.

- **Decompose and recompose**: Extract individual parameter dimensions for independent processing, then recombine them into new sonic configurations.

The conversion to P format preserves the temporal relationships (durations calculated from time differences) while making the data suitable for sequencer playback, enabling you to realize complex geometric transformations as actual sonic events.

```ruby
require 'musa-dsl'

using Musa::Extension::Matrix

# Matrix representing a melodic gesture: [time, pitch]
# Time progresses: 0 -> 1 -> 2
# Pitch changes: 60 -> 62 -> 64
melody_matrix = Matrix[[0, 60], [1, 62], [2, 64]]

# Convert to P format for sequencer playback
# time_dimension: 0 means first column is time
# Time dimension removed, used only for duration calculation
p_sequence = melody_matrix.to_p(time_dimension: 0)

# Result: [[[60], 1, [62], 1, [64]]]
# Format: [[pitch1], duration1, [pitch2], duration2, [pitch3]]
# Each value [60], [62], [64] is extended with V module

# Multi-parameter example: [time, pitch, velocity]
gesture = Matrix[[0, 60, 100], [0.5, 62, 110], [1, 64, 120]]
p_with_velocity = gesture.to_p(time_dimension: 0)
# Result: [[[60, 100], 0.5, [62, 110], 0.5, [64, 120]]]

# Condensing connected gestures
phrase1 = Matrix[[0, 60], [1, 62]]
phrase2 = Matrix[[1, 62], [2, 64], [3, 65]]

# Matrices that share endpoints are automatically merged
merged = [phrase1, phrase2].to_p(time_dimension: 0)
# Result: [[[60], 1, [62], 1, [64], 1, [65]]]
# Both phrases merged into continuous sequence
```

**Use cases:**
- Converting recorded MIDI data to playable sequences
- Transforming algorithmic compositions from matrix form to time-based sequences
- Merging fragmented sonic gestures

## API Reference

**Complete API documentation:**
- [Musa::Matrix](https://rubydoc.info/gems/musa-dsl/Musa/Matrix) - Matrix to point sequence conversion

**Source code:** `lib/matrix/`


