require_relative '../../core-ext/with'

require_relative 'note-complexities'
require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        class Notation
          include Helper::ToXML

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

        class Note
          extend Musa::Extension::AttributeBuilder
          include Musa::Extension::With

          include Helper
          include ToXML

          def initialize(*_rest,
                         pizzicato: nil,  # true
                         # main content
                         grace: nil, # true
                         cue: nil, # true
                         chord: nil, # true
                         duration: nil, # number positive divisions
                         tie_start: nil, tie_stop: nil, # true
                         voice: nil, # number
                         type: nil, # whole / half / quarter / ...
                         dots: nil, # number
                         accidental: nil, # sharp / flat / ...
                         time_modification: nil, # TimeModification class instance
                         stem: nil, # up / down / double
                         notehead: nil, # Notehead class instance
                         staff: nil, # number

                         # notations
                         accidental_mark: nil, # sharp / natural / flat / ...
                         arpeggiate: nil, # true / up / down

                         tied: nil, # start / stop / continue
                         tuplet: nil, # Tuplet class instance

                         dynamics: nil, # pppp...ffff (single or array of)
                         fermata: nil, # true / upright / inverted
                         glissando: nil, # start / stop
                         non_arpeggiate: nil, # top / bottom

                         slide: nil, # start / stop
                         slur: nil, # start / stop / continue | { type: start/stop/continue, [**other_attributes: other_values] }

                         ## articulations
                         accent: nil, # true
                         breath_mark: nil, # true / comma / tick
                         caesura: nil, # true
                         detached_legato: nil, # true
                         doit: nil, # true
                         falloff: nil, # true
                         other_articulation: nil, # text
                         plop: nil, # true
                         scoop: nil, # true
                         spiccato: nil, # true
                         staccatissimo: nil, # true
                         staccato: nil, # true
                         stress: nil, # true
                         strong_accent: nil, # true / up / down
                         tenuto: nil, # true
                         unstress: nil, # true

                         ## ornaments
                         delayed_inverted_turn: nil, # true
                         delayed_turn: nil, # true
                         inverted_mordent: nil, # true
                         inverted_turn: nil, # true
                         mordent: nil, # true
                         schleifer: nil, # true
                         shake: nil, # true
                         tremolo: nil, # start / stop / single,
                         trill_mark: nil, # true
                         turn: nil, # true
                         vertical_turn: nil, # true
                         wavy_line: nil, # true
                         other_ornament: nil, # true
                         ornament_accidental_mark: nil, # sharp / natural / flat / ...

                         ## technical
                         arrow: nil, # Arrow class instance
                         bend: nil, # Bend class instance
                         double_tongue: nil, # true
                         down_bow: nil, # true
                         fingering: nil,  # Fingering class instance
                         fingernails: nil, # true
                         fret: nil, # number
                         hammer_on: nil, # start / stop
                         handbell: nil, # damp / echo / ...
                         harmonic: nil, # Harmonic class instance
                         heel: nil, # true
                         hole: nil, # Hole class instance
                         open_string: nil, # true
                         other_technical: nil, # text
                         pluck: nil, # text
                         pull_off: nil, # start / stop
                         snap_pizzicato: nil, # true
                         stopped: nil, # true
                         string: nil, # number (string number)
                         tap: nil, # text
                         thumb_position: nil, # true
                         toe: nil, # true
                         triple_tongue: nil, # true
                         up_bow: nil, # true
                         **_keyrest,
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

          def specific_to_xml(io, indent:); end

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