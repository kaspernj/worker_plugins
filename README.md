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

## Release

Run the release task from a clean worktree:

```bash
bundle exec rake release:patch
```

The task checks out `master`, fetches and fast-forwards from `origin/master`, bumps `lib/worker_plugins/version.rb`, commits and pushes the release commit, runs `npm login` if `npm whoami` shows no active session, then builds and pushes the gem to RubyGems and removes the generated `.gem` file afterward.

Use `BUMP=minor`, `BUMP=major`, or `VERSION=x.y.z` to control the version bump:

```bash
bundle exec rake release:minor
bundle exec rake release:major
bundle exec rake release:rubygems VERSION=0.1.0
```

## License

This project rocks and uses MIT-LICENSE.
