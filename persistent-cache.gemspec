# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'persistent-cache/version'

Gem::Specification.new do |gem|
  gem.description   = %q{Persistent Cache using a pluggable back-end (e.g. SQLite)}
  gem.summary       = %q{Persistent Cache has a default freshness threshold of 179 days after which entries are no longer returned}
  gem.homepage      = 'https://github.com/xneelo/persistent-cache.git'
  gem.authors       = ["Ernst Van Graan", "xneelo (Pty) Ltd"]
  gem.email         = ["ernst.vangraan@gmail.com"]
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'persistent-cache'
  gem.require_paths = ['lib']
  gem.required_ruby_version = ['>= 2.0', '< 3.1.20']
  gem.version       = Persistent::VERSION
  gem.add_development_dependency 'rspec', '3.11.0'
  gem.add_development_dependency 'coveralls', '~> 0.8'
  gem.add_development_dependency 'rake', '13.0.6'
  gem.add_development_dependency 'byebug', '~> 11.1'
  gem.add_dependency 'eh', '~> 1.0'
  gem.add_dependency 'persistent-cache-storage-api', '~> 0.1.4'
  gem.add_dependency 'persistent-cache-storage-sqlite', '~> 0.1.3'
  gem.add_dependency 'persistent-cache-storage-directory', '~> 0.1.2'
  gem.add_dependency 'persistent-cache-storage-ram', '~> 0.1.2'
end
