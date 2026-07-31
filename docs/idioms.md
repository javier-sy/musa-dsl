# Idioms — choosing the MusaDSL form

Every entry below names a **reflex**: something a competent programmer writes
when they have not yet asked what MusaDSL calls it. The reflex always works.
That is the problem — it produces code that runs, sounds right, passes every
test, and is foreign to the framework.

This document is the answer to one question, asked at the moment of writing:

> *What I have to do here — how would it be expressed most beautifully in
> MusaDSL?*

It is organised by **the shape of the data and of the problem**, not by
subsystem, because the shape is what you can see when you are about to make the
mistake. The subsystem is what you can only see afterwards.

Read it from the symptom.

---

## The root principle

> **The shape of the data decides the idiom.**

The generalist reflex is not committed when the loop is written. It is committed
earlier, when the plan is modelled. Hold absolute positions and a loop of `at`
is already inevitable; hold durations and `play` is already natural. No guard
placed later can rescue a plan modelled in the wrong coordinates.

Two corollaries used throughout this document:

- **Model plans as durations, not as positions.**
- **Keep the musical layer musical**: grades, proportional durations and
  dynamic marks travel as far as the sink; pitches, seconds and integers appear
  only where the sound is actually produced.

---

## 1. Events placed in time

**Reflex** — precompute absolute positions, then iterate:

```ruby
plan.each_with_index do |(start, duration), i|
  at 1 + start do ... end
end
```

**Idiom** — a serie whose elements carry `duration:` (and, when the sounding
length differs from the step, `note_duration:` and `forward_duration:`),
consumed by `play`, which walks time itself:

```ruby
play plan_serie do |duration:, order:, ...|
  ...
end
```

**What is gained** — the plan stays *data*: sliceable (`.cut`, `.max_size`),
composable (`MERGE`, `H`, `HC`), reusable across voices (`.buffered`). Temporal
arithmetic disappears from the code. And `play` returns a control, so the ending
is a handle (`control.after { ... }`) instead of a computed final position.

**Detectable** — `at` inside `each`/`times`/`while`, or `at` whose position
contains a loop variable.

**When the reflex is right** — a genuine one-off landmark: the start, a single
structural mark, the end.

---

## 2. Sequences of anything

**Reflex** — an array, iterated, indexed, or consumed with `.next_value` by
hand.

**Idiom** — `S(...)` and the operations: `.map`, `.select`, `.remove`,
`.reverse`, `.shift`, `.randomize`, `.repeat`, `.max_size`, `.cut`, `.with`,
`MERGE`, `H`/`HC`. Numeric contours have constructors of their own: `FOR`,
`SIN`, `FIBO`, `HARMO`, `RND`.

**What is gained** — laziness (infinite generators, no cost until consumed) and
composition (a complex line is an expression, not a built list). The
prototype/instance split (`.i`) lets the same definition be read independently
by several voices; `.buffered` + `.buffer.i` lets them read the *same* progress
at different speeds, which is what a canon is.

**Detectable** — `.i.to_a` followed by Array operations followed by `S(*...)`.

**When the reflex is right** — materialising a finite, already-computed plan
into `S(*plan)` is legitimate: generators feed series. The smell is when every
intermediate step was expressible as a serie operation.

---

## 3. Pitch

**Reflex** — arithmetic on MIDI note numbers: `pitch + 7`, `% 12`, a table of
semitones, an array called `pitches`.

**Idiom** — `scale[grade]`, `note.at_octave`, `.sharp` / `.flat`, `chord_on`,
`chord.with_quality` / `.with_move`, `chord.search_in_scales`,
`scale.degree_of_chord`.

**What is gained** — this is not decoration. A piece written in MIDI integers is
welded to one tuning and one tonic; written in grades, transposing, modulating
or re-temperament is *rebinding the scale*. And the material stays navigable:
you can ask a chord for its degree, a scale for its chords.

**Detectable** — literals in the 48–84 range combined with `+`/`-`/`% 12`.

---

## 4. Layers: musical intent vs. realization

**Reflex** — compute MIDI pitches and durations in seconds where the material is
defined.

**Idiom** — GDV (grade, duration as a multiple of `base_duration`, velocity as a
dynamic mark) all the way to the edge; `to_pdv(scale)` and the conversion to
seconds only in the sink.

**What is gained** — the same material renders to MIDI, to a synthesis server or
to MusicXML by changing the sink, not the piece.

**Detectable** — `60.0 / bpm`, `* beat` or integer velocities appearing in the
*material* (constants, series, plans) rather than in the block that finally
emits sound. Converting inside the emitting call is correct and is not a smell.

---

## 5. Recurrences and hand-made state

**Reflex** — `a, b = b, a + b`, accumulators inside `loop`, a small class whose
core is a recurrence.

**Idiom** — `FIBO(first, second)`, whose seeds are its first two values, so
`FIBO(1, 2)` and `FIBO(2, 1)` are relatives of Fibonacci and not delayed echoes
of it; `E(*seeds) { |last_value:, caller:| ... }` when the recurrence is not
Fibonacci at all (`caller.parameters` carries the state); `.repeat` for cycles.

**What is gained** — the recurrence becomes a serie, so it composes with
everything else: `.map`, `.select`, feeding `play` directly.

**Detectable** — the swap `a, b = b, a + b` is a literal grep.

**When the reflex is right** — when the object needs to be *inspected*, not just
consumed. A serie is a flow: you cannot ask it for its period, its reachable
states or its cycle. A grid that must answer "when does my state repeat?" is a
domain object and deserves a class. What is never right is writing the
recurrence four times instead of extracting it.

---

## 6. Randomness

**Reflex** — `rand` with a ladder of `if p < 0.3`.

