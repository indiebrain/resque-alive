require_relative "lib/resque/plugins/alive/version"

Gem::Specification.new do |spec|
  spec.name          = "resque-alive"
  spec.version       = Resque::Plugins::Alive::VERSION
  spec.authors       = ["Aaron Kuehler"]
  spec.email         = ["aaron.kuehler@gmail.com"]

  spec.summary       = %q{Adds a Kubernetes Liveness probe to Resque}
  spec.description   = <<~EOD

    resque-alive adds a Kubernetes Liveness probe to a Resque instance.

    How?

    resque-alive provides a small rack application which
    exposes HTTP endpoint to return the "Aliveness" of the Resque
    instance. Aliveness is determined by the presence of an
    auto-expiring key. resque-alive schedules a "heartbeat"
    job to periodically refresh the expiring key - in the event the
    Resque instance can"t process the job, the key expires and the
    instance is marked as unhealthy.
  EOD

  spec.homepage      = "https://github.com/indiebrain/resque-alive"
  spec.license       = "GPL-3.0"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/indiebrain/resque-alive"
  spec.metadata["changelog_uri"] = "https://github.com/indiebrain/resque-alive/blob/master/changelog.txt"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.16"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "mock_redis"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "resque_spec", "~> 0.18.1"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "resque"
  spec.add_dependency "resque-scheduler"
end
