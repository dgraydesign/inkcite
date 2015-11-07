# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'inkcite/version'

Gem::Specification.new do |spec|

  spec.name          = "inkcite"
  spec.version       = Inkcite::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ["Jeffrey D. Hoffman"]
  spec.email         = ["inkcite@inkceptional.com"]
  spec.description   = "An opinionated modern, responsive HTML email generator with integrated helpers, versioning, live previews, minification and testing."
  spec.summary       = "Simplifying email development"
  spec.homepage      = "https://github.com/inkceptional/inkcite"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/) - [".gitignore", "Gemfile", "Gemfile.lock"]
  spec.executables   << 'inkcite'
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Sorry, not yet
  spec.has_rdoc = false

  spec.add_dependency 'activesupport'
  spec.add_dependency 'builder'
  spec.add_dependency 'erubis'
  spec.add_dependency 'faker'
  spec.add_dependency 'guard'
  spec.add_dependency 'guard-livereload'
  spec.add_dependency 'htmlbeautifier'
  spec.add_dependency 'image_optim'
  spec.add_dependency 'image_optim_pack'
  spec.add_dependency 'litmus'
  spec.add_dependency 'mail'
  spec.add_dependency 'mailgun-ruby'
  spec.add_dependency 'net-sftp'
  spec.add_dependency 'rack'
  spec.add_dependency 'rack-livereload'
  spec.add_dependency 'rubyzip'
  spec.add_dependency 'thor'
  spec.add_dependency 'yui-compressor'

  spec.add_development_dependency "bundler", "~> 1.1"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"

end
