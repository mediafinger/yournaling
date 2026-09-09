# Store a few per-request attributes here (globally), instead of passing them around everywhere
#
# https://api.rubyonrails.org/classes/ActiveSupport/CurrentAttributes.html

class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :team
  attribute :member

  attribute :module_name
  attribute :path
  attribute :request_id
end
