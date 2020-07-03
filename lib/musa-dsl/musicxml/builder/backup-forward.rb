require_relative 'helper'

module Musa
  module MusicXML
    module Builder
      module Internal
        class Backup
          include Helper::ToXML

          def initialize(duration)
            @duration = duration
          end

          attr_accessor :duration

          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<backup><duration>#{@duration}</duration></backup>"
          end
        end

        class Forward
          include Helper::ToXML

          def initialize(duration, voice: nil, staff: nil)
            @duration = duration
            @voice = voice
            @staff = staff
          end

          attr_accessor :duration, :voice, :staff

          def _to_xml(io, indent:, tabs:)
            io.puts "#{tabs}<forward>"

            io.puts "#{tabs}\t<duration>#{@duration}</duration>"
            io.puts "#{tabs}\t<voice>#{@voice}</voice>" if @voice
            io.puts "#{tabs}\t<staff>#{@staff}</staff>" if @staff

            io.puts "#{tabs}</forward>"
          end
        end
      end
    end
  end
end