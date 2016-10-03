require 'digest/md5'
require 'json'
require 'fileutils'

module SqlTracker
  class Handler
    def initialize(config)
      @config = config
      @started_at = Time.now.to_s
      @data = {} # {key: {sql:, count:, duration, source: []}, ...}
    end

    def call(name, started, finished, id, payload)
      return unless @config.enabled

      sql = payload[:sql]
      return unless allowed_query_matcher =~ sql

      cleaned_trace = clean_trace(caller)
      return if cleaned_trace.empty?

      sql = clean_sql_query(sql)
      duration = 1000.0 * (finished - started) # in milliseconds
      sql_key = Digest::MD5.hexdigest(sql)

      if @data.key?(sql_key)
        update_data(sql_key, cleaned_trace, duration)
      else
        add_data(sql_key, sql, cleaned_trace, duration)
      end
    end

    def allowed_query_matcher
      @allowed_query_matcher ||= /\A#{@config.tracked_sql_command.join('|')}/i
    end

    def clean_sql_query(query)
      query.squish!
      query.gsub!(/(\s(=|>|<|>=|<=|<>|!=)\s)('[^']+'|\w+)/, '\1xxx')
      query.gsub!(/(\sIN\s)\([^\(\)]+\)/i, '\1(xxx)')
      query.gsub!(/(\sBETWEEN\s)('[^']+'|\w+)(\sAND\s)('[^']+'|\w+)/i, '\1xxx\3xxx')
      query
    end

    def clean_trace(trace)
      if Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
        Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
      end

      Rails.backtrace_cleaner.remove_silencers!
      Rails.backtrace_cleaner.add_silencer do |line|
        line !~ %r{^(#{@config.tracked_paths.join('|')})\/}
      end
      Rails.backtrace_cleaner.clean(trace)
    end

    def add_data(key, sql, trace, duration)
      @data[key] = {}
      @data[key][:sql] = sql
      @data[key][:count] = 1
      @data[key][:duration] = duration
      @data[key][:source] = [trace.first]
      @data
    end

    def update_data(key, trace, duration)
      @data[key][:count] += 1
      @data[key][:duration] += duration
      @data[key][:source] << trace.first
      @data
    end

    # save the data to file
    def save
      return if @data.empty?
      output = {}
      output[:data] = @data
      output[:generated_at] = Time.now.to_s
      output[:started_at] = @started_at
      output[:format_version] = '1.0'
      output[:rails_version] = Rails.version
      output[:rails_path] = Rails.root.to_s

      FileUtils.mkdir_p(@config.output_path)
      filename = "sql_tracker-#{Process.pid}-#{Time.now.to_i}.json"

      File.open(File.join(@config.output_path, filename), 'w') do |f|
        f.write JSON.dump(output)
      end
    end
  end
end
