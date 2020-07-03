require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
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
      end
    end
  end
end


