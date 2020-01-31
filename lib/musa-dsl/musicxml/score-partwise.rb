require 'date'

require 'musa-dsl/core-ext/attribute-builder'

require_relative 'part-group'
require_relative 'part'

require_relative 'helper'

module Musa
  module MusicXML

    class TypedText
      include Helper::ToXML

      def initialize(type = nil, text)
        @type = type
        @text = text
      end

      attr_accessor :type, :text
      attr_reader :tag

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<#{tag}#{" type=\"#{@type}\"" if @type}>#{@text}</#{tag}>"
      end
    end

    private_constant :TypedText

    class Creator < TypedText
      def initialize(type, name)
        @tag = 'creator'
        super type, name
      end
    end

    class Rights < TypedText
      def initialize(type, name)
        @tag = 'rights'
        super type, name
      end
    end

    class ScorePartwise
      include AsContextRun
      include Helper::ToXML

      extend AttributeBuilder

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

        self.as_context_run block if block_given?
      end

      attr_simple_builder :work_title
      attr_simple_builder :work_number

      attr_simple_builder :movement_title
      attr_simple_builder :movement_number

      attr_simple_builder :encoding_date

      attr_tuple_adder_to_array :rights, Rights, plural: :rights
      attr_tuple_adder_to_array :creator, Creator

      attr_complex_adder_to_custom :part, variable: :@parts do |id, name:, abbreviation: nil|
        Part.new(id, name: name, abbreviation: abbreviation).tap do |part|
          @parts[id] = part
          @groups_and_parts << part
        end
      end

      attr_complex_adder_to_custom :group do |*parameters, **key_parameters|
        PartGroup.new(*parameters, **key_parameters).tap do |group|
          @groups_and_parts << group
        end
      end

      def _to_xml(io, indent:, tabs:)
        io.puts "#{tabs}<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>"
        io.puts "#{tabs}<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 3.0 Partwise//EN\" \"http://www.musicxml.org/dtds/partwise.dtd\">"
        io.puts "#{tabs}<score-partwise version=\"3.0\">"

        if @work_number || @work_title
          io.puts"#{tabs}\t<work>"
          io.puts"#{tabs}\t\t<work-number>#{@work_number}</work-number>" if @work_number
          io.puts"#{tabs}\t\t<work-number>#{@work_title}</work-number>" if @work_title
          io.puts"#{tabs}\t</work>"
        end

        io.puts"#{tabs}\t<movement-number>#{@movement_number}</movement-number>" if @movement_number
        io.puts"#{tabs}\t<movement-title>#{@movement_title}</movement-title>" if @movement_title

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

        io.puts "#{tabs}\t<part-list>"
        @groups_and_parts.each do |group_or_part|
          group_or_part.header_to_xml(io, indent: indent + 2)
        end
        io.puts "#{tabs}\t</part-list>"

        @parts.each_value do |part|
          part.to_xml(io, indent: indent + 1)
        end

        io.puts "#{tabs}</score-partwise>"
      end
    end

  end
end


