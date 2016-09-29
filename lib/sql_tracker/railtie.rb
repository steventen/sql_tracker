module SqlTracker
  class Railtie < ::Rails::Railtie
    initializer 'sql_tracker.configure_rails_initialization' do
      SqlTracker.initialize!
    end
  end
end
