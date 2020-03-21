# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sql_tracker/version'

Gem::Specification.new do |spec|
  spec.name          = 'sql_tracker'
  spec.version       = SqlTracker::VERSION
  spec.authors       = ['Steven Yue']
  spec.email         = ['jincheker@gmail.com']

  spec.summary       = 'Rails SQL Query Tracker'
  spec.description   = 'Track and analyze sql queries of your rails application'
  spec.homepage      = 'http://www.github.com/steventen/sql_tracker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['sql_tracker']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'activesupport', '>= 3.0.0'
end
