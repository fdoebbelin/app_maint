# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'app_maint/version'

Gem::Specification.new do |gem|
  gem.name          = "app_maint"
  gem.version       = AppMaint::VERSION
  gem.authors       = ["Fritz-Rainer Doebbelin"]
  gem.summary       = "Application maintenance with capistrano"
  gem.description   = "Provides usefull capistrano recipes for application maintenance"
  gem.email         = "frd@doebbelin.net"
  gem.homepage      = "http://github.com/fdoebbelin/app_maint"
  
  gem.add_development_dependency "rake"  
  gem.add_dependency "capistrano"
  gem.add_dependency "capistrano-ext"
  gem.add_dependency "json"
  
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
