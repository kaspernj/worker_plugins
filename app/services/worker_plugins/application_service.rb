class WorkerPlugins::ApplicationService < ServicePattern::Service
  def db_now_method
    if sqlite?
      "TIME('now')"
    else
      "NOW()"
    end
  end

  def sqlite?
    ActiveRecord::Base.connection.instance_values["config"][:adapter].downcase.include?("sqlite")
  end
end
