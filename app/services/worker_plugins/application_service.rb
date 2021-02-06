class WorkerPlugins::ApplicationService < ServicePattern::Service
  def db_now_value
    @db_now_value ||= begin
      time_string = Time.zone.now.strftime("%Y-%m-%d %H:%M:%S")

      if postgres?
        "CAST(#{quote(time_string)} AS TIMESTAMP)"
      else
        quote(time_string)
      end
    end
  end

  def quote(value)
    WorkerPlugins::Workplace.connection.quote(value)
  end

  def postgres?
    ActiveRecord::Base.connection.instance_values["config"][:adapter].downcase.include?("postgres")
  end

  def sqlite?
    ActiveRecord::Base.connection.instance_values["config"][:adapter].downcase.include?("sqlite")
  end
end
