# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kubert/version'

Gem::Specification.new do |spec|
  spec.name          = "kubert"
  spec.version       = Kubert::VERSION
  spec.authors       = ["Brian Glusman"]
  spec.email         = ["brian@stellaservice.com"]

  spec.summary       = %q{Kube convenience tools}
  spec.description   = %q{Run tasks and discover/connect to pods in a kube cluster}
  spec.license       = "MIT"

  # # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # # to allow pushing to a single host or delete this section to allow pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_runtime_dependency 'thor', '~> 0.19'
  spec.add_runtime_dependency 'kubeclient', '~> 2'
  spec.add_runtime_dependency 'ky', '~> 0.5.2.pre1'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
