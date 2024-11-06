# Blazer: https://github.com/ankane/blazer
#
# override Blazers base controller to inherit from AdminController to only give admins access
#
module Blazer
  class BaseController < ::AdminController
  end
end
