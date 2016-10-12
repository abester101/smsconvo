require 'resque/tasks'
require 'resque/scheduler/tasks'

# task 'resque:setup' => :environment

namespace :resque do
  task :setup => :environment do
  end
  task :setup_schedule => :setup do
    require 'resque-scheduler'
  end
  task :scheduler => :setup_schedule
end