Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = '0.14.26'
  s.date        = '2019-09-30'
  s.summary     = 'A simple Ruby DSL for making complex music'
  s.description = 'Musa-DSL: A Ruby DSL for algorithmic music composition, device language neutral (MIDI, OSC, etc)'
  s.authors     = ['Javier Sánchez Yeste']
  s.email       = 'javier.sy@gmail.com'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|samples)/}) }
  s.homepage    = 'https://github.com/javier-sy/musa-dsl'
  s.license     = 'CC-BY-NC-ND-4.0'

  s.add_runtime_dependency 'citrus', '~> 3.0.0', '>= 3.0.0'

  s.add_runtime_dependency 'midi-message', '~> 0.4', '>= 0.4.9'
  s.add_runtime_dependency 'midi-nibbler', '~> 0.2', '>= 0.2.4'
end
