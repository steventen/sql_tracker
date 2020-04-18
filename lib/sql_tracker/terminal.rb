module SqlTracker
  class Terminal
    DEFAULT_WIDTH = 80
    MIN_WIDTH = 10

    def self.width
      if unix?
        result = (dynamic_width_stty.nonzero? || dynamic_width_tput)
        result < MIN_WIDTH ? DEFAULT_WIDTH : result
      else
        DEFAULT_WIDTH
      end
    end

    def self.dynamic_width_stty
      `stty size 2>/dev/null`.split[1].to_i
    end

    def self.dynamic_width_tput
      `tput cols 2>/dev/null`.to_i
    end

    def self.unix?
      RUBY_PLATFORM =~
        /(aix|darwin|linux|(net|free|open)bsd|cygwin|solaris|irix|hpux)/i
    end
  end
end
