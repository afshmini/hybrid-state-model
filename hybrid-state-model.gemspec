# frozen_string_literal: true

require_relative "lib/hybrid_state_model/version"

Gem::Specification.new do |spec|
  spec.name = "hybrid-state-model"
  spec.version = HybridStateModel::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "A two-layer hierarchical state system for Ruby models"
  spec.description = <<~DESC
    hybrid-state-model introduces a revolutionary two-layer state system:
    Primary State (high-level lifecycle) and Secondary Micro-State (small steps within primary state).
    Perfect for complex workflows that are too complex for flat state machines but don't need full orchestration.
  DESC
  spec.homepage = "https://github.com/yourusername/hybrid-state-model"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 5.2.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "sqlite3", "~> 1.6"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
end

