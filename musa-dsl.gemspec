Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = '0.6.3'
  s.date        = '2018-06-02'
  s.summary     = "A Ruby DSL for making simple and complex music"
  s.description = "..."
  s.authors     = ["Javier Sánchez Yeste"]
  s.email       = 'javier.sy@gmail.com'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.homepage    = 'http://rubygems.org/gems/musa-dsl'
  s.license       = 'CC-BY-NC-ND-4.0'
end
