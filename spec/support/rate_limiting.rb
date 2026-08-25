# frozen_string_literal: true

# Rate limiting is backed by `config.action_controller.cache_store`, which the test environment
# deliberately points at an in-memory store so that rate limits are actually exercised. (The
# general `config.cache_store` stays a :null_store, against which every limiter silently passes.)
#
# That store is captured once, at class definition time, and therefore outlives a single example,
# so counters have to be reset between examples or they bleed across the suite.
#
RSpec.configure do |config|
  config.before { ActionController::Base.cache_store.clear }
end
