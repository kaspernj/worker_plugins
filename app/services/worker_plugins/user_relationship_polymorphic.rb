class WorkerPlugins::UserRelationshipPolymorphic
  def self.execute!
    WorkerPlugins::Workplace.columns_hash.key?("user_type")
  rescue ActiveRecord::StatementInvalid => e
    if e.message.start_with?("Could not find table")
      # Fall back to true if we are in the middle of a migration or something
      return true
    else
      raise e
    end
  end
end