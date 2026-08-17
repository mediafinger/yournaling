# frozen_string_literal: true

require "pagy"
require "pagy/toolbox/paginators/method"

# Global Pagy Options (Pagy v43+)
Pagy::OPTIONS[:limit] = AppConf.items_per_page
