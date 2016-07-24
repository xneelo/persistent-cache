# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'persistent-cache/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Ernst van Graan"]
  gem.email         = ["ernstvangraan@gmail.com"]
  gem.description   = %q{Persistent Cache using a pluggable back-end (e.g. SQLite)}
  gem.summary       = %q{Persistent Cache has a default freshness threshold of 179 days after which entries are no longer returned}
  gem.homepage      = "https://github.com/evangraan/persistent-cache.git"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "persistent-cache"
  gem.require_paths = ["lib"]
  gem.version       = Persistent::VERSION
  gem.add_development_dependency 'rspec', '2.12.0'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'simplecov-rcov'
  gem.add_development_dependency 'byebug'
  gem.add_dependency 'eh'
  gem.add_dependency "persistent-cache-storage-api"
  gem.add_dependency "persistent-cache-storage-sqlite"
  gem.add_dependency "persistent-cache-storage-directory"
  gem.add_dependency "persistent-cache-storage-ram"
end
