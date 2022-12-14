$LOAD_PATH.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "worker_plugins/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "worker_plugins"
  s.version = WorkerPlugins::VERSION
  s.authors = ["Kasper Johanmsen"]
  s.email = ["kaspernj@gmail.com"]
  s.homepage = "https://www.github.com/kaspernj/worker_plugins"
  s.summary = "Rails framework for easily choosing and creating lists of objects and execute plugins against them."
  s.description = "Rails framework for easily choosing and creating lists of objects and execute plugins against them."
  s.required_ruby_version = ">= 2.5.7"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 6.0.0"

  s.add_runtime_dependency "service_pattern", ">= 1.0.0"

  s.add_development_dependency "awesome_translations"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "rubocop-performance"
  s.add_development_dependency "rubocop-rails"
  s.add_development_dependency "rubocop-rspec"
  s.add_development_dependency "sqlite3"
end
