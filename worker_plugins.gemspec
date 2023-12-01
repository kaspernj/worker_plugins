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
  s.required_ruby_version = ">= 2.7.8"
  s.metadata["rubygems_mfa_required"] = "true"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.md"]
end
