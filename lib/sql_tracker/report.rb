module SqlTracker
  class Report
    attr_accessor :raw_data

    def initialize(data)
      self.raw_data = data
    end

    def valid?
      return false unless raw_data.key?('format_version')
      return false unless raw_data.key?('data')
      return false if raw_data['data'].nil? || raw_data['data'].empty?
      sample = raw_data['data'].values.first
      %w(sql count source).each do |key|
        return false unless sample.key?(key)
      end
      true
    end

    def version
      raw_data['format_version']
    end

    def data
      raw_data['data']
    end

    def print_text(f = STDOUT)
      f.puts '=================================='
      f.puts "Total Unique SQL Queries: #{data.keys.size}"
      f.puts '=================================='
      f.printf(
        "%-#{count_width}s | %-#{duration_width}s | %-#{sql_width}s | Source\n",
        'Count', 'Avg Time (ms)', 'SQL Query'
      )
      f.puts '-' * terminal_width

      data.values.sort_by { |d| -d['count'] }.each do |row|
        chopped_sql = wrap_text(row['sql'], sql_width)
        source_list = wrap_list(row['source'].uniq, sql_width - 10)
        avg_duration = row['duration'].to_f / row['count']
        total_lines = if chopped_sql.length >= source_list.length
                        chopped_sql.length
                      else
                        source_list.length
                      end

        (0...total_lines).each do |line|
          count = line == 0 ? row['count'].to_s : ''
          duration = line == 0 ? avg_duration.round(2) : ''
          source = source_list.length > line ? source_list[line] : ''
          query = row['sql'].length > line ? chopped_sql[line] : ''
          f.printf(
            "%-#{count_width}s | %-#{duration_width}s | %-#{sql_width}s | %-#{sql_width}s\n",
            count, duration, query, source
          )
        end
        f.puts '-' * terminal_width
      end
    end

    def +(other)
      unless self.class == other.class
        raise ArgumentError, "cannot combine #{other.class}"
      end
      unless version == other.version
        raise ArgumentError, "cannot combine v#{version} with v#{other.version}"
      end

      r1 = data
      r2 = other.data

      merged = (r1.keys + r2.keys).uniq.each_with_object({}) do |id, memo|
        if !r1.key?(id)
          memo[id] = r2[id]
        elsif r2.key?(id)
          memo[id] = r1[id]
          memo[id]['count'] += r2[id]['count']
          memo[id]['duration'] += r2[id]['duration']
          memo[id]['source'] += r2[id]['source']
        else
          memo[id] = r1[id]
        end
      end
      merged_data = { 'data' => merged, 'format_version' => version }

      self.class.new(merged_data)
    end

    private

    def wrap_text(text, width)
      return [text] if text.length <= width
      text.scan(/.{1,#{width}}/)
    end

    # an array of text
    def wrap_list(list, width)
      list.map do |text|
        wrap_text(text, width)
      end.flatten
    end

    def sql_width
      @sql_width ||= (terminal_width - count_width - duration_width) / 2
    end

    def count_width
      5
    end

    def duration_width
      15
    end

    def terminal_width
      @terminal_width ||= begin
        result = unix? ? dynamic_width : 80
        result < 10 ? 80 : result
      end
    end

    def dynamic_width
      @dynamic_width ||= (dynamic_width_stty.nonzero? || dynamic_width_tput)
    end

    def dynamic_width_stty
      `stty size 2>/dev/null`.split[1].to_i
    end

    def dynamic_width_tput
      `tput cols 2>/dev/null`.to_i
    end

    def unix?
      RUBY_PLATFORM =~
        /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
    end
  end
end
