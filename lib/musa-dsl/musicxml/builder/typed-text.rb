require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Base class for typed text elements (creators, rights).
        #
        # TypedText represents MusicXML elements that have a type attribute and
        # text content, such as `<creator type="composer">Name</creator>`.
        #
        # This is a private base class used by {Creator} and {Rights}.
        #
        # @api private
        class TypedText
          include Helper::ToXML

          # Creates a typed text element.
          #
          # @param type [String, Symbol, nil] element type attribute
          # @param text [String] text content
          def initialize(type = nil, text)
            @type = type
            @text = text
          end

          # Type attribute value.
          # @return [String, Symbol, nil]
          attr_accessor :type

          # Text content.
          # @return [String]
          attr_accessor :text

          # XML tag name (set by subclasses).
          # @return [String]
          attr_reader :tag

          # Generates XML for this typed text element.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<#{tag}#{" type=\"#{@type}\"" if @type}>#{@text}</#{tag}>"
          end
        end

        private_constant :TypedText

        # Creator metadata for MusicXML identification section.
        #
        # Represents a `<creator>` element specifying who created various aspects
        # of the work (composer, lyricist, arranger, etc.).
        #
        # @example
        #   creator = Creator.new(:composer, "Ludwig van Beethoven")
        #   creator.to_xml  # => <creator type="composer">Ludwig van Beethoven</creator>
        class Creator < TypedText
          # Creates a creator entry.
          #
          # @param type [String, Symbol] creator type (e.g., :composer, :lyricist, :arranger)
          # @param name [String] creator's name
          #
          # @example
          #   Creator.new(:composer, "Mozart")
          #   Creator.new(:lyricist, "Da Ponte")
          def initialize(type, name)
            @tag = 'creator'
            super type, name
          end
        end

        # Rights metadata for MusicXML identification section.
        #
        # Represents a `<rights>` element specifying copyright, licensing, or
        # attribution information.
        #
        # @example
        #   rights = Rights.new(:lyrics, "Copyright 2024 Publisher Name")
        #   rights.to_xml  # => <rights type="lyrics">Copyright 2024 Publisher Name</rights>
        class Rights < TypedText
          # Creates a rights entry.
          #
          # @param type [String, Symbol] rights type (e.g., :lyrics, :music, :arrangement)
          # @param name [String] rights statement or holder name
          #
          # @example
          #   Rights.new(:music, "Copyright 2024 ACME Publishing")
          #   Rights.new(:lyrics, "Public Domain")
          def initialize(type, name)
            @tag = 'rights'
            super type, name
          end
        end
      end
    end
  end
end


