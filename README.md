# Rails SQL Query Tracker

[![Code Climate](https://codeclimate.com/github/steventen/sql_tracker/badges/gpa.svg)](https://codeclimate.com/github/steventen/sql_tracker)
[![Build Status](https://travis-ci.org/steventen/sql_tracker.svg?branch=master)](https://travis-ci.org/steventen/sql_tracker)

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

### Tracking Using a Block

It is also possible to track queries executed within a block. This method uses a new subscriber to `sql.active_record` event notifications for each invocation. Results using this method are not saved to a file.

```ruby
query_data = SqlTracker.track do
  # Run some active record queries
end

query_data.values
# =>
# [{
#  :sql=>"SELECT * FROM users",
#  :count=>1,
#  :duration=>1.0,
#  :source=>["app/models/user.rb:12"]
# }]
```

## Reporting

To generate report, run
```bash
sql_tracker tmp/sql_tracker-*.json
```
The output report looks like this:
```
==================================
Total Unique SQL Queries: 24
==================================
Count | Avg Time (ms)   | SQL Query                                                                                                 | Source
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
8     | 0.33            | SELECT `users`.* FROM `users` WHERE `users`.`id` = xxx LIMIT 1                                            | app/controllers/users_controller.rb:125:in `create'
      |                 |                                                                                                           | app/controllers/projects_controller.rb:9:in `block in update'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
4     | 0.27            | SELECT `projects`.* FROM `projects` WHERE `projects`.`user_id` = xxx AND `projects`.`id` = xxx LIMIT 1    | app/controllers/projects_controller.rb:4:in `update'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2     | 0.27            | UPDATE `projects` SET `updated_at` = xxx WHERE `projects`.`id` = xxx                                      | app/controllers/projects_controller.rb:9:in `block in update'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
2     | 1.76            | SELECT projects.* FROM projects WHERE projects.priority BETWEEN xxx AND xxx ORDER BY created_at DESC      | app/controllers/projects_controller.rb:35:in `index'
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
... ...
```
By default, the report will be sorted by the total count of each query, you can also choose to sort it by average duration:
```bash
sql_tracker tmp/sql_tracker-*.json --sort-by=duration
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

