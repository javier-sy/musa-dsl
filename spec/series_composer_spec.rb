require 'spec_helper'

require 'musa-dsl'

include Musa::Series::Composer

RSpec.describe Musa::Series::Composer do
  context '' do

    it '' do
      composer = Composer.new(inputs: nil) do
        input ({ S: [1, 2, 3, 4, 5] })

        step1 ({ skip: 2 }), reverse, { repeat: 2 }, reverse

        route input,to: step1
        route step1, to: output

        # parte1a reverse, { skip: 2 }, { repeat: 2 }
        # parte1b reverse, { skip: 3 }, { repeat: 3 }
        #
        # parte2 ({ skip: 3 }), { repeat: 2 }
        #
        # route input, to: parte1a
        # route input, to: parte1b
        #
        # route parte1a, to: parte2
        #
        # route parte2, to: output
      end

      s = composer.outputs[:output].i

      while v = s.next_value
        puts "s.next_value = #{v}"
      end
    end

    it '' do
      # ...
      #
      x.inputs[:input] = S(1, 2, 3)
      puts x.outputs[:output].next_value

      # esto...
      x.route :parte1b, to: :parte2
      x.route :input, to: :a

      # debería ser como esto otro...
      x.update do
        route parte1b, to: parte2
        route input, to: a
      end
    end
  end
end