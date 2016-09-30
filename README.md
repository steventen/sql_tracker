# Rails SQL Query Tracker

`sql_tracker` tracks SQL queries by subscribing to Rails' `sql.active_record` event notifications.

It then aggregates and generates report to give you insights about all the sql queries happened in your Rails application.

## Installation

Add this line to your application's Gemfile:

```ruby
group :development, :test do
  ... ...
  gem 'sql_tracker'
end
```

And then execute:

    $ bundle


## Tracking

To start tracking, simply start your rails application server. When your server is shutting down, `sql_tracker` will dump all the tracking data into one or more json file(s) under the `tmp` folder of your application.

`sql_tracker` can also track sql queries when running rails tests (e.g. your controller or integration tests), it will dump the data after all the tests are finished.


## Reporting

To generate report, run
```bash
sql_tracker tmp/sql_tracker-*.json
```

## Configurations

All the configurable variables and their defaults are list below:
```ruby
SqlTracker::Config.enabled = true
SqlTracker::Config.tracked_paths = %w(app lib)
SqlTracker::Config.tracked_sql_command = %w(SELECT INSERT UPDATE DELETE)
SqlTracker::Config.output_path = File.join(Rails.root.to_s, 'tmp')
```

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

