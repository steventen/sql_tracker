require 'sql_tracker/config'
require 'sql_tracker/handler'
require 'sql_tracker/report'

module SqlTracker
  def self.initialize!
    raise 'sql tracker initialized twice' if @already_initialized

    config = SqlTracker::Config.apply_defaults
    handler = SqlTracker::Handler.new(config)
    ActiveSupport::Notifications.subscribe('sql.active_record', handler)
    @already_initialized = true

    at_exit { handler.save }
  end
end

if defined?(::Rails) && ::Rails::VERSION::MAJOR.to_i >= 3
  require 'sql_tracker/railtie'
end
