require 'date'
require_relative 'part-group'
require_relative 'part'

require_relative 'helper'

module Musa
  module MusicXML
    class ScorePartwise
      include Helper::ToXML

      def initialize(work_number: nil, work_title: nil,
                     movement_number: nil, movement_title: nil,
                     creators: nil,
                     rights: nil)

        @work_number = work_number
        @work_title = work_title
        @movement_number = movement_number
        @movement_title = movement_title

        @creators = []
        @rights = []

        creators.arrayfy.each do |creator|
          creator.each_pair do |type, name|
            add_creator type, name: name
          end
        end

        rights.arrayfy.each do |rights|
          rights.each_pair do |type, name|
            add_rights type, name: name
          end
        end

        @groups_and_parts = []
        @parts = {}
      end

      attr_accessor :work_number, :work_title
      attr_accessor :movement_number, :movement_title
      attr_reader :creators
      attr_reader :rights
      attr_reader :parts

      def add_rights(type, name:)
        Rights.new(type, name: name).tap { |rights| @rights << rights }
      end

      def add_creator(type, name:)
        Creator.new(type, name: name).tap { |creator| @creators << creator }
      end

      def add_part(id, name:, abbreviation: nil)
        Part.new(id, name: name, abbreviation: abbreviation).tap do |part|
          @parts[id] = part
          @groups_and_parts << part
        end
      end

      def add_group(number = nil, type:, name: nil, abbreviation: nil, symbol: nil, group_barline: nil, group_time: nil)
        PartGroup.new(number, type: type,
                      name: name, abbreviation: abbreviation, symbol: symbol,
                      group_barline: group_barline, group_time: group_time).tap { |group| @groups_and_parts << group }
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
        io.puts"#{tabs}\t\t\t<encoding-date>#{DateTime.now.strftime("%Y-%m-%d")}</encoding-date>"
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

    class TypedText
      include Helper::ToXML

      def initialize(type = nil, text:)
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
      def initialize(type, name:)
        @tag = 'creator'
        super type, text: name
      end
    end

    class Rights < TypedText
      def initialize(type, name:)
        @tag = 'rights'
        super type, text: name
      end
    end
  end
end


