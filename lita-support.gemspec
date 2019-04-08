Gem::Specification.new do |spec|
  spec.name          = "lita-support"
  spec.version       = "0.0.1"
  spec.authors       = ["Ben Odom"]
  spec.email         = ["ben@odomnet.com"]
  spec.description   = %q{Lookup common Librato system objects, such as users}
  spec.summary       = %q{Lookup common Librato system objects, such as users}
  spec.homepage      = "https://github.com/librato/lita-lookup"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"
  spec.add_runtime_dependency "lita-keyword-arguments", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "coveralls"
end
