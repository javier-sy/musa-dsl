Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = '0.9.5'
  s.date        = '2019-01-03'
  s.summary     = 'A simple Ruby DSL for making complex music'
  s.description = '...'
  s.authors     = ['Javier Sánchez Yeste']
  s.email       = 'javier.sy@gmail.com'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.homepage    = 'http://rubygems.org/gems/musa-dsl'
  s.license = 'CC-BY-NC-ND-4.0'
end
