require "resque"
require "resque/tasks"
# require "resque/scheduler/tasks"
# require_relative Rails.root.join + "config/application" # Include this line if you want your workers to have access to your application

desc "Resque setup"
task "resque:setup" => :environment

# task "resque:setup": :environment do
#   Resque.before_fork = proc { ActiveRecord::Base.connection.disconnect! }
#   Resque.after_fork = proc { ActiveRecord::Base.establish_connection }
# end
