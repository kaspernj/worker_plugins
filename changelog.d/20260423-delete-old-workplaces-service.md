Added `WorkerPlugins::DeleteOldWorkplaces` service. Consumers schedule it (e.g. from a Sidekiq worker) to remove workplaces that haven't seen any activity in a given window — both the workplace row's `updated_at` is older than the cutoff *and* none of its links have been created or updated since. Deletion happens in batches via raw `delete_all` to keep long-running cleanup jobs cheap. The gem itself does not register a scheduler.

Usage:

```ruby
WorkerPlugins::DeleteOldWorkplaces.execute!(older_than: 2.months)
# => {workplaces_deleted: <N>, links_deleted: <M>}
```

`batch_size:` defaults to 1000.
