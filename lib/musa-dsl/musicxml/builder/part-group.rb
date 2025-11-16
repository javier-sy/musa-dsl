require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        # Part group for bracketing multiple parts together.
        #
        # PartGroup represents the `<part-group>` element in the MusicXML part-list
        # section. Part groups visually bracket or brace related parts together
        # (e.g., string sections, choir SATB, piano grand staff).
        #
        # ## Usage
        #
        # Part groups are defined by matching start/stop pairs with the same number:
        #
        #     <part-group number="1" type="start">
        #       <group-name>Strings</group-name>
        #       <group-symbol>bracket</group-symbol>
        #     </part-group>
        #     <score-part id="p1">...</score-part>
        #     <score-part id="p2">...</score-part>
        #     <part-group number="1" type="stop" />
        #
        # ## Nesting
        #
        # Groups can be nested using different numbers:
        #
        #     <part-group number="1" type="start" name="Orchestra" />
        #     <part-group number="2" type="start" name="Strings" />
        #     <score-part id="vln1" />
        #     <score-part id="vln2" />
        #     <part-group number="2" type="stop" />
        #     <part-group number="1" type="stop" />
        #
        # ## Symbols
        #
        # Common bracket symbols:
        # - **bracket**: Standard square bracket
        # - **brace**: Curly brace (for piano, organ)
        # - **line**: Simple vertical line
        # - **square**: Square bracket (rare)
        #
        # @example String quartet grouping
        #   group_start = PartGroup.new(1,
        #     type: 'start',
        #     name: "String Quartet",
        #     symbol: 'bracket'
        #   )
        #   # ... add parts vln1, vln2, vla, vlc ...
        #   group_stop = PartGroup.new(1, type: 'stop')
        #
        # @example Piano grand staff
        #   PartGroup.new(1,
        #     type: 'start',
        #     symbol: 'brace',
        #     group_barline: true
        #   )
        #   # ... add parts for right hand and left hand ...
        #   PartGroup.new(1, type: 'stop')
        class PartGroup
          include Helper
          include Helper::HeaderToXML

          # Creates a part group declaration.
          #
          # @param number [Integer, nil] group number for matching start/stop pairs
          # @param type [String] 'start' or 'stop'
          # @param name [String, nil] group name displayed on bracket
          # @param abbreviation [String, nil] abbreviated group name
          # @param symbol [String, nil] bracket type: 'bracket', 'brace', 'line', 'square'
          # @param group_barline [Boolean, String, nil] whether barlines connect across group
          # @param group_time [Boolean, String, nil] whether time signatures are shared
          #
          # @example Start a bracket group
          #   PartGroup.new(1,
          #     type: 'start',
          #     name: "Woodwinds",
          #     symbol: 'bracket'
          #   )
          #
          # @example Stop a group
          #   PartGroup.new(1, type: 'stop')
          def initialize(number = nil, # number
                         type:,
                         name: nil,
                         abbreviation: nil,
                         symbol: nil,
                         group_barline: nil, # true
                         group_time: nil) # true
            @number = number
            @type = type
            @name = name
            @abbreviation = abbreviation
            @symbol = symbol
            @group_barline = group_barline
            @group_time = group_time
          end

          # Group number (for matching start/stop pairs).
          # @return [Integer, nil]
          attr_accessor :number

          # Type: 'start' or 'stop'.
          # @return [String]
          attr_accessor :type

          # Group name displayed on bracket.
          # @return [String, nil]
          attr_accessor :name

          # Abbreviated group name.
          # @return [String, nil]
          attr_accessor :abbreviation

          # Bracket symbol type.
          # @return [String, nil]
          attr_accessor :symbol

          # Whether barlines connect across the group.
          # @return [Boolean, String, nil]
          attr_accessor :group_barline

          # Whether time signatures are shared.
          # @return [Boolean, String, nil]
          attr_accessor :group_time

          # Generates the part-group XML element for the part-list section.
          #
          # @param io [IO] output stream
          # @param indent [Integer] indentation level
          # @param tabs [String] tab string
          # @return [void]
          #
          # @api private
          def _header_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<part-group#{ decode_bool_or_string_attribute(@number&.to_i, 'number') } type=\"#{@type}\">"

            io.puts "#{tabs}\t<group-name>#{@name}</group-name>" if @name
            io.puts "#{tabs}\t<group-abbreviation>#{@abbreviation}</group-abbreviation>" if @abbreviation
            io.puts "#{tabs}\t<group-symbol>#{@symbol}</group-symbol>" if @symbol
            io.puts "#{tabs}\t<group-barline>#{decode_bool_or_string_value(@group_barline, 'yes', 'no')}</group-barline>" if @group_barline
            io.puts "#{tabs}\t<group-time>#{decode_bool_or_string_value(@group_time, 'yes', 'no')}</group-time>" if @group_time

            io.puts "#{tabs}</part-group>"
          end
        end
      end
    end
  end
end