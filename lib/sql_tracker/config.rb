require 'active_support/configurable'

module SqlTracker
  class Config
    include ActiveSupport::Configurable
    config_accessor :tracked_paths, :tracked_sql_command, :output_path, :enabled

    class << self
      def apply_defaults
        self.enabled = enabled.nil? ? true : enabled
        self.tracked_paths ||= %w(app lib)
        self.tracked_sql_command ||= %w(SELECT INSERT UPDATE DELETE)
        self.output_path ||= File.join(Rails.root.to_s, 'tmp')
        self
      end
    end
  end
end
