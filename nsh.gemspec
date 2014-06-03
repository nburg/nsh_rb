# -*- encoding: utf-8 -*-
require File.expand_path('../lib/nsh/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nick Burgess"]
  gem.email         = ["nick@teguchi.org"]
  gem.summary       = %q{Run commands on remote servers in parallel}
  gem.description   = %q{Run commands on remote servers in parallel}
  gem.homepage      = "http://github.com/nburg/nsh_rb"
  gem.license       = "MIT"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- spec/*`.split("\n")
  gem.name          = "nsh"
  gem.require_paths = ["lib"]
  gem.version       = Nsh::VERSION

  gem.add_development_dependency('rake')
  gem.add_development_dependency('mocha')
end
