# -*- encoding: utf-8 -*-
require File.expand_path('../lib/knife-baremetalcloud/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = ["knife-baremetalcloud"]
  gem.version       = '0.0.5'
  gem.authors       = ["Diego Desani"]
  gem.email         = ["diego@newservers.com"]
  gem.summary       = %q{baremetalcloud Compute Support for Chef's Knife Command}
  gem.description   = gem.summary
  gem.homepage      = "https://github.com/baremetalcloud/knife-baremetalcloud"
  gem.rubyforge_project = 'rake'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "knife-baremetalcloud"
  gem.require_paths = ["lib"]
  gem.version       = Knife::Baremetalcloud::VERSION
  gem.add_dependency "fog", ">= 1.5.0"
end
