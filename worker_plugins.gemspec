$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "worker_plugins/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "worker_plugins"
  s.version     = WorkerPlugins::VERSION
  s.authors     = ["Kasper Johansen"]
  s.email       = ["k@spernj.org"]
  s.homepage    = "https://www.github.com/kaspernj/worker_plugins"
  s.summary     = "TODO: Summary of WorkerPlugins."
  s.description = "TODO: Description of WorkerPlugins."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'rails', '~> 3.2.21'

  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'rspec-rails'
end
