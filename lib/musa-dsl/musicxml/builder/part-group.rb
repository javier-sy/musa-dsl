require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        class PartGroup
          include Helper
          include Helper::HeaderToXML

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

          attr_accessor :number, :type, :name, :abbreviation, :symbol, :group_barline, :group_time

          def _header_to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<part-group #{decode_bool_or_string_attribute(@number, 'number')} type=\"#{@type}\">"

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