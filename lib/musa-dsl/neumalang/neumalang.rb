require 'citrus'

require_relative '../series'
require_relative '../neumas'
require_relative '../datasets'

module Musa
  # Neumalang namespace for parser and related functionality.
  #
  # @api public
  module Neumalang
    # Neumalang parser for parsing neuma text notation to structured objects.
    #
    # Neumalang is a domain-specific language (DSL) for expressing musical notation
    # in a compact, text-based format. The parser uses Citrus (PEG parser framework)
    # to parse neuma notation strings into structured Ruby objects.
    #
    # ## Architecture Overview
    #
    # ### Parser Framework
    #
    # The parser is built on **Citrus**, a Parsing Expression Grammar (PEG) framework:
    #
    # - Grammar defined in `.citrus` files (terminals, datatypes, neuma, vectors, process, neumalang)
    # - Each grammar rule has a corresponding Ruby module for semantic actions
    # - Modules transform parse tree into structured neuma objects
    #
    # ### Grammar Files
    #
    # 1. **terminals.citrus** - Basic tokens (numbers, names, symbols, whitespace)
    # 2. **datatypes.citrus** - Data types (strings, numbers, symbols, vectors)
    # 3. **neuma.citrus** - Neuma notation (grade, duration, velocity, modifiers)
    # 4. **vectors.citrus** - Vector notation (V, PackedV for musical data)
    # 5. **process.citrus** - Process notation (P for rhythmic processes)
    # 6. **neumalang.citrus** - Top-level grammar combining all elements
    #
    # ## Parsing Pipeline
    #
    # ```ruby
    # Text → Citrus Parser → Parse Tree → Semantic Modules → Neuma Objects → Series
    # "0 +2 +2"    ↓              ↓              ↓                ↓
    #           Grammar      AST nodes    Module.value()    Structured hashes
    # ```
    #
    # ## Neuma Object Structure
    #
    # Parsed neumas are hashes with `:kind` key indicating type:
    #
    # ### GDVD (Musical Event)
    # ```ruby
    # {
    #   kind: :gdvd,
    #   gdvd: {
    #     delta_grade: +2,
    #     factor_duration: 2,
    #     modifiers: { tr: true }
    #   }.extend(Musa::Datasets::GDVd)
    # }.extend(Musa::Neumas::Neuma)
    # ```
    #
    # ### Serie (Sequential)
    # ```ruby
    # {
    #   kind: :serie,
    #   serie: [neuma1, neuma2, ...]
    # }.extend(Musa::Neumas::Neuma::Serie)
    # ```
    #
    # ### Parallel (Polyphonic)
    # ```ruby
    # {
    #   kind: :parallel,
    #   parallel: [
    #     { kind: :serie, serie: [...] },
    #     { kind: :serie, serie: [...] }
    #   ]
    # }.extend(Musa::Neumas::Neuma::Parallel)
    # ```
    #
    # ### Commands & Variables
    # ```ruby
    # { kind: :command, command: proc { ... } }
    # { kind: :use_variable, use_variable: :@variable_name }
    # { kind: :assign_to, assign_to: [:@var1], assign_value: ... }
    # ```
    #
    # ### Values
    # ```ruby
    # { kind: :value, value: 42 }
    # { kind: :value, value: :symbol }
    # { kind: :value, value: "string" }
    # ```
    #
    # ### Vectors & Processes
    # ```ruby
    # { kind: :v, v: [1, 2, 3].extend(Musa::Datasets::V) }
    # { kind: :packed_v, packed_v: {a: 1, b: 2}.extend(Musa::Datasets::PackedV) }
    # { kind: :p, p: [values...].extend(Musa::Datasets::P) }
    # ```
    #
    # ## Neumalang Syntax Features
    #
    # - **Grade notation**: `0`, `+2`, `-1`, `^2` (octave up), `v1` (octave down)
    # - **Duration notation**: `_`, `_2`, `_/2`, `_3/2` (dotted), `_.` (dots)
    # - **Velocity notation**: `p`, `pp`, `mp`, `mf`, `f`, `ff`, `fff`
    # - **Modifiers**: `.tr`, `.mor`, `.turn`, `.st`, `.b` (ornaments/articulations)
    # - **Appogiatura**: `(+1_/4)+2_` (grace note before main note)
    # - **Parallel**: `[0 +2 +4 | +7 +5 +7]` (multiple voices)
    # - **Vectors**: `<1 2 3>` (V), `<a: 1 b: 2>` (PackedV)
    # - **Process**: `<< 1 _ _ 2 _ >>` (rhythmic process)
    # - **Commands**: `{ ruby code }` (embedded Ruby)
    # - **Variables**: `@variable`, `@var = value`
    # - **Events**: `event_name(params)`, `event_name(key: value)`
    #
    # ## Usage
    #
    # ```ruby
    # # Parse string
    # neumas = Musa::Neumalang::Neumalang.parse("0 +2 +2 -1 0")
    #
    # # Parse with decoder (converts GDVD to GDV)
    # decoder = NeumaDecoder.new(scale)
    # gdvs = Musa::Neumalang::Neumalang.parse(
    #   "0 +2 +2 -1 0",
    #   decode_with: decoder
    # )
    #
    # # Parse file
    # neumas = Musa::Neumalang::Neumalang.parse_file("melody.neuma")
    #
    # # Debug parsing
    # Musa::Neumalang::Neumalang.parse(
    #   "0 +2 +2 -1 0",
    #   debug: true  # Dumps parse tree
    # )
    # ```
    #
    # ## Integration
    #
    # - **Series**: Parsed neumas generate Series for sequential playback
    # - **Neumas**: Output extends Neuma modules for structural operations
    # - **Datasets**: GDVd, V, PackedV, P extensions for musical data
    # - **Decoders**: Optional decode_with parameter for immediate GDV conversion
    #
    # @example Basic parsing (simple melody)
    #   neumas = Musa::Neumalang::Neumalang.parse("(0) (+2) (+2) (-1) (0)")
    #   # Returns serie of GDVD neuma objects
    #
    #   # Access the series
    #   neumas.i.to_a.size  # => 5
    #   neumas.i.to_a[0][:gdvd][:abs_grade]  # => 0
    #   neumas.i.to_a[1][:gdvd][:delta_grade]  # => 2
    #
    # @example With decoder
    #   scale = Musa::Scales::Scales.et12[440.0].major[60]
    #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
    #     scale,
    #     base_duration: 1/4r
    #   )
    #
    #   gdvs = Musa::Neumalang::Neumalang.parse(
    #     "(0) (+2) (+2) (-1) (0)",
    #     decode_with: decoder
    #   )
    #   # Returns serie of GDV events
    #
    # @example Complex notation
    #   neumas = Musa::Neumalang::Neumalang.parse(
    #     "(0) (+2 .tr) (+4 _) (+5 _2) ((^1 _/4) +7 _) (+5) (+4) (+2) (0)"
    #   )
    #
    # @example Parallel voices
    #   neumas = Musa::Neumalang::Neumalang.parse(
    #     "[(0) (+2) (+4) | (+7) (+5) (+7)]"
    #   )
    #
    # @example With variables and commands
    #   neumas = Musa::Neumalang::Neumalang.parse(
    #     "@melody = (0) (+2) (+2) (-1) (0)
    #      @melody { |gdv| gdv[:duration] *= 2 }"
    #   )
    #
    # @see Musa::Neumas
    # @see Musa::Neumas::Decoders::NeumaDecoder
    # @see Musa::Datasets
    # @see https://github.com/mjackson/citrus Citrus parser framework
    #
    # @api public
    module Neumalang
      # Parser namespace containing grammar and semantic modules.
      #
      # @api public
      module Parser
        # Grammar namespace where Citrus loads grammar rules.
        #
        # Populated by Citrus when loading .citrus files.
        # Contains Grammar class with parse methods.
        #
        # @api private
        module Grammar; end

        # Semantic action for top-level sentences (sequence of expressions).
        #
        # Transforms parsed expressions into Serie structure.
        # Used for main neuma sequences like `"0 +2 +4"`.
        #
        # @api private
        module Sentences
          # Builds serie from expressions.
          #
          # @return [Hash] serie structure with kind :serie
          #
          # @api private
          def value
            Musa::Series::Constructors.S(*captures(:expression).collect(&:value)).extend(Musa::Neumas::Neuma::Serie)
          end
        end

        # Semantic action for parallel structure (voices separated by `|`).
        #
        # Transforms bracketed parallel notation into Parallel structure.
        # Used for polyphonic notation like `"[0 +2 | +7 +5]"`.
        #
        # @api private
        module BracketedBarSentences
          # Builds parallel structure from bar-separated series.
          #
          # @return [Hash] parallel structure with kind :parallel
          #
          # @api private
          def value
            { kind: :parallel,
              parallel: [{ kind: :serie,
                           serie: Musa::Series::Constructors.S(*capture(:aa).value) }] +
                                  captures(:bb).collect { |c| { kind: :serie, serie: Musa::Series::Constructors.S(*c.value) } }
            }.extend(Musa::Neumas::Neuma::Parallel)
          end
        end

        # Semantic action for bracketed sentences (grouping).
        #
        # Transforms bracketed expressions into serie structure.
        # Used for grouping like `"[0 +2 +4]"` (without bars).
        #
        # @api private
        module BracketedSentences
          # Builds serie from bracketed sentences.
          #
          # @return [Hash] serie structure with kind :serie
          #
          # @api private
          def value
            { kind: :serie,
              serie: Musa::Series::Constructors.S(*capture(:sentences).value) }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for command references.
        #
        # Transforms referenced braced commands (Ruby code blocks).
        # Used when command is referenced elsewhere.
        #
        # @api private
        module ReferencedBracedCommand
          # Builds command reference structure.
          #
          # @return [Hash] command reference with kind :command_reference
          #
          # @api private
          def value
            { kind: :command_reference,
              command: capture(:braced_command).value }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for variable assignment.
        #
        # Transforms variable assignment notation like `"@melody = 0 +2 +4"`.
        # Supports multiple variables: `"@var1 @var2 = expression"`.
        #
        # @api private
        module VariableAssign
          # Builds variable assignment structure.
          #
          # @return [Hash] assignment with kind :assign_to, variable names, and value
          #
          # @api private
          def value
            { kind: :assign_to,
              assign_to: captures(:use_variable).collect { |c| c.value[:use_variable] },
              assign_value: capture(:expression).value
            }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for event notation.
        #
        # Transforms event calls like `"event_name(params)"` or `"event_name(key: value)"`.
        # Events can trigger external actions during playback.
        #
        # @api private
        module Event
          # Builds event structure with name and parameters.
          #
          # @return [Hash] event with kind :event, name, and optional parameters
          #
          # @api private
          def value
            { kind: :event,
              event: capture(:name).value.to_sym
            }.merge(capture(:parameters) ? capture(:parameters).value : {}).extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for function/event parameters.
        #
        # Parses parameter lists for events and commands.
        # Separates positional parameters, keyword parameters, and proc parameters.
        #
        # @api private
        module Parameters
          # Builds parameters structure.
          #
          # @return [Hash] parameters with :value_parameters, :key_parameters, :proc_parameter
          #
          # @api private
          def value
            value_parameters = []
            key_value_parameters = {}

            captures(:parameter).each do |pp|
              p = pp.value
              if p.has_key? :key_value
                key_value_parameters.merge! p[:key_value]
              else
                value_parameters << p[:value]
              end
            end

            {}.tap do |_|
              _[:value_parameters] = value_parameters unless value_parameters.empty?
              _[:key_parameters] = key_value_parameters unless key_value_parameters.empty?

              _[:proc_parameter] = capture(:codeblock).value if capture(:codeblock)
            end
          end
        end

        # Semantic action for code blocks (proc parameters).
        #
        # Transforms braced commands or variable references into proc parameters.
        #
        # @api private
        module Codeblock
          # Builds codeblock structure.
          #
          # @return [Hash] codeblock with command or variable reference
          #
          # @api private
          def value
            { codeblock:
                capture(:braced_command)&.value ||
                  capture(:referenced_braced_command)&.value ||
                  capture(:use_variable)&.value }
          end
        end

        # Semantic action for individual parameter.
        #
        # Transforms either key-value parameter or positional parameter.
        #
        # @api private
        module Parameter
          # Builds parameter structure.
          #
          # @return [Hash] parameter as :key_value or :value
          #
          # @api private
          def value
            if capture(:key_value_parameter)
              { key_value: capture(:key_value_parameter).value }
            else
              { value: capture(:expression).value }
            end
          end
        end

        # Semantic action for braced Ruby commands.
        #
        # Transforms `{ ruby code }` into executable proc.
        # Evaluates Ruby code string to create proc object.
        #
        # @api private
        module BracedCommand
          # Builds command structure with evaluated proc.
          #
          # @return [Hash] command with kind :command and executable proc
          #
          # @api private
          def value
            { kind: :command,
              command: eval("proc { #{capture(:complex_command).value.strip} }")
            }.merge(capture(:parameters) ? capture(:parameters).value : {}).extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for method call chains.
        #
        # Transforms method call chains like `"object.method1.method2"`.
        # Enables fluent interface notation in Neumalang.
        #
        # @api private
        module CallMethodsExpression
          # Builds method call chain structure.
          #
          # @return [Hash] call_methods with kind :call_methods, methods array, and target object
          #
          # @api private
          def value
            { kind: :call_methods,
              call_methods: captures(:method_call).collect(&:value),
              on: capture(:object_expression).value }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for variable usage.
        #
        # Transforms variable references like `"@variable"`.
        # Converts name to symbol with @ prefix.
        #
        # @api private
        module UseVariable
          # Builds variable reference structure.
          #
          # @return [Hash] variable reference with kind :use_variable and symbol name
          #
          # @api private
          def value
            { kind: :use_variable,
              use_variable: "@#{capture(:name).value}".to_sym }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for neuma notation (core musical event).
        #
        # Transforms neuma notation like `"+2_2.tr"` into GDVD structure.
        # Combines grade, octave, duration, velocity, and modifiers.
        #
        # This is the most important module - it builds the musical events
        # that form the core of Neumalang notation.
        #
        # @api private
        module NeumaAsAttributes
          # Builds GDVD structure from neuma attributes.
          #
          # Merges:
          #
          # - Grade attributes (delta_grade, abs_grade, etc.)
          # - Octave attributes (delta_octave, abs_octave)
          # - Duration attributes (delta_duration, abs_duration, factor_duration)
          # - Velocity attributes (delta_velocity, abs_velocity)
          # - Modifiers (ornaments, articulations)
          #
          # @return [Hash] GDVD neuma with kind :gdvd
          #
          # @example Parse result
          #   # "+2_2.tr" becomes:
          #   {
          #     kind: :gdvd,
          #     gdvd: {
          #       delta_grade: 2,
          #       factor_duration: 2,
          #       modifiers: { tr: true }
          #     }.extend(Musa::Datasets::GDVd)
          #   }
          #
          # @api private
          def value
            h = {}.extend Musa::Datasets::GDVd

            capture(:grade)&.value&.tap { |_| h.merge! _ if _ }
            capture(:octave)&.value&.tap { |_| h.merge! _ if _ }
            capture(:duration)&.value&.tap { |_| h.merge! _ if _ }
            capture(:velocity)&.value&.tap { |_| h.merge! _ if _ }

            h[:modifiers] = {} unless captures(:modifiers).empty?
            captures(:modifiers).collect(&:value).each { |_| h[:modifiers].merge! _ if _ }

            { kind: :gdvd, gdvd: h }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for packed vector notation.
        #
        # Transforms packed vector notation `"<a: 1 b: 2>"` into PackedV structure.
        # PackedV is hash-based vector with named components.
        #
        # @api private
        module PackedVector
          # Builds packed vector structure.
          #
          # @return [Hash] packed_v with kind :packed_v
          #
          # @api private
          def value
            { kind: :packed_v, packed_v: capture(:raw_packed_vector).value }.extend(Musa::Neumas::Neuma)
          end
        end

        # Semantic action for raw packed vector data.
        #
        # Extracts key-value pairs from packed vector notation.
        #
        # @api private
        module RawPackedVector
          # Builds PackedV hash.
          #
          # @return [Hash] PackedV extended hash
          #
          # @api private
          def value
            captures(:key_value).collect(&:value).to_h.extend(Musa::Datasets::PackedV)
          end
        end

        # Semantic action for vector notation.
        #
        # Transforms vector notation `"<1 2 3>"` into V structure.
        # V is array-based vector for musical data.
        #
        # @api private
        module Vector
          # Builds vector structure.
          #
          # @return [Hash] v with kind :v
          #
          # @api private
          def value
            { kind: :v, v: capture(:raw_vector).value }.extend(Musa::Neumas::Neuma)
          end
        end

        # Semantic action for raw vector data.
        #
        # Extracts numeric values from vector notation.
        #
        # @api private
        module RawVector
          # Builds V array.
          #
          # @return [Array] V extended array
          #
          # @api private
          def value
            captures(:raw_number).collect(&:value).extend(Musa::Datasets::V)
          end
        end

        # Semantic action for process notation (rhythmic process).
        #
        # Transforms process notation `"<< 1 _ _ 2 _ >>"` into P structure.
        # P represents rhythmic/temporal processes with values and rests.
        #
        # @api private
        module ProcessOfVectors
          # Builds process structure.
          #
          # Interleaves durations and rests: [first, duration1, rest1, duration2, rest2, ...]
          #
          # @return [Hash] p with kind :p
          #
          # @api private
          def value
            durations_rest = []
            i = 0

            rests = captures(:rest).collect(&:value)
            captures(:durations).collect(&:value).each do |duration|
              durations_rest[i * 2] = duration
              durations_rest[i * 2 + 1] = rests[i]
              i += 1
            end

            p = ([ capture(:first).value ] + durations_rest).extend(Musa::Datasets::P)
            { kind: :p, p: p }.extend(Musa::Neumas::Neuma)
          end
        end

        # Semantic action for differential grade (pitch) attribute.
        #
        # Parses relative pitch changes: `"+2"`, `"-1"`, `"+2#"` (with sharp), `"+I"` (interval).
        # Used for scale-degree-based melodic motion.
        #
        # @api private
        module DeltaGradeAttribute
          # Builds delta grade structure.
          #
          # @return [Hash] delta_grade, delta_sharps, delta_interval attributes
          #
          # @api private
          def value

            value = {}

            sign = capture(:sign)&.value || 1

            value[:delta_grade] = capture(:grade).value * sign if capture(:grade)
            value[:delta_sharps] = capture(:accidentals).value * sign if capture(:accidentals)

            value[:delta_interval] = capture(:interval).value if capture(:interval)
            value[:delta_interval_sign] = sign if capture(:interval) && capture(:sign)

            value
          end
        end

        # Semantic action for absolute grade (pitch) attribute.
        #
        # Parses absolute pitch: `"0"` (tonic), `"2#"` (2nd degree sharp), `"I"` (interval name).
        # Used for establishing absolute pitch positions.
        #
        # @api private
        module AbsGradeAttribute
          # Builds absolute grade structure.
          #
          # @return [Hash] abs_grade, abs_sharps attributes
          #
          # @api private
          def value
            value = {}

            value[:abs_grade] = capture(:grade).value if capture(:grade)
            value[:abs_grade] ||= capture(:interval).value.to_sym if capture(:interval)

            value[:abs_sharps] = capture(:accidentals).value if capture(:accidentals)

            value
          end
        end

        # Semantic action for differential octave attribute.
        #
        # Parses relative octave changes: `"^2"` (up 2 octaves), `"v1"` (down 1 octave).
        #
        # @api private
        module DeltaOctaveAttribute
          # Builds delta octave structure.
          #
          # @return [Hash] delta_octave attribute
          #
          # @api private
          def value
            { delta_octave: capture(:sign).value * capture(:number).value }
          end
        end

        # Semantic action for absolute octave attribute.
        #
        # Parses absolute octave: `"^2"` (octave 2), used for setting specific octave.
        #
        # @api private
        module AbsOctaveAttribute
          # Builds absolute octave structure.
          #
          # @return [Hash] abs_octave attribute
          #
          # @api private
          def value
            { abs_octave: capture(:number).value }
          end
        end

        # Helper module for duration calculations.
        #
        # Calculates duration from notation including dots and slashes.
        # Supports: `_2` (double), `_/2` (half), `_.` (dotted), `_..` (double dotted).
        #
        # @api private
        module DurationCalculation
          # Calculates duration value.
          #
          # @return [Rational] calculated duration
          #
          # @api private
          def duration
            base = capture(:number)&.value

            slashes = capture(:slashes)&.value || 0
            base ||= Rational(1, 2**slashes.to_r)

            dots_extension = 0
            capture(:mid_dots)&.value&.times do |i|
              dots_extension += Rational(base, 2**(i+1))
            end

            base + dots_extension
          end
        end

        # Semantic action for differential duration attribute (absolute delta).
        #
        # Parses absolute duration changes: `"+1/4"` (add quarter), `"-1/2"` (subtract half).
        #
        # @api private
        module DeltaDurationAttribute
          include DurationCalculation

          # Builds delta duration structure.
          #
          # @return [Hash] delta_duration attribute
          #
          # @api private
          def value
            sign = capture(:sign).value

            { delta_duration: sign * duration }
          end
        end

        # Semantic action for absolute duration attribute.
        #
        # Parses absolute duration: `"1/4"`, `"1"`, `"1/2.."` (double dotted).
        #
        # @api private
        module AbsDurationAttribute
          include DurationCalculation

          # Builds absolute duration structure.
          #
          # @return [Hash] abs_duration attribute
          #
          # @api private
          def value
            { abs_duration: duration }
          end
        end

        # Semantic action for factor duration attribute (multiplicative).
        #
        # Parses duration factors: `"_2"` (double), `"_/2"` (half), `"_*3"` (triple).
        # Most common duration notation in neumas.
        #
        # @api private
        module FactorDurationAttribute
          # Builds factor duration structure.
          #
          # @return [Hash] factor_duration attribute
          #
          # @api private
          def value
            { factor_duration: capture(:number).value ** (capture(:factor).value == '/' ? -1 : 1) }
          end
        end

        # Semantic action for absolute velocity attribute.
        #
        # Parses dynamics: `"pp"`, `"p"`, `"mp"`, `"mf"`, `"f"`, `"ff"`, `"fff"`.
        # Converts to numeric velocity levels.
        #
        # @api private
        module AbsVelocityAttribute
          # Builds absolute velocity structure.
          #
          # @return [Hash] abs_velocity attribute
          #
          # @api private
          def value
            if capture(:p)
              v = -capture(:p).length
            elsif capture(:mp)
              v = 0
            elsif capture(:mf)
              v = 1
            else
              v = capture(:f).length + 1
            end

            { abs_velocity: v }
          end
        end

        # Semantic action for differential velocity attribute.
        #
        # Parses relative dynamics: `"+f"` (louder), `"-p"` (softer).
        #
        # @api private
        module DeltaVelocityAttribute
          # Builds delta velocity structure.
          #
          # @return [Hash] delta_velocity attribute
          #
          # @api private
          def value
            d = capture(:delta).value
            s = capture(:sign).value

            if /p+/.match?(d)
              v = -d.length
            else
              v = d.length
            end

            { delta_velocity: s * v }
          end
        end

        # Semantic action for appogiatura (grace note).
        #
        # Parses grace note notation: `"(+1_/4)+2_"` (grace +1, then main +2).
        # Attaches grace note as modifier to main note.
        #
        # @api private
        module AppogiaturaNeuma
          # Builds neuma with appogiatura modifier.
          #
          # @return [Hash] neuma with appogiatura in modifiers
          #
          # @api private
          def value
            capture(:base).value.tap do |_|
              _[:gdvd][:modifiers] ||= {}
              _[:gdvd][:modifiers][:appogiatura] = capture(:appogiatura).value[:gdvd]
            end
          end
        end

        # Semantic action for symbol values.
        #
        # Parses symbol notation: `":symbol_name"`.
        #
        # @api private
        module Symbol
          # Builds symbol value structure.
          #
          # @return [Hash] symbol value with kind :value
          #
          # @api private
          def value
            { kind: :value,
              value: capture(:name).value.to_sym }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for string values.
        #
        # Parses string notation: `"\"text\""`.
        #
        # @api private
        module String
          # Builds string value structure.
          #
          # @return [Hash] string value with kind :value
          #
          # @api private
          def value
            { kind: :value,
              value: capture(:everything_except_double_quote).value }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for numeric values.
        #
        # Parses numbers: `42`, `3.14`, `1/2`.
        #
        # @api private
        module Number
          # Builds number value structure.
          #
          # @return [Hash] number value with kind :value
          #
          # @api private
          def value
            { kind: :value,
              value: capture(:raw_number).value }.extend Musa::Neumas::Neuma
          end
        end

        # Semantic action for special values.
        #
        # Parses special keywords: `nil`, `true`, `false`.
        #
        # @api private
        module Special
          # Builds special value structure.
          #
          # @return [Hash] special value with kind :value
          #
          # @api private
          def value
            v = captures(0)
            { kind: :value,
              value: v == 'nil' ? nil : (v == 'true' ? true : false) }.extend Musa::Neumas::Neuma
          end
        end
      end

      extend self

      # Parses Neumalang notation string or file to structured neuma objects.
      #
      # Main parsing method. Uses Citrus parser to transform text notation
      # into structured neuma series. Optionally decodes GDVD to GDV using
      # provided decoder.
      #
      # ## Parsing Process
      #
      # 1. Parse text with Citrus grammar
      # 2. Apply semantic action modules to build neuma structures
      # 3. Optionally decode GDVD events to GDV with decoder
      # 4. Return serie of neuma objects
      #
      # ## Decoder Integration
      #
      # If `decode_with` parameter provided:
      #
      # - GDVD events decoded to GDV (absolute format)
      # - Requires NeumaDecoder or compatible decoder
      # - Useful for immediate conversion to playable events
      #
      # ## Debug Mode
      #
      # If `debug: true`:
      #
      # - Dumps parse tree to stdout
      # - Shows grammar rule matches
      # - Useful for understanding parsing or debugging grammar
      #
      # @param string_or_file [String, File] neuma notation to parse
      # @param decode_with [Decoder, nil] optional decoder for GDVD→GDV conversion
      # @param debug [Boolean, nil] enable parse tree debugging output
      #
      # @return [Serie, Array] parsed neuma serie or array of neumas
      #
      # @raise [ArgumentError] if string_or_file is not String or File
      # @raise [Citrus::ParseError] if notation has syntax errors
      #
      # @example Parse simple notation
      #   neumas = Musa::Neumalang::Neumalang.parse("(0) (+2) (+2) (-1) (0)")
      #   # => Serie of GDVD neuma objects
      #
      # @example Parse with decoder (immediate GDV conversion)
      #   scale = Musa::Scales::Scales.et12[440.0].major[60]
      #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(
      #     scale,
      #     base_duration: 1/4r
      #   )
      #
      #   gdvs = Musa::Neumalang::Neumalang.parse(
      #     "(0) (+2) (+2) (-1) (0)",
      #     decode_with: decoder
      #   )
      #   # => Serie of GDV events ready for playback
      #
      # @example Parse file
      #   file = File.open("melody.neuma")
      #   neumas = Musa::Neumalang::Neumalang.parse(file)
      #
      # @example Debug parsing
      #   neumas = Musa::Neumalang::Neumalang.parse(
      #     "(0) (+2) (+2)",
      #     debug: true
      #   )
      #   # Prints parse tree to stdout
      #
      # @example Complex notation
      #   neumas = Musa::Neumalang::Neumalang.parse(
      #     "[(0) (+2 .tr) (+4 _) | (+7) (+5 .mor) (+7 _)] (+9 _2)"
      #   )
      #   # Parallel voices followed by longer note
      #
      # @api public
      def parse(string_or_file, decode_with: nil, debug: nil)
        case string_or_file
        when String
          match = Parser::Grammar::Grammar.parse string_or_file

        when File
          match = Parser::Grammar::Grammar.parse string_or_file.read

        else
          raise ArgumentError, 'Only String or File allowed to be parsed'
        end

        match.dump if debug

        serie = match.value

        if decode_with
          serie.eval do |e|
            if e[:kind] == :gdvd
              decode_with.decode(e[:gdvd])
            else
              raise ArgumentError, "Don't know how to convert #{e} to neumas"
            end
          end
        else
          serie
        end
      end

      # Parses Neumalang notation file to structured neuma objects.
      #
      # Convenience method for parsing files. Opens file and calls `parse`.
      #
      # @param filename [String] path to neuma notation file
      # @param decode_with [Decoder, nil] optional decoder for GDVD→GDV conversion
      # @param debug [Boolean, nil] enable parse tree debugging output
      #
      # @return [Serie, Array] parsed neuma serie or array
      #
      # @raise [Errno::ENOENT] if file not found
      # @raise [Citrus::ParseError] if notation has syntax errors
      #
      # @example Parse neuma file
      #   neumas = Musa::Neumalang::Neumalang.parse_file("melodies/theme.neuma")
      #
      # @example Parse with decoder
      #   scale = Musa::Scales::Scales.et12[440.0].major[60]
      #   decoder = Musa::Neumas::Decoders::NeumaDecoder.new(scale)
      #   gdvs = Musa::Neumalang::Neumalang.parse_file(
      #     "melodies/theme.neuma",
      #     decode_with: decoder
      #   )
      #
      # @api public
      def parse_file(filename, decode_with: nil, debug: nil)
        File.open filename do |file|
          parse file, decode_with: decode_with, debug: debug
        end
      end

      # Load Citrus grammar files.
      #
      # Grammars are loaded in dependency order:
      #
      # 1. terminals.citrus - Basic tokens
      # 2. datatypes.citrus - Data types
      # 3. neuma.citrus - Neuma notation
      # 4. vectors.citrus - Vector notation
      # 5. process.citrus - Process notation
      # 6. neumalang.citrus - Top-level grammar
      #
      # Grammar classes are loaded into Parser::Grammar namespace.
      #
      # @api private
      Citrus.load File.join(File.dirname(__FILE__), 'terminals.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'datatypes.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'neuma.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'vectors.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'process.citrus')
      Citrus.load File.join(File.dirname(__FILE__), 'neumalang.citrus')
    end
  end
end
