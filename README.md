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

## Scheduled cleanup of unused workplaces

`WorkerPlugins::DeleteOldWorkplaces` removes workplaces that haven't seen activity in a given window — both the workplace row's `updated_at` is older than the cutoff *and* no link on it has been created or updated since. Deletion runs in batches via raw `delete_all` to skip per-row callbacks.

```ruby
result = WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)
# => {workplaces_deleted: <N>, links_deleted: <M>}
```

Options:

- `older_than:` (required) — any object that responds to `.ago` (typically an `ActiveSupport::Duration` like `2.months` or `30.days`). The service computes the cutoff at call time.
- `batch_size:` (default `1000`) — how many stale workplaces to delete per round-trip.

The gem does not register a scheduler of its own. Wire the service into your application's background queue. Example with `sidekiq-scheduler`:

```ruby
# config/sidekiq.yml
:scheduler:
  :schedule:
    DeleteOldWorkplaces:
      cron: "0 40 3 * * *"   # daily at 03:40 local time
      args: ["WorkerPlugins::DeleteOldWorkplaces", {"older_than": "2.months"}]
      class: ServiceScheduler  # or whatever your project's service-dispatching worker is called
      queue: low_priority
```

If your `ServiceScheduler` only accepts YAML-serializable arguments, wrap the call in a thin application-side service:

```ruby
class Workplaces::DeleteOld < ApplicationService
  def perform
    WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)
    succeed!
  end
end
```

and schedule `Workplaces::DeleteOld` instead.

## Scheduled cleanup of orphan links

`WorkerPlugins::DeleteOrphanLinks` removes `worker_plugins_workplace_links` whose target row no longer exists — i.e. links that point at a resource that was destroyed without the link being cleaned up alongside. Run it periodically from a background job to keep the links table consistent and keep probes like `QueryLinksStatus#checked_count` honest.

```ruby
result = WorkerPlugins::DeleteOrphanLinks.execute!
# => {deleted_count: <N>}
```

Links whose `resource_type` doesn't resolve to a Ruby class (e.g. a model was renamed or removed) are left alone — cleaning those up requires human judgement.

Schedule the same way as `DeleteOldWorkplaces` — typically once a day off-hours.

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
