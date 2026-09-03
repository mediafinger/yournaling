# frozen_string_literal: true

# Marksmith Markdown editor (Story insight).
#
# The engine is mounted explicitly in config/routes.rb (above the "*path"
# catch-all, or its preview endpoint would 404). Auto-mounting appends the
# route *after* the catch-all, so it is disabled here.
Marksmith.configure do |config|
  config.automatically_mount_engine = false
  config.parser = "commonmarker"
end
