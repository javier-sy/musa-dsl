# TODO reorganizar dependencias explícitas e implícitas: en este fichero poner sólo los require de los módulos principales, y que estos hagan require de sus dependencias
# TODO separar en submódulos las clases que dependen sólo de ruby+activesupport y las que dependen de otras cosas (unimidi)

require 'musa-dsl/class-mods.rb'
require 'musa-dsl/tool.rb'

require 'musa-dsl/series'
require 'musa-dsl/hash-serie-splitter'

require 'musa-dsl/transport'
require 'musa-dsl/sequencer'
require 'musa-dsl/midi-voices'

require 'musa-dsl/scales'
require 'musa-dsl/chords'

require 'musa-dsl/variatio'
require 'musa-dsl/darwin'

module Musa
	VERSION = '0.0.1'
end

