require_relative '../../core-ext/with'

require_relative 'note-complexities'
require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Notation element helper.
        #
        # Private helper class for creating MusicXML notation elements with
        # type attributes and optional content. Used internally for elements
        # like slurs, which can be simple (type: 'start'/'stop') or complex
        # (with additional attributes like placement, bezier curves, etc.).
        #
        # @api private
        class Notation
          include Helper::ToXML

          # Creates a Notation from various input formats.
          #
          # @param tag [String] XML element tag name
          # @param value_or_attributes [Symbol, String, Hash, nil] type value or hash of attributes
          # @param true_value [String, nil] value to use when type is true
          # @param false_value [String, nil] value to use when type is false
          # @return [Notation, nil]
          #
          # @api private
          def self.create(tag, value_or_attributes, true_value = nil, false_value = nil)
            case value_or_attributes
            when Hash
              value_or_attributes = value_or_attributes.clone

              type = value_or_attributes.delete :type
              content = value_or_attributes.delete :content

              Notation.new(tag, type, content, true_value, false_value, **value_or_attributes)

            when NilClass
              nil

            else
              Notation.new(tag, value_or_attributes)
            end
          end

          # Creates a notation element.
          #
          # @param tag [String] XML element tag name
          # @param type [Symbol, String, Boolean] type attribute value
          # @param content [String, nil] element text content
          # @param true_value [String, nil] value to use when type is true
          # @param false_value [String, nil] value to use when type is false
          # @param attributes [Hash] additional XML attributes
          #
          # @api private
          def initialize(tag, type, content = nil, true_value = nil, false_value = nil, **attributes)
            @tag = tag

            if type == true && true_value
              @type = true_value
            elsif type == false && false_value
              @type = false_value
            else
              @type = type
            end

            @content = content
            @attributes = attributes
          end

          # Generates the notation XML element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.print "#{tabs}\t<#{ @tag } "

            io.print "type=\"#{@type}\""

            @attributes.each_pair do |name, value|
              io.print " #{name}=\"#{value}\""
            end

            if @content
              io.puts ">#{@content}</#{ @tag }>"
            else
              io.puts "/>"
            end
          end
        end

        private_constant :Notation

        # Abstract base class for all note types.
        #
        # Note is the foundation for pitched notes, rests, and unpitched percussion notes.
        # It provides comprehensive support for musical notation including:
        #
        # ## Core Note Properties
        # - **Duration and Type**: Timing (duration in divisions, type: whole/half/quarter/etc.)
        # - **Voice and Staff**: Multi-voice and multi-staff support
        # - **Dots**: Dotted and double-dotted notes
        # - **Grace Notes**: Ornamental notes without duration
        # - **Cue Notes**: Smaller notes for reference
        # - **Chords**: Notes that sound simultaneously
        #
        # ## Notations
        # The `<notations>` element groups musical symbols attached to notes:
        #
        # ### Basic Notations
        # - **Ties/Tied**: Visual ties connecting notes (tie) vs sustained sound (tied)
        # - **Slurs**: Phrase markings
        # - **Tuplets**: Irregular rhythmic groupings (triplets, quintuplets, etc.)
        # - **Dynamics**: Volume markings (pp, p, mp, mf, f, ff, etc.)
        # - **Fermata**: Pause/hold symbols
        # - **Accidental Marks**: Sharp, flat, natural annotations
        # - **Arpeggiate**: Rolled chord indication
        # - **Glissando/Slide**: Pitch glide
        #
        # ### Articulations
        # Attack and release characteristics:
        # - **accent**: Emphasis (>)
        # - **staccato**: Short, detached (•)
        # - **tenuto**: Full value (−)
        # - **staccatissimo**: Very short (▼)
        # - **spiccato**: Bouncing bow
        # - **strong_accent**: Forceful (^)
        # - **detached_legato**: Portato
        # - **breath_mark**: Breath pause
        # - **caesura**: Railroad tracks (caesura)
        # - Plus: doit, falloff, plop, scoop, stress, unstress
        #
        # ### Ornaments
        # Melodic decorations:
        # - **trill_mark**: Rapid alternation with upper neighbor
        # - **mordent**: Single alternation with lower neighbor
        # - **inverted_mordent**: Single alternation with upper neighbor
        # - **turn**: Four-note figure around main note
        # - **inverted_turn**: Inverted turn figure
        # - **delayed_turn**: Turn after main note
        # - **shake**: Extended trill
        # - **tremolo**: Rapid repetition (single) or alternation (start/stop)
        # - **schleifer**: Slide ornament
        # - **wavy_line**: Trill extension
        #
        # ### Technical Markings
        # Performance technique indicators:
        #
        # **String Instruments**:
        # - **fingering**: Finger numbers
        # - **up_bow/down_bow**: Bowing direction (↑/↓)
        # - **harmonic**: Natural or artificial harmonics
        # - **open_string**: Open string indication (○)
        # - **stopped**: Stopped note (+)
        # - **snap_pizzicato**: Bartók pizzicato
        # - **thumb_position**: Cello thumb position
        # - **string**: String number
        # - **hammer_on/pull_off**: Legato technique
        #
        # **Wind Instruments**:
        # - **double_tongue/triple_tongue**: Tonguing technique
        # - **fingernails**: Use fingernails
        # - **hole**: Woodwind fingering holes
        #
        # **Guitar/Fretted**:
        # - **fret**: Fret number
        # - **bend**: String bend
        # - **tap**: Tapping technique
        # - **pluck**: Plucking style
        #
        # **Other**:
        # - **arrow**: Directional arrow
        # - **handbell**: Handbell technique (damp, echo, gyro, etc.)
        # - **heel/toe**: Organ pedal technique
        #
        # ## Hierarchy
        #
        # Note is an abstract base class with three concrete subclasses:
        # - {PitchedNote}: Notes with specific pitch (step, octave, alteration)
        # - {Rest}: Silences with duration
        # - {UnpitchedNote}: Percussion notes without specific pitch
        #
        # ## Usage
        #
        # Note is not used directly—use {PitchedNote}, {Rest}, or {UnpitchedNote}.
        # Notes are typically added via {Measure} convenience methods:
        # - {Measure#add_pitch} / {Measure#pitch}
        # - {Measure#add_rest} / {Measure#rest}
        # - {Measure#add_unpitched} / {Measure#unpitched}
        #
        # @abstract Subclass and override {#specific_to_xml} to implement.
        # @see PitchedNote Pitched notes with step/octave
        # @see Rest Rests and measure rests
        # @see UnpitchedNote Unpitched percussion
        # @see Measure Container for notes
        class Note
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper
          include ToXML

          # Creates a note (abstract base constructor).
          #
          # This constructor is called by subclasses ({PitchedNote}, {Rest}, {UnpitchedNote}).
          # The extensive parameter list supports all MusicXML notation features.
          #
          # ## Parameter Categories
          #
          # ### Core Note Properties
          # @param grace [Boolean, nil] grace note (ornamental, no time value)
          # @param cue [Boolean, nil] cue note (smaller, reference indication)
          # @param chord [Boolean, nil] note is part of a chord (sounds with previous note)
          # @param duration [Integer, nil] duration in division units
          # @param type [String, nil] note type: 'whole', 'half', 'quarter', 'eighth', '16th', etc.
          # @param dots [Integer, nil] number of augmentation dots (1 or 2)
          # @param voice [Integer, nil] voice number for polyphonic music
          # @param staff [Integer, nil] staff number for multi-staff instruments
          # @param tie_start [Boolean, nil] start a tie to next note
          # @param tie_stop [Boolean, nil] stop a tie from previous note
          # @param accidental [String, nil] visual accidental: 'sharp', 'flat', 'natural', etc.
          # @param stem [String, nil] stem direction: 'up', 'down', 'double', 'none'
          # @param pizzicato [Boolean, nil] pizzicato attribute on note element
          #
          # ### Rhythm Modification
          # @param time_modification [TimeModification, Hash, nil] tuplet ratio (e.g., 3:2 for triplets)
          # @param notehead [Notehead, Hash, nil] notehead style and properties
          #
          # ### Basic Notations
          # @param tied [String, nil] tied notation: 'start', 'stop', 'continue'
          # @param tuplet [Tuplet, Hash, nil] tuplet bracket/number notation
          # @param slur [String, Hash, nil] slur: 'start', 'stop', 'continue' or hash with attributes
          # @param dynamics [String, Array<String>, nil] dynamics: 'pp', 'p', 'mp', 'mf', 'f', 'ff', etc.
          # @param fermata [Boolean, String, nil] fermata: true, 'upright', 'inverted'
          # @param accidental_mark [String, nil] accidental in notations: 'sharp', 'flat', 'natural'
          # @param arpeggiate [Boolean, String, nil] arpeggio: true, 'up', 'down'
          # @param non_arpeggiate [String, nil] non-arpeggio: 'top', 'bottom'
          # @param glissando [String, nil] glissando: 'start', 'stop'
          # @param slide [String, nil] slide: 'start', 'stop'
          #
          # ### Articulations
          # @param accent [Boolean, nil] accent mark (>)
          # @param staccato [Boolean, nil] staccato (•)
          # @param tenuto [Boolean, nil] tenuto (−)
          # @param staccatissimo [Boolean, nil] staccatissimo (▼)
          # @param spiccato [Boolean, nil] spiccato
          # @param strong_accent [Boolean, String, nil] strong accent (^): true, 'up', 'down'
          # @param detached_legato [Boolean, nil] detached legato (portato)
          # @param breath_mark [Boolean, String, nil] breath mark: true, 'comma', 'tick'
          # @param caesura [Boolean, nil] caesura (railroad tracks)
          # @param doit [Boolean, nil] doit
          # @param falloff [Boolean, nil] falloff
          # @param plop [Boolean, nil] plop
          # @param scoop [Boolean, nil] scoop
          # @param stress [Boolean, nil] stress
          # @param unstress [Boolean, nil] unstress
          # @param other_articulation [String, nil] custom articulation text
          #
          # ### Ornaments
          # @param trill_mark [Boolean, nil] trill
          # @param mordent [Boolean, nil] mordent (lower neighbor)
          # @param inverted_mordent [Boolean, nil] inverted mordent (upper neighbor)
          # @param turn [Boolean, nil] turn
          # @param inverted_turn [Boolean, nil] inverted turn
          # @param delayed_turn [Boolean, nil] delayed turn
          # @param delayed_inverted_turn [Boolean, nil] delayed inverted turn
          # @param shake [Boolean, nil] shake
          # @param tremolo [String, nil] tremolo: 'single', 'start', 'stop'
          # @param schleifer [Boolean, nil] schleifer
          # @param wavy_line [Boolean, nil] wavy line (trill extension)
          # @param vertical_turn [Boolean, nil] vertical turn
          # @param other_ornament [Boolean, nil] custom ornament
          # @param ornament_accidental_mark [String, nil] ornament accidental: 'sharp', 'flat', 'natural'
          #
          # ### String Technique
          # @param fingering [Fingering, Hash, nil] fingering indication
          # @param up_bow [Boolean, nil] up bow (↑)
          # @param down_bow [Boolean, nil] down bow (↓)
          # @param harmonic [Harmonic, Hash, nil] harmonic
          # @param open_string [Boolean, nil] open string (○)
          # @param stopped [Boolean, nil] stopped note (+)
          # @param snap_pizzicato [Boolean, nil] Bartók pizzicato
          # @param thumb_position [Boolean, nil] cello thumb position
          # @param string [Integer, nil] string number
          # @param hammer_on [String, nil] hammer-on: 'start', 'stop'
          # @param pull_off [String, nil] pull-off: 'start', 'stop'
          #
          # ### Wind Technique
          # @param double_tongue [Boolean, nil] double tonguing
          # @param triple_tongue [Boolean, nil] triple tonguing
          # @param fingernails [Boolean, nil] use fingernails
          # @param hole [Hole, Hash, nil] woodwind fingering hole
          #
          # ### Fretted Instrument Technique
          # @param fret [Integer, nil] fret number
          # @param bend [Bend, Hash, nil] string bend
          # @param tap [String, nil] tapping
          # @param pluck [String, nil] plucking technique
          #
          # ### Other Technical
          # @param arrow [Arrow, Hash, nil] arrow indication
          # @param handbell [String, nil] handbell technique: 'damp', 'echo', 'gyro', etc.
          # @param heel [Boolean, nil] heel (organ pedal)
          # @param toe [Boolean, nil] toe (organ pedal)
          # @param other_technical [String, nil] custom technical text
          #
          # @yield Optional DSL block for setting properties
          #
          # @example Basic quarter note with staccato
          #   PitchedNote.new('C', octave: 4, duration: 2, type: 'quarter', staccato: true)
          #
          # @example Dotted eighth with slur start
          #   PitchedNote.new('D', octave: 5, duration: 3, type: 'eighth', dots: 1, slur: 'start')
          #
          # @example Grace note with accent
          #   PitchedNote.new('E', octave: 5, grace: true, type: 'eighth', accent: true)
          #
          # @example Multi-voice with fermata
          #   PitchedNote.new('G', octave: 4, duration: 4, type: 'half', voice: 2, fermata: true)
          #
          # For detailed parameter documentation, see {NoteComplexities::PARAMETERS}
          #
          # @api private (called by subclasses)
          def initialize(*rest_args,
                         pizzicato: nil,
                         grace: nil, cue: nil, chord: nil,
                         duration: nil, tie_start: nil, tie_stop: nil,
                         voice: nil, type: nil, dots: nil,
                         accidental: nil, time_modification: nil,
                         stem: nil, notehead: nil, staff: nil,
                         accidental_mark: nil, arpeggiate: nil,
                         tied: nil, tuplet: nil,
                         dynamics: nil, fermata: nil, glissando: nil, non_arpeggiate: nil,
                         slide: nil, slur: nil,
                         accent: nil, breath_mark: nil, caesura: nil,
                         detached_legato: nil, doit: nil, falloff: nil,
                         other_articulation: nil, plop: nil, scoop: nil,
                         spiccato: nil, staccatissimo: nil, staccato: nil,
                         stress: nil, strong_accent: nil, tenuto: nil, unstress: nil,
                         delayed_inverted_turn: nil, delayed_turn: nil,
                         inverted_mordent: nil, inverted_turn: nil,
                         mordent: nil, schleifer: nil, shake: nil,
                         tremolo: nil, trill_mark: nil, turn: nil,
                         vertical_turn: nil, wavy_line: nil,
                         other_ornament: nil, ornament_accidental_mark: nil,
                         arrow: nil, bend: nil, double_tongue: nil, down_bow: nil,
                         fingering: nil, fingernails: nil, fret: nil,
                         hammer_on: nil, handbell: nil, harmonic: nil,
                         heel: nil, hole: nil, open_string: nil,
                         other_technical: nil, pluck: nil, pull_off: nil,
                         snap_pizzicato: nil, stopped: nil, string: nil,
                         tap: nil, thumb_position: nil, toe: nil,
                         triple_tongue: nil, up_bow: nil,
                         **keyrest_args,
                         &block)

            @tuplets = []

            @pizzicato = pizzicato

            @grace = grace
            @cue = cue
            @chord = chord
            @duration = duration
            @tie_start = tie_start
            @tie_stop = tie_stop
            @voice = voice
            @type = type
            @dots = dots
            @accidental = accidental
            @time_modification = make_instance_if_needed(TimeModification, time_modification)
            @stem = stem
            @notehead = make_instance_if_needed(Notehead, notehead)
            @staff = staff

            # notations
            @accidental_mark = accidental_mark
            @arpeggiate = arpeggiate
            @tied = tied
            @tuplets << make_instance_if_needed(Tuplet, tuplet) if tuplet
            @dynamics = dynamics
            @fermata = fermata
            @glissando = glissando
            @non_arpeggiate = non_arpeggiate
            @slide = slide
            @slur = Notation.create('slur', slur)

            ## articulations
            @accent = accent
            @breath_mark = breath_mark
            @caesura = caesura
            @detached_legato = detached_legato
            @doit = doit
            @falloff = falloff
            @other_articulation = other_articulation
            @plop = plop
            @scoop = scoop
            @spiccato = spiccato
            @staccatissimo = staccatissimo
            @staccato = staccato
            @stress = stress
            @strong_accent = strong_accent
            @tenuto = tenuto
            @unstress = unstress

            ## ornaments
            @delayed_inverted_turn = delayed_inverted_turn
            @delayed_turn = delayed_turn
            @inverted_mordent = inverted_mordent
            @inverted_turn = inverted_turn
            @mordent = mordent
            @schleifer = schleifer
            @shake = shake
            @tremolo = tremolo
            @trill_mark = trill_mark
            @turn = turn
            @vertical_turn = vertical_turn
            @wavy_line = wavy_line
            @other_ornament = other_ornament
            @ornament_accidental_mark = ornament_accidental_mark

            ## technical
            @arrow = make_instance_if_needed(Arrow, arrow)
            @bend = make_instance_if_needed(Bend, bend)
            @double_tongue = double_tongue
            @down_bow = down_bow
            @fingering = make_instance_if_needed(Fingering, fingering)
            @fingernails = fingernails
            @fret = fret
            @hammer_on = hammer_on
            @handbell = handbell
            @harmonic = make_instance_if_needed(Harmonic, harmonic)
            @heel = heel
            @hole = make_instance_if_needed(Hole, hole)
            @open_string = open_string
            @other_technical = other_technical
            @pluck = pluck
            @pull_off = pull_off
            @snap_pizzicato = snap_pizzicato
            @stopped = stopped
            @string = string
            @tap_ = tap
            @thumb_position = thumb_position
            @toe = toe
            @triple_tongue = triple_tongue
            @up_bow = up_bow

            with &block if block_given?
          end

          attr_simple_builder :pizzicato
          attr_simple_builder :grace
          attr_simple_builder :cue
          attr_simple_builder :chord

          attr_simple_builder :duration
          attr_simple_builder :tie_start
          attr_simple_builder :tie_stop
          attr_simple_builder :type
          attr_simple_builder :dots
          attr_simple_builder :accidental
          attr_simple_builder :stem
          attr_simple_builder :notehead
          attr_simple_builder :voice
          attr_simple_builder :staff

          attr_complex_builder :time_modification, TimeModification

          # notations
          attr_simple_builder :accidental_mark
          attr_simple_builder :arpeggiate
          attr_simple_builder :tied
          attr_simple_builder :dynamics
          attr_simple_builder :fermata
          attr_simple_builder :glissando
          attr_simple_builder :non_arpeggiate
          attr_simple_builder :slide

          attr_complex_adder_to_custom :tuplet do | *parameters, **key_parameters |
            Tuplet.new(*parameters, **key_parameters).tap { |tuplet| @tuplets << tuplet }
          end

          attr_complex_builder :slur, Notation, first_parameter: 'slur'

          ## articulations
          attr_simple_builder :accent
          attr_simple_builder :breath_mark
          attr_simple_builder :caesura
          attr_simple_builder :detached_legato
          attr_simple_builder :doit
          attr_simple_builder :falloff
          attr_simple_builder :other_articulation
          attr_simple_builder :plop
          attr_simple_builder :scoop
          attr_simple_builder :spiccato
          attr_simple_builder :staccatissimo
          attr_simple_builder :staccato
          attr_simple_builder :stress
          attr_simple_builder :strong_accent
          attr_simple_builder :tenuto
          attr_simple_builder :unstress

          ## ornaments
          attr_simple_builder :delayed_inverted_turn
          attr_simple_builder :delayed_turn
          attr_simple_builder :inverted_mordent
          attr_simple_builder :inverted_turn
          attr_simple_builder :mordent
          attr_simple_builder :schleifer
          attr_simple_builder :shake
          attr_simple_builder :tremolo
          attr_simple_builder :trill_mark
          attr_simple_builder :turn
          attr_simple_builder :vertical_turn
          attr_simple_builder :wavy_line
          attr_simple_builder :other_ornament
          attr_simple_builder :ornament_accidental_mark

          ## technical
          attr_simple_builder :arrow
          attr_simple_builder :bend
          attr_simple_builder :double_tongue
          attr_simple_builder :down_bow
          attr_simple_builder :fingering
          attr_simple_builder :fingernails
          attr_simple_builder :fret
          attr_simple_builder :hammer_on
          attr_simple_builder :handbell
          attr_simple_builder :harmonic
          attr_simple_builder :heel
          attr_simple_builder :hole
          attr_simple_builder :open_string
          attr_simple_builder :other_technical
          attr_simple_builder :pluck
          attr_simple_builder :pull_off
          attr_simple_builder :snap_pizzicato
          attr_simple_builder :stopped
          attr_simple_builder :string
          attr_simple_builder :tap_
          attr_simple_builder :thumb_position
          attr_simple_builder :toe
          attr_simple_builder :triple_tongue
          attr_simple_builder :up_bow

          # Generates the note XML element.
          #
          # Outputs a complete `<note>` element with all sub-elements in MusicXML order:
          # grace, cue, chord, pitch/rest/unpitched, duration, tie, voice, type, dots,
          # accidental, time_modification, stem, notehead, staff, notations.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<note#{" pizzicato=\"yes\"" if @pizzicato}>"

            io.puts "#{tabs}\t<grace />" if @grace
            io.puts "#{tabs}\t<cue />" if @cue
            io.puts "#{tabs}\t<chord />" if @chord

            specific_to_xml(io, indent: indent + 1)

            io.puts "#{tabs}\t<duration>#{@duration}</duration>"

            io.puts "#{tabs}\t<tie type=\"stop\"/>" if @tie_stop
            io.puts "#{tabs}\t<tie type=\"start\"/>" if @tie_start

            io.puts "#{tabs}\t<voice>#{@voice}</voice>" if @voice

            io.puts "#{tabs}\t<type>#{@type}</type>"

            dots&.times do
              io.puts "#{tabs}\t<dot />"
            end

            io.puts "#{tabs}\t<accidental>#{@accidental}</accidental>" if @accidental

            @time_modification&.to_xml(io, indent: indent + 1)

            io.puts "#{tabs}\t<stem>#{@stem}</stem>" if @stem

            @notehead&.to_xml(io, indent: indent + 1)

            io.puts "#{tabs}\t<staff>#{@staff.to_i}</staff>" if @staff

            if _notations
              io.puts "#{tabs}\t<notations>"
              io.puts "#{tabs}\t\t<accidental-mark>#{@accidental_mark}</accidental-mark>" if @accidental_mark
              io.puts "#{tabs}\t\t<arpeggiate#{ decode_bool_or_string_attribute(@arpeggiate, 'direction') }/>" if @arpeggiate
              io.puts "#{tabs}\t\t<tied type=\"#{@tied}\"/>" if @tied
              @tuplets.each do |tuplet|
                tuplet.to_xml(io, indent: indent + 3)
              end

              if @dynamics
                io.puts "#{tabs}\t\t<dynamics>"
                @dynamics.arrayfy.each do |dynamics|
                  io.puts "#{tabs}\t\t\t<#{dynamics} />"
                end
                io.puts "#{tabs}\t\t</dynamics>"
              end

              io.puts "#{tabs}\t\t<fermata#{ decode_bool_or_string_attribute(@fermata, 'type') }/>" if @fermata
              io.puts "#{tabs}\t\t<glissando type=\"#{@glissando}\"/>" if @glissando
              io.puts "#{tabs}\t\t<non-arpeggiate type=\"#{@non_arpeggiate}\"/>" if @non_arpeggiate
              io.puts "#{tabs}\t\t<slide type=\"#{@slide}\"/>" if @slide
              @slur&.to_xml(io, indent: indent + 1)

              if _articulations
                io.puts "#{tabs}\t\t<articulations>"

                io.puts "#{tabs}\t\t\t<accent />" if @accent
                io.puts "#{tabs}\t\t\t<breath-mark>#{decode_bool_or_string_value(@breath_mark)}</breath-mark>" if @breath_mark
                io.puts "#{tabs}\t\t\t<caesura />" if @caesura
                io.puts "#{tabs}\t\t\t<detached-legato />" if @detached_legato
                io.puts "#{tabs}\t\t\t<doit />" if @doit
                io.puts "#{tabs}\t\t\t<falloff />" if @falloff
                io.puts "#{tabs}\t\t\t<other-articulation>#{decode_bool_or_string_value(@other_articulation)}</other-articulation>" if @other_articulation
                io.puts "#{tabs}\t\t\t<plop />" if @plop
                io.puts "#{tabs}\t\t\t<scoop />" if @scoop
                io.puts "#{tabs}\t\t\t<spiccato />" if @spiccato
                io.puts "#{tabs}\t\t\t<staccatissimo />" if @staccatissimo
                io.puts "#{tabs}\t\t\t<staccato />" if @staccato
                io.puts "#{tabs}\t\t\t<stress />" if @stress
                io.puts "#{tabs}\t\t\t<strong-accent#{ decode_bool_or_string_attribute(@strong_accent, 'type') }/>" if @strong_accent
                io.puts "#{tabs}\t\t\t<tenuto />" if @tenuto
                io.puts "#{tabs}\t\t\t<unstress />" if @unstress

                io.puts "#{tabs}\t\t</articulations>"
              end

              if _ornaments
                io.puts "#{tabs}\t\t<ornaments>"

                io.puts "#{tabs}\t\t\t<delayed-inverted-turn />" if @delayed_inverted_turn
                io.puts "#{tabs}\t\t\t<delayed-turn />" if @delayed_turn
                io.puts "#{tabs}\t\t\t<inverted-mordent />" if @inverted_mordent
                io.puts "#{tabs}\t\t\t<inverted-turn />" if @inverted_turn
                io.puts "#{tabs}\t\t\t<mordent />" if @mordent
                io.puts "#{tabs}\t\t\t<other-ornament>#{decode_bool_or_string_value(@other_ornament)}</other-ornament>" if @other_ornament
                io.puts "#{tabs}\t\t\t<schleifer />" if @schleifer
                io.puts "#{tabs}\t\t\t<shake />" if @shake
                io.puts "#{tabs}\t\t\t<tremolo#{ decode_bool_or_string_attribute(@tremolo, 'type') }/>" if @tremolo
                io.puts "#{tabs}\t\t\t<trill-mark />" if @trill_mark
                io.puts "#{tabs}\t\t\t<turn />" if @turn
                io.puts "#{tabs}\t\t\t<wavy-line#{ decode_bool_or_string_attribute(@wavy_line, 'type') }/>" if @wavy_line
                io.puts "#{tabs}\t\t\t<accidental-mark>#{@ornament_accidental_mark}</accidental-mark>" if @ornament_accidental_mark

                io.puts "#{tabs}\t\t</ornaments>"
              end

              if _technical
                io.puts "#{tabs}\t\t<technical>"

                @arrow&.to_xml(io, indent: indent + 3)
                @bend&.to_xml(io, indent: indent + 3)
                io.puts "#{tabs}\t\t\t<double-tongue />" if @double_tongue
                io.puts "#{tabs}\t\t\t<down-bow />" if @down_bow
                @fingering&.to_xml(io, indent: indent + 3)
                io.puts "#{tabs}\t\t\t<fingernails />" if @fingernails
                io.puts "#{tabs}\t\t\t<fret>#{@fret}</fret>" if @fret
                io.puts "#{tabs}\t\t\t<hammer-on>#{@hammer_on}</hammer-on>" if @hammer_on
                io.puts "#{tabs}\t\t\t<handbell>#{@handbell}</handbell>" if @handbell
                @harmonic&.to_xml(io, indent: indent + 3)
                io.puts "#{tabs}\t\t\t<heel />" if @heel
                @hole&.to_xml(io, indent: indent + 3)
                io.puts "#{tabs}\t\t\t<open-string />" if @open_string
                io.puts "#{tabs}\t\t\t<other-technical>#{@other_technical}</other-technical>" if @other_technical
                io.puts "#{tabs}\t\t\t<pluck>#{@pluck}</pluck>" if @pluck
                io.puts "#{tabs}\t\t\t<pull-off>#{@pull_off}</pull-off>" if @pull_off
                io.puts "#{tabs}\t\t\t<snap-pizzicato />" if @snap_pizzicato
                io.puts "#{tabs}\t\t\t<stopped />" if @stopped
                io.puts "#{tabs}\t\t\t<string>#{@string}</string>" if @string
                io.puts "#{tabs}\t\t\t<tap>#{@tap_}</tap>" if @tap_
                io.puts "#{tabs}\t\t\t<thumb-position />" if @thumb_position
                io.puts "#{tabs}\t\t\t<toe />" if @toe
                io.puts "#{tabs}\t\t\t<triple-tongue />" if @triple_tongue
                io.puts "#{tabs}\t\t\t<up-bow />" if @up_bow

                io.puts "#{tabs}\t\t</technical>"
              end

              io.puts "#{tabs}\t</notations>"
            end

            io.puts "#{tabs}</note>"
          end

          private

          # Outputs note-type-specific XML content.
          #
          # Abstract method overridden by subclasses to output pitch, rest, or unpitched elements.
          # Called during XML generation between chord and duration elements.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @return [void]
          #
          # @abstract Subclasses must implement this method
          # @api private
          def specific_to_xml(io, indent:); end

          # Checks if any notation elements are present.
          #
          # @return [Boolean] true if any notations should be output
          # @api private
          def _notations
            @accidental_mark ||
                @arpeggiate ||
                @tied ||
                !@tuplets.empty? ||
                @dynamics ||
                @fermata ||
                @glissando ||
                @non_arpeggiate ||
                @slide ||
                @slur ||
                _articulations ||
                _ornaments ||
                _technical
          end

          def _articulations
            @accent ||
                @breath_mark ||
                @caesura ||
                @detached_legato ||
                @doit ||
                @falloff ||
                @other_articulation ||
                @plop ||
                @scoop ||
                @spiccato ||
                @staccatissimo ||
                @staccato ||
                @stress ||
                @strong_accent ||
                @tenuto ||
                @unstress
          end

          def _ornaments
            @delayed_inverted_turn ||
                @delayed_turn ||
                @inverted_mordent ||
                @inverted_turn ||
                @mordent ||
                @schleifer ||
                @shake ||
                @tremolo ||
                @trill_mark ||
                @turn ||
                @vertical_turn ||
                @wavy_line ||
                @other_ornament ||
                @ornament_accidental_mark
          end

          def _technical
            @arrow ||
                @bend ||
                @double_tongue ||
                @down_bow ||
                @fingering ||
                @fingernails ||
                @fret ||
                @hammer_on ||
                @handbell ||
                @harmonic ||
                @heel ||
                @hole ||
                @open_string ||
                @other_technical ||
                @pluck ||
                @pull_off ||
                @snap_pizzicato ||
                @stopped ||
                @string ||
                @tap_ ||
                @thumb_position ||
                @toe ||
                @triple_tongue ||
                @up_bow
          end
        end

        private_constant :Note
      end
    end
  end
end