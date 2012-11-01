# -*- encoding: utf-8 -*-
require File.expand_path('../lib/websocket_handler/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Michael Pevzner"]
  gem.email         = ["mihapbox@gmail.com"]
  gem.description   = "Websocket connections handler"
  

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "websocket_handler"

  gem.require_paths = ["lib"]
  gem.version       = WebsocketHandler::VERSION

  gem.add_runtime_dependency 'http'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end