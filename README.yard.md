# Musa-DSL — API reference

A Ruby framework and DSL for algorithmic sound and musical thinking and
composition. It builds complex temporal structures independently of the audio
rendering engine: sequencing and transport, lazy series, a text notation
(neumalang), scales and chords, generative tools, and transcription to MIDI and
MusicXML.

**This page is the API reference** — classes, methods, signatures, and the
`@example` blocks attached to them. Every one of those examples is executed and
its declared output compared against what the code actually returns, so what you
read here has been run.

## The conceptual documentation is not here

Knowing a signature is not knowing when to reach for it. The guides that answer
*when is this the answer, and when is it not* — one per subsystem, plus a
catalogue of idioms organised by the shape of the problem — live in the
repository, where their cross-references work:

**https://github.com/javier-sy/musa-dsl**

They also travel inside the gem itself, under `docs/`, so they are readable
offline from the installed copy and always match the version you have.

## Installing

```ruby
gem 'musa-dsl'
```

Requires Ruby ~> 3.4.

---

Copyright (c) 2016-2026 [Javier Sánchez Yeste](https://yeste.studio),
licensed under LGPL-3.0-or-later.
