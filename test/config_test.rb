require 'test_helper'

module SqlTracker
  class ConfigTest < Minitest::Test
    def test_defaults_should_not_overwrite_user_configs
      SqlTracker::Config.enabled = false
      SqlTracker::Config.tracked_paths = %w(app/model)
      SqlTracker::Config.tracked_sql_command = %w(SELECT)
      SqlTracker::Config.output_path = '/usr/local/test'

      config = SqlTracker::Config.apply_defaults

      assert_equal(false, config.enabled)
      assert_equal(%w(app/model), config.tracked_paths)
      assert_equal(%w(SELECT), config.tracked_sql_command)
      assert_equal('/usr/local/test', config.output_path)
    end
  end
end
