require 'test_helper'

module SqlTracker
  class HandlerTest < Minitest::Test
    def setup
      reset_sql_tracker_options
    end

    def test_tracking_queries_with_a_block
      SqlTracker::Config.tracked_sql_command = %w(SELECT INSERT)

      expected_queries = [
        'SELECT * FROM users',
        'insert into users VALUES (xxx)'
      ]

      query_data = SqlTracker.track do
        expected_queries.each { |q| instrument_query(q) }
        instrument_query('DELETE FROM users WHERE id = 1')
      end

      instrument_query('SELECT * FROM comments')

      assert_equal(
        expected_queries,
        query_data.values.map { |v| v[:sql] }
      )
    end

    def test_track_is_always_enabled_when_using_a_block
      SqlTracker::Config.enabled = false
      query = 'SELECT * FROM users'
      query_data = SqlTracker.track do
        instrument_query(query)
      end
      refute_empty(query_data)
      assert_equal(query, query_data.values.first[:sql])
    end

    private

    def instrument_query(query)
      ActiveSupport::Notifications.instrument(
        'sql.active_record',
        sql: query
      )
    end
  end
end
