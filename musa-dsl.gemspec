Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = '0.26.1'
  s.date        = '2021-11-23'
  s.summary     = 'A simple Ruby DSL for making complex music'
  s.description = 'Musa-DSL: A Ruby framework and DSL for algorithmic sound and musical thinking and composition'
  s.authors     = ['Javier Sánchez Yeste']
  s.email       = 'javier.sy@gmail.com'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|samples)/}) }
  s.homepage    = 'https://github.com/javier-sy/musa-dsl'
  s.license     = 'LGPL-3.0'

  s.required_ruby_version = '~> 2.7'

  # TODO
  #s.metadata    = {
    # "source_code_uri" => "https://",
    # "homepage_uri" => "",
    # "documentation_uri" => "",
    # "changelog_uri" => ""
  #}

  s.add_runtime_dependency 'logger', '~> 1.4', '>= 1.4.3'

  s.add_runtime_dependency 'citrus', '~> 3.0', '>= 3.0.0'

  s.add_runtime_dependency 'midi-events', '~> 0.5', '>= 0.5.0'
  s.add_runtime_dependency 'midi-parser', '~> 0.3', '>= 0.3.0'

  s.add_development_dependency 'descriptive-statistics', '~> 2.2'
  s.add_development_dependency 'rspec', '~> 3.0'
end
