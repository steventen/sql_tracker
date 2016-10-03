require 'test_helper'

module SqlTracker
  class HandlerTest < Minitest::Test
    def test_clean_values_from_where_in_clause
      query = %{
        SELECT * FROM a
        WHERE a.id IN (
          SELECT b.id FROM b WHERE b.id IN (1,2,3,4)
          AND b.uid IN ('aaaa', 'bbbb')
        ) AND a.xid IN (11, 22, 33)
      }
      expected = %{
        SELECT * FROM a
        WHERE a.id IN (
          SELECT b.id FROM b WHERE b.id IN (xxx)
          AND b.uid IN (xxx)
        ) AND a.xid IN (xxx)
      }.squish

      handler = SqlTracker::Handler.new(nil)
      cleaned_query = handler.clean_sql_query(query)
      assert_equal(expected, cleaned_query)
    end

    def test_clean_values_from_comparison_operators
      query = %{
        SELECT * FROM a
        WHERE a.id = 1 AND a.uid != 'bbb'
        (a.num > 1 AND a.num < 3) AND
        (start_date >= '2010-01-01' AND end_date <= '2010-10-01') AND
        a.total BETWEEN 0 AND 100
      }
      expected = %{
        SELECT * FROM a
        WHERE a.id = xxx AND a.uid != xxx
        (a.num > xxx AND a.num < xxx) AND
        (start_date >= xxx AND end_date <= xxx) AND
        a.total BETWEEN xxx AND xxx
      }.squish

      handler = SqlTracker::Handler.new(nil)
      cleaned_query = handler.clean_sql_query(query)
      assert_equal(expected, cleaned_query)
    end

    def test_clean_sql_query_is_case_insensitive
      query = %{
        SELECT * FROM a
        where a.id = 1 AND a.uid != 'bbb'
        (a.num > 1 AND a.num < 3) AND
        (start_date >= '2010-01-01' AND end_date <= '2010-10-01') AND
        a.total between 0 and 100
      }
      expected = %{
        SELECT * FROM a
        where a.id = xxx AND a.uid != xxx
        (a.num > xxx AND a.num < xxx) AND
        (start_date >= xxx AND end_date <= xxx) AND
        a.total between xxx and xxx
      }.squish

      handler = SqlTracker::Handler.new(nil)
      cleaned_query = handler.clean_sql_query(query)
      assert_equal(expected, cleaned_query)
    end
  end
end
