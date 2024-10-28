Dir["#{Rails.root.join('lib/rails_ext/*')}"].each { |path| require "rails_ext/#{File.basename(path)}" }
