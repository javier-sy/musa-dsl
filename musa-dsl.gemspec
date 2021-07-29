Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = '0.23.6'
  s.date        = '2021-07-29'
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

  s.add_runtime_dependency 'citrus', '~> 3.0.0', '>= 3.0.0'

  s.add_runtime_dependency 'midi-message', '~> 0.4', '>= 0.4.9'
  s.add_runtime_dependency 'midi-nibbler', '~> 0.2', '>= 0.2.4'
end
