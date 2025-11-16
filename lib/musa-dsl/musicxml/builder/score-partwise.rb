require 'date'

require_relative '../../core-ext/attribute-builder'
require_relative '../../core-ext/with'

require_relative 'typed-text'
require_relative 'part-group'
require_relative 'part'

require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      # Main entry point for creating MusicXML scores.
      #
      # ScorePartwise represents the root `<score-partwise>` element of a MusicXML 3.0
      # document. It contains metadata (work info, creators, rights), part definitions,
      # and the actual musical content organized by parts and measures.
      #
      # ## Structure
      #
      # A ScorePartwise document contains:
      #
      # - **Metadata**: work title/number, movement title/number, creators, rights
      # - **Part List**: part and part-group declarations with names/abbreviations
      # - **Parts**: actual musical content (measures with notes, dynamics, etc.)
      #
      # ## Usage Patterns
      #
      # ### Constructor Style
      #
      # Set properties via constructor parameters and use `add_*` methods:
      #
      #     score = ScorePartwise.new(
      #       work_title: "Symphony No. 1",
      #       creators: { composer: "Composer Name" }
      #     )
      #     part = score.add_part(:p1, name: "Violin")
      #     measure = part.add_measure(divisions: 2)
      #
      # ### DSL Style
      #
      # Use blocks with method names as setters/builders:
      #
      #     score = ScorePartwise.new do
      #       work_title "Symphony No. 1"
      #       creators composer: "Composer Name"
      #       part :p1, name: "Violin" do
      #         measure do
      #           # measure content
      #         end
      #       end
      #     end
      #
      # ## Part Groups
      #
      # Parts can be organized into groups (for orchestral sections, etc.):
      #
      #     score.add_group 1, type: 'start', name: "Strings"
      #     score.add_part :p1, name: "Violin I"
      #     score.add_part :p2, name: "Violin II"
      #     score.add_group 1, type: 'stop'
      #
      # ## XML Output
      #
      # Generate MusicXML 3.0 compliant XML:
      #
      #     File.open('score.xml', 'w') do |f|
      #       score.to_xml(f)
      #     end
      #
      #     # Or get as string:
      #     xml_string = score.to_xml.string
      #
      # @example Complete score with two parts
      #   score = ScorePartwise.new do
      #     work_title "Duet"
      #     creators composer: "J. Composer"
      #     encoding_date DateTime.new(2024, 1, 1)
      #
      #     part :p1, name: "Flute" do
      #       measure do
      #         attributes do
      #           divisions 4
      #           key fifths: 1  # G major
      #           time beats: 3, beat_type: 4
      #           clef sign: 'G', line: 2
      #         end
      #         pitch 'G', octave: 4, duration: 4, type: 'quarter'
      #         pitch 'A', octave: 4, duration: 4, type: 'quarter'
      #         pitch 'B', octave: 4, duration: 4, type: 'quarter'
      #       end
      #     end
      #
      #     part :p2, name: "Piano" do
      #       measure do
      #         attributes do
      #           divisions 4
      #           key fifths: 1
      #           time beats: 3, beat_type: 4
      #           clef sign: 'G', line: 2
      #         end
      #         pitch 'D', octave: 4, duration: 12, type: 'half', dots: 1
      #       end
      #     end
      #   end
      #
      # @see Internal::Part Part implementation
      # @see Internal::PartGroup Part grouping
      # @see Internal::Measure Measure implementation
      class ScorePartwise
        extend Musa::Extension::AttributeBuilder
        include Musa::Extension::With

        include Internal::Helper::ToXML

        # Creates a new MusicXML score.
        #
        # @param work_number [Integer, nil] opus or catalog number
        # @param work_title [String, nil] title of the work
        # @param movement_number [Integer, String, nil] movement number
        # @param movement_title [String, nil] movement title
        # @param encoding_date [DateTime, nil] encoding date (default: now)
        # @param creators [Hash{Symbol => String}, nil] creators by type (e.g., composer: "Name")
        # @param rights [Hash{Symbol => String}, nil] rights by type (e.g., lyrics: "Name")
        # @yield Optional DSL block for building score structure
        #
        # @example With metadata in constructor
        #   ScorePartwise.new(
        #     work_title: "Sonata in C",
        #     work_number: 1,
        #     movement_title: "Allegro",
        #     creators: { composer: "Mozart", arranger: "Smith" },
        #     rights: { lyrics: "Public Domain" }
        #   )
        #
        # @example With DSL block
        #   ScorePartwise.new do
        #     work_title "Sonata in C"
        #     creators composer: "Mozart"
        #     part :p1, name: "Piano" do
        #       # ...
        #     end
        #   end
        def initialize(work_number: nil, work_title: nil,
                       movement_number: nil, movement_title: nil,
                       encoding_date: nil,
                       creators: nil,
                       rights: nil,
                       &block)

          @work_number = work_number
          @work_title = work_title
          @movement_number = movement_number
          @movement_title = movement_title

          @encoding_date = encoding_date || DateTime.now

          @creators = []
          @rights = []

          self.creators **creators if creators
          self.rights **rights if rights

          @groups_and_parts = []
          @parts = {}

          with &block if block_given?
        end

        # Work title builder/setter.
        #
        # @overload work_title(value)
        #   Sets work title via DSL
        #   @param value [String] work title
        # @overload work_title=(value)
        #   Sets work title via assignment
        #   @param value [String] work title
        attr_simple_builder :work_title

        # Work number builder/setter.
        #
        # @overload work_number(value)
        #   Sets work number via DSL
        #   @param value [Integer] work number
        # @overload work_number=(value)
        #   Sets work number via assignment
        #   @param value [Integer] work number
        attr_simple_builder :work_number

        # Movement title builder/setter.
        #
        # @overload movement_title(value)
        #   Sets movement title via DSL
        #   @param value [String] movement title
        # @overload movement_title=(value)
        #   Sets movement title via assignment
        #   @param value [String] movement title
        attr_simple_builder :movement_title

        # Movement number builder/setter.
        #
        # @overload movement_number(value)
        #   Sets movement number via DSL
        #   @param value [Integer, String] movement number
        # @overload movement_number=(value)
        #   Sets movement number via assignment
        #   @param value [Integer, String] movement number
        attr_simple_builder :movement_number

        # Encoding date builder/setter.
        #
        # @overload encoding_date(value)
        #   Sets encoding date via DSL
        #   @param value [DateTime] encoding date
        # @overload encoding_date=(value)
        #   Sets encoding date via assignment
        #   @param value [DateTime] encoding date
        attr_simple_builder :encoding_date

        # Adds rights information (single or multiple).
        #
        # Rights specify copyright, licensing, or attribution information.
        #
        # @overload rights(hash)
        #   Adds multiple rights via hash (DSL style)
        #   @param hash [Hash{Symbol => String}] rights by type
        # @overload add_rights(type, name)
        #   Adds single rights entry (method style)
        #   @param type [Symbol, String] rights type (e.g., :lyrics, :arrangement)
        #   @param name [String] rights holder name
        #
        # @example DSL style
        #   score.rights lyrics: "John Doe", music: "Jane Smith"
        #
        # @example Method style
        #   score.add_rights :lyrics, "John Doe"
        #   score.add_rights :music, "Jane Smith"
        attr_tuple_adder_to_array :rights, Internal::Rights, plural: :rights

        # Adds creator information (single or multiple).
        #
        # Creators specify who created various aspects of the work.
        #
        # @overload creators(hash)
        #   Adds multiple creators via hash (DSL style)
        #   @param hash [Hash{Symbol => String}] creators by type
        # @overload add_creator(type, name)
        #   Adds single creator entry (method style)
        #   @param type [Symbol, String] creator type (e.g., :composer, :lyricist, :arranger)
        #   @param name [String] creator name
        #
        # @example DSL style
        #   score.creators composer: "Mozart", lyricist: "Da Ponte"
        #
        # @example Method style
        #   score.add_creator :composer, "Mozart"
        #   score.add_creator :lyricist, "Da Ponte"
        attr_tuple_adder_to_array :creator, Internal::Creator

        # Adds a part to the score.
        #
        # Parts represent individual instruments or voices in the score. Each part
        # contains measures with musical content.
        #
        # @param id [Symbol, String] unique part identifier (used in part references)
        # @param name [String] full part name (displayed in score)
        # @param abbreviation [String, nil] abbreviated name (for subsequent systems)
        # @yield Optional DSL block for defining measures
        # @return [Internal::Part] the created part
        #
        # @example DSL style
        #   score.part :p1, name: "Violin I", abbreviation: "Vln. I" do
        #     measure do
        #       pitch 'A', octave: 4, duration: 4, type: 'quarter'
        #     end
        #   end
        #
        # @example Method style
        #   part = score.add_part(:p1, name: "Violin I", abbreviation: "Vln. I")
        #   measure = part.add_measure
        #   measure.add_pitch step: 'A', octave: 4, duration: 4, type: 'quarter'
        attr_complex_adder_to_custom :part, variable: :@parts do |id, name:, abbreviation: nil, &block|
          Internal::Part.new(id, name: name, abbreviation: abbreviation, &block).tap do |part|
            @parts[id] = part
            @groups_and_parts << part
          end
        end

        # Adds a part group to organize parts.
        #
        # Part groups bracket multiple parts together (e.g., string section, choir).
        # Groups are defined by matching start/stop pairs with the same number.
        #
        # @param number [Integer, nil] group number (for matching start/stop)
        # @param type [String] 'start' or 'stop'
        # @param name [String, nil] group name (displayed on bracket)
        # @param abbreviation [String, nil] abbreviated group name
        # @param symbol [String, nil] bracket symbol (e.g., 'bracket', 'brace')
        # @param group_barline [Boolean, String, nil] whether barlines connect across group
        # @param group_time [Boolean, String, nil] whether time signatures are shared
        # @return [Internal::PartGroup] the created group
        #
        # @example Bracketing string section
        #   score.add_group 1, type: 'start', name: "Strings", symbol: 'bracket'
        #   score.add_part :p1, name: "Violin I"
        #   score.add_part :p2, name: "Violin II"
        #   score.add_part :p3, name: "Viola"
        #   score.add_group 1, type: 'stop'
        #
        # @example Nested groups
        #   score.add_group 1, type: 'start', name: "Orchestra"
        #   score.add_group 2, type: 'start', name: "Woodwinds"
        #   score.add_part :p1, name: "Flute"
        #   score.add_part :p2, name: "Oboe"
        #   score.add_group 2, type: 'stop'
        #   score.add_group 1, type: 'stop'
        attr_complex_adder_to_custom :group do |*parameters, **key_parameters|
          Internal::PartGroup.new(*parameters, **key_parameters).tap do |group|
            @groups_and_parts << group
          end
        end

        # Generates the complete MusicXML document structure.
        #
        # Creates a MusicXML 3.0 Partwise document with:
        # - XML declaration and DOCTYPE
        # - Work and movement metadata
        # - Identification section (creators, rights, encoding info)
        # - Part list (part and group declarations)
        # - Part content (measures with notes)
        #
        # The encoding section automatically includes:
        # - Encoding date (from @encoding_date)
        # - Software attribution: "MusaDSL: MusicXML output formatter"
        #
        # @param io [IO] output stream to write XML to
        # @param indent [Integer] current indentation level
        # @param tabs [String] precomputed tab string for current indent
        # @return [void]
        #
        # @api private
        def _to_xml(io, indent:, tabs:)
          io.puts "#{tabs}<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>"
          io.puts "#{tabs}<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 3.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">"
          io.puts "#{tabs}<score-partwise version=\"3.0\">"

          # Work section (optional)
          if @work_number || @work_title
            io.puts"#{tabs}\t<work>"
            io.puts"#{tabs}\t\t<work-number>#{@work_number.to_i}</work-number>" if @work_number
            io.puts"#{tabs}\t\t<work-title>#{@work_title}</work-title>" if @work_title
            io.puts"#{tabs}\t</work>"
          end

          # Movement metadata (optional)
          io.puts"#{tabs}\t<movement-number>#{@movement_number.to_i}</movement-number>" if @movement_number
          io.puts"#{tabs}\t<movement-title>#{@movement_title}</movement-title>" if @movement_title

          # Identification section (required)
          io.puts "#{tabs}\t<identification>"

          @creators.each do |creator|
            creator.to_xml(io, indent: indent + 2)
          end

          @rights.each do |rights|
            rights.to_xml(io, indent: indent + 2)
          end

          io.puts "#{tabs}\t\t<encoding>"
          io.puts"#{tabs}\t\t\t<encoding-date>#{@encoding_date.strftime("%Y-%m-%d")}</encoding-date>"
          io.puts"#{tabs}\t\t\t<software>MusaDSL: MusicXML output formatter</software>"
          io.puts "#{tabs}\t\t</encoding>"

          io.puts "#{tabs}\t</identification>"

          # Part list section (required)
          io.puts "#{tabs}\t<part-list>"
          @groups_and_parts.each do |group_or_part|
            group_or_part.header_to_xml(io, indent: indent + 2)
          end
          io.puts "#{tabs}\t</part-list>"

          # Parts content (measures with notes)
          @parts.each_value do |part|
            part.to_xml(io, indent: indent + 1)
          end

          io.puts "#{tabs}</score-partwise>"
        end
      end
    end
  end
end


