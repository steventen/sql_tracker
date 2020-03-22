require 'test_helper'

module SqlTracker
  class HandlerTest < Minitest::Test
    def test_tracking_queries_with_a_block
      config = SqlTracker::Config.apply_defaults
      config.enabled = true
      config.tracked_sql_command = %w(SELECT INSERT)

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

    private

    def instrument_query(query)
      ActiveSupport::Notifications.instrument(
        'sql.active_record',
        sql: query
      )
    end
  end
end
