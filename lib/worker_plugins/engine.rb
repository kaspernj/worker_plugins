module WorkerPlugins
  class Engine < ::Rails::Engine
    isolate_namespace WorkerPlugins

    # Add translations to load path.
    path = File.realpath(File.join(File.dirname(__FILE__), '..', '..', 'config', 'locales'))
    I18n.load_path += Dir[File.join(path, '**', '*.{rb,yml}')]

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        if Rails.version.start_with?("3")
          app.config.paths['db/migrate'] += config.paths['db/migrate'].expanded
        else
          config.paths['db/migrate'].expanded.each do |path|
            app.config.paths['db/migrate'] << path
          end
        end
      end
    end
  end
end
