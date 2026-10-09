class WorkerPlugins::UserRelationshipPolymorphic
  def self.execute!
    return true unless WorkerPlugins::Workplace.connection.table_exists?(WorkerPlugins::Workplace.table_name)
    WorkerPlugins::Workplace.columns_hash.key?("user_type")
  end
end
