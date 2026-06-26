module SqlQueryCounter
  IGNORED_SQL_PAYLOAD_NAMES = %w[SCHEMA TRANSACTION].freeze
  IGNORED_SQL_PREFIXES = [
    "BEGIN",
    "COMMIT",
    "ROLLBACK",
    "SAVEPOINT",
    "RELEASE SAVEPOINT",
    "PRAGMA"
  ].freeze

  # Captures SQL statements executed inside the block while skipping schema and transaction noise.
  def capture_sql_queries(&)
    queries = []

    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      sql = payload.fetch(:sql)
      next if payload[:cached]
      next if IGNORED_SQL_PAYLOAD_NAMES.include?(payload[:name])
      next if IGNORED_SQL_PREFIXES.any? { |prefix| sql.start_with?(prefix) }

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &)

    queries
  end
end