**Idiom** — `RND(values, random: Random.new(seed))`, constrained with
`.remove { |value, history| ... }`; Markov when the tendency has memory. Note
that `Markov` **is a serie** — it can feed `play` directly and be chained with
`.map`.

**What is gained** — reproducibility (an explicit seed makes the piece the same
piece), tendencies as a *mutable table* (blend two tables to evolve behaviour
while the chain keeps its state), and constraints declared rather than filtered
ad hoc.

**Detectable** — `rand` not derived from a seeded `Random`; thresholds in a
chain of `if`.

---

## 7. Combinatorics and search

**Reflex** — nested loops, `Array#product`, `permutation` followed by filters.

**Idiom** — **Variatio** (fields + `constructor`, re-constrained at runtime with
`.on()`), **GenerativeGrammar** (`|` alternative, `+` sequence, `.repeat`,
`.limit`), **Rules** (grow a tree, `prune` during growth, `fish` the survivors),
**Darwin** (score candidates by measures and weights, select the fittest).

**What is gained** — the exploration space becomes an object: re-restrictable,
filterable, and prunable *during* growth instead of generate-then-filter. The
constraints are declared where they are conceived.

**Detectable** — `product` / `permutation` / `combination`, or three nested
loops filling an array of candidates.

---

## 8. Musical material as text

**Reflex** — literal arrays of `{ grade:, duration:, velocity: }`.

**Idiom** — neumas: `'(0 1 mf) (+2 1/2 f tr)'.to_neumas`, `|` for polyphony,
`.neu` files.

**What is gained** — material readable *as a score*, relative encoding
(invariant under transposition), access to ornaments, and the route to MusicXML.

**Detectable** — hash literals with those three keys, repeated.

---

## 9. Articulation and ornament

**Reflex** — schedule a grace note plus the real note; multiply a duration by
`0.5` for staccato.

**Idiom** — a `Transcriptor` with the appropriate transcription set; the
distinction between `duration`, `note_duration` and `forward_duration`.

**What is gained** — articulation as annotation instead of arithmetic, and the
same GDV rendering expanded MIDI or symbolic MusicXML by changing the set.

**Detectable** — `* 0.5` on durations; pairs of notes with a small fixed offset.

---

## 10. Parameters that change over time

**Reflex** — `every` plus a variable nudged towards a target.

**Idiom** — `move from:, to:, duration:, every:, function:` (scalar and hash
forms); `SIN()` for cyclic contours; `.quantize` for stepped output.

**What is gained** — the *shape* (a proc from `[0..1]` to `[0..1]`) is separated
from the *clock*, so one movement can rise and fall, and the shape can be
reasoned about, plotted and reused.

**Detectable** — `every` whose body mutates a variable towards a target.

---

## 11. Several layers of events in time

**Reflex** — arrays of `[time, ...]` sorted and traversed with indices.

**Idiom** — AbsTimed series and `TIMED_UNION` (array and hash forms),
`.flatten_timed`, `.compact_timed`, consumed with `play_timed`, whose block
receives `time:` and `started_ago:`.

**What is gained** — merging layers becomes algebra, with components addressable
by name.

**Detectable** — `sort_by { |e| e[:time] }` followed by pointer traversal.

---

## 12. Macro form

**Reflex** — constants chained by addition (`SECTION_2 = SECTION_1 + LENGTH`),
boolean flags, a counter deciding what happens.

**Idiom** — `on` / `launch` for sections; `control.after` for natural
completion; `control.on_stop` for cleanup; `every` with `duration:`, `till:` or
`condition:`.

**What is gained** — form as a graph of events rather than arithmetic; material
recalculated at each entry rather than precomputed; and the distinction between
*finishing* and *being stopped*, which position arithmetic cannot express at
all. `after` fires only on natural completion — never rely on it for cleanup.

**Detectable** — position constants defined in terms of other position
constants.

---

## 13. Multiparametric gesture

**Reflex** — tables of parameters traversed by loops.

**Idiom** — `Matrix#to_p(time_dimension:)` → `to_ps_serie` / `to_timed_serie` →
`play_timed`; `condensed_matrices` for the reduction.

**What is gained** — a trajectory drawn in several dimensions at once becomes a
single object, interpolated and consumed as one gesture.

**Detectable** — low. This is territory for *suggestion*, not for lint: the
user will rarely ask for it by name. When someone describes "a trajectory that
is drawn", the matrix is the honest answer.

---

## 14. Event lists for querying or export

**Reflex** — hand-rolled arrays of events, then hand-rolled queries over them.

**Idiom** — `Datasets::Score` (`at`, `between`, `changes_between`, `subset`,
`values_of`) and the MusicXML builder.

**What is gained** — the piece becomes queryable, and exportable, without a
second representation.

---

## 15. Clocks

**Reflex** — always the real clock, even for tests and offline rendering.

**Idiom** — `DummyClock` for tests and fast rendering, `ExternalTickClock` when
another source owns time, tickless mode when events are not on a grid,
`change_position_to` to jump.

**What is gained** — a piece that can be rendered faster than real time, and
tested at all.

---

## Using this document

For each layer or material of a piece, before writing code, name:

1. **the shape of the data** — serie? neumas? generator output? timed serie? a
   class of its own, and if so why the framework does not have it;
2. **the verb that consumes it** — `play`, `play_timed`, `move`, `every`,
   `on` + `launch`, `at`;
3. **why not the neighbouring verb**.

`at` with a computed position, and a bespoke class, are the two answers that
always require an explicit justification. Neither is forbidden — sometimes a
class modelling an inspectable structure *is* the honest answer. What is not
acceptable is that the choice was never argued against the framework.
