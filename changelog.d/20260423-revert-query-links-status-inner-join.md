Rewrote `WorkerPlugins::QueryLinksStatus#count_linked_rows` to take an index-only fast path for unscoped queries. Previously (both with the IN-subquery in 0.0.15 and the INNER JOIN in 0.0.16) the probe had to cross-reference every workplace-link against the target table's primary key — measured at 2.2–13.6 s on a 340k-user workplace, with the variance driven by MariaDB's query plan choice rather than anything we control.

The fast path runs a plain `COUNT(*)` against `(workplace_id, resource_type)` on the composite index — ~50 ms on the same dataset, a 40–250× speedup — and clamps the raw count to `query_count` to defend against orphan links (`checked_count` can never exceed `query_count`, so `all_checked` / `some_checked` stay correct whether or not orphans are present). `WorkerPlugins::DeleteOrphanLinks`, scheduled by consumers, keeps orphan counts at zero in practice so the clamped value equals the live-linked count exactly.

Scoped queries (WHERE / limit / offset / joins / group / having / from / with) still use the `resource_id IN (SELECT ...)` subquery — the window has to be respected and the dataset is bounded by whatever the caller passed.

Kept the `relation_unscoped?` helper; still shared with `RemoveQuery`.
