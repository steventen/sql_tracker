$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'sql_tracker'
require 'active_support'
require 'active_support/core_ext/string'

require 'minitest/autorun'

def reset_sql_tracker_options
  SqlTracker::Config.enabled = nil
  SqlTracker::Config.tracked_paths = nil
  SqlTracker::Config.tracked_sql_command = nil
  SqlTracker::Config.output_path = nil
end
