class WorkerPlugins::UserRelationshipPolymorphic
  def self.execute!
    WorkerPlugins::Workplace.columns_hash.key?("user_type")
  rescue StandardError => e
    # Fall back to true if the table doesn't exist yet (MySQL, SQLite, PostgreSQL)
    return true if e.message.start_with?("Could not find table") ||
                   e.message.match?(/Table '(.+)' doesn't exist/) ||
                   e.message.match?(/relation .* does not exist/)

    raise e
  end
end
