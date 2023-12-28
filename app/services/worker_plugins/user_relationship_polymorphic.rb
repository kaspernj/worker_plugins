class WorkerPlugins::UserRelationshipPolymorphic
  def self.execute!
    WorkerPlugins::Workplace.columns_hash.key?("user_type")
  rescue => e
    # Fall back to true if we are in the middle of a migration or something
    return true if e.message.start_with?("Could not find table") || e.message.match(/Table '(.+)' doesn't exist/)

    raise e
  end
end
