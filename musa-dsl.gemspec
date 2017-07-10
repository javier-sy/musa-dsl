Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = '0.0.1'
  s.date        = '2017-04-23'
  s.summary     = "A Ruby DSL for making simple and complex music"
  s.description = "..."
  s.authors     = ["Javier Sánchez"]
  s.email       = 'javier.sy@gmail.com'
  s.files       = ["lib/musa-dsl.rb", 
                    "lib/musa-dsl/class-mods.rb",
                    "lib/musa-dsl/topaz-midi-clock-input-mods.rb", 
                    "lib/musa-dsl/tool.rb", 
                    "lib/musa-dsl/duplicate.rb",
                    "lib/musa-dsl/transport.rb", "lib/musa-dsl/sequencer.rb", "lib/musa-dsl/themes.rb", 
                    "lib/musa-dsl/series.rb", "lib/musa-dsl/hash-serie-splitter.rb",
                    "lib/musa-dsl/midi-voices.rb", 
                    "lib/musa-dsl/scales.rb", "lib/musa-dsl/chords.rb",
                    "lib/musa-dsl/variatio.rb", "lib/musa-dsl/darwin.rb" ]
  s.homepage    = 'http://rubygems.org/gems/musa-dsl'
  s.license       = 'CC-BY-NC-ND-4.0'
end