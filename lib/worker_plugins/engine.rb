module WorkerPlugins; end

class WorkerPlugins::Engine < ::Rails::Engine
  isolate_namespace WorkerPlugins

  # Add translations to load path.
  path = File.realpath(File.join(File.dirname(__FILE__), "..", "..", "config", "locales"))
  I18n.load_path += Dir[File.join(path, "**", "*.{rb,yml}")]
end
