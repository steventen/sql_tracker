require 'digest/md5'
require 'json'
require 'fileutils'

module SqlTracker
  class Handler
    attr_reader :data

    def initialize(config)
      @config = config
      @started_at = Time.now.to_s
      @data = {} # {key: {sql:, count:, duration, source: []}, ...}
    end

    def subscribe
      @subscription ||= ActiveSupport::Notifications.subscribe(
        'sql.active_record',
        self
      )
    end

    def unsubscribe
      return unless @subscription

      ActiveSupport::Notifications.unsubscribe(@subscription)

      @subscription = nil
    end

    def call(_name, started, finished, _id, payload)
      return unless @config.enabled

      sql = payload[:sql].dup
      return unless track?(sql)

      cleaned_trace = clean_trace(caller)
      return if cleaned_trace.empty?

      sql = clean_sql_query(sql)
      duration = 1000.0 * (finished - started) # in milliseconds
      sql_key = Digest::MD5.hexdigest(sql.downcase)

      if @data.key?(sql_key)
        update_data(sql_key, cleaned_trace, duration)
      else
        add_data(sql_key, sql, cleaned_trace, duration)
      end
    end

    def track?(sql)
      return true unless @config.tracked_sql_command.respond_to?(:join)
      tracked_sql_matcher =~ sql
    end

    def tracked_sql_matcher
      @tracked_sql_matcher ||= /\A#{@config.tracked_sql_command.join('|')}/i
    end

    def trace_path_matcher
      @trace_path_matcher ||= %r{^(#{@config.tracked_paths.join('|')})\/}
    end

    def clean_sql_query(query)
      query.squish!
      unless @config&.retain_sql_query_ids
        query.gsub!(/(\s(=|>|<|>=|<=|<>|!=)\s)('[^']+'|[\$\+\-\w\.]+)/, '\1xxx')
        query.gsub!(/(\sIN\s)\([^\(\)]+\)/i, '\1(xxx)')
        query.gsub!(/(\sBETWEEN\s)('[^']+'|[\+\-\w\.]+)(\sAND\s)('[^']+'|[\+\-\w\.]+)/i, '\1xxx\3xxx')
        query.gsub!(/(\sVALUES\s)\(.+\)/i, '\1(xxx)')
        query.gsub!(/(\s(LIKE|ILIKE|SIMILAR TO|NOT SIMILAR TO)\s)('[^']+')/i, '\1xxx')
        query.gsub!(/(\s(LIMIT|OFFSET)\s)(\d+)/i, '\1xxx')
      end
      query
    end

    def clean_trace(trace)
      return trace unless defined?(::Rails)

      if Rails.backtrace_cleaner.instance_variable_get(:@root) == '/'
        Rails.backtrace_cleaner.instance_variable_set :@root, Rails.root.to_s
      end

      Rails.backtrace_cleaner.remove_silencers!

      if @config.tracked_paths.respond_to?(:join)
        Rails.backtrace_cleaner.add_silencer do |line|
          line !~ trace_path_matcher
        end
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
