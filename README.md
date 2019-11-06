# WorkerPlugins

## Install

Add to your Gemfile and bundle:
```ruby
gem 'worker_plugins'
```

Install migrations (only necessary sometimes - try running `rails db:migrate` first before installing migrations):
```bash
rails worker_plugins:install:migrations
```

## Usage

Add a lot of objects to a workspace through transactions:

```ruby
users = User.where('id > 0')
workspace.add_links_to_objects(users)
```

Optimally loop over resources on a workspace:

```ruby
workspace.each_resource(types: ['User']) do |user|
```

## License

This project rocks and uses MIT-LICENSE.
