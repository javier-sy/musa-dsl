require_relative 'lib/musa-dsl/version'

Gem::Specification.new do |s|
  s.name        = 'musa-dsl'
  s.version     = Musa::VERSION
  s.summary     = 'A simple Ruby DSL for making complex music'
  s.description = 'Musa-DSL: A Ruby framework and DSL for algorithmic sound and musical thinking and composition'
  s.authors     = ['Javier Sánchez Yeste']
  s.email       = 'javier.sy@gmail.com'
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|samples|\.github)/}) }
  s.homepage    = 'https://musadsl.yeste.studio'
  s.license     = 'LGPL-3.0-or-later'

  s.required_ruby_version = '>= 3.4.7'

  s.metadata = {
    'homepage_uri' => s.homepage,
    'source_code_uri' => 'https://github.com/javier-sy/musa-dsl',
    'documentation_uri' => 'https://www.rubydoc.info/gems/musa-dsl',
    'rubygems_mfa_required' => 'true'
  }

  s.add_dependency 'matrix', '~> 0.4'
  s.add_dependency 'prime', '~> 0.1'
  s.add_dependency 'sorted_set', '~> 1.0'

  s.add_dependency 'logger', '~> 1.4', '>= 1.4.3'

  s.add_dependency 'citrus', '~> 3.0'

  s.add_dependency 'midi-events', '~> 0.7'
  s.add_dependency 'midi-parser', '~> 0.5'

  s.add_development_dependency 'descriptive-statistics', '~> 2.2'
  s.add_development_dependency 'rack', '~> 2.2'
  s.add_development_dependency 'redcarpet', '~> 3.6'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'webrick', '~> 1.8'
  s.add_development_dependency 'yard', '~> 0.9'

  s.add_development_dependency 'debug', '~> 1'
  s.add_development_dependency 'rubocop', '~> 1'
  # s.add_development_dependency 'ruby-lsp'
  # s.add_development_dependency 'steep'
end
