
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "minibidi/version"

Gem::Specification.new do |spec|
  spec.name          = "minibidi"
  spec.version       = Minibidi::VERSION
  spec.authors       = ["YusukeIwaki"]
  spec.email         = ["q7w8e9w8q7w8e9@yahoo.co.jp"]

  spec.summary       = "Mini WebDriver BiDi binding for Ruby"
  spec.homepage      = 'https://github.com/YusukeIwaki/minibidi'
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/}) || f.include?(".git")
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = ">= 3.2" # Dependency for socketry/async and Data.define
  spec.add_dependency "async"
  spec.add_dependency "async-websocket"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
end
