require_relative 'lib/imdbak/version'

Gem::Specification.new do |spec|
  spec.name          = "imdbak"
  spec.version       = Imdbak::VERSION
  spec.authors       = ["ken"]
  spec.email         = ["block24block@gmail.com"]

  spec.summary       = %q{Parse IMDb datasets}
  spec.homepage      = "https://github.com/turnon/imdbak"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "pry", "~> 0.14.1"

  spec.add_dependency "sqlite3", "~> 1.4.2"
  spec.add_dependency "activerecord", "~> 7.0.1"
  spec.add_dependency "click_house", "~> 1.6.0"
  spec.add_dependency "ruby-kafka", "~> 1.4.0"
end
