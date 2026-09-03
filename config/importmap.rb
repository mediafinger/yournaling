# frozen_string_literal: true

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Marksmith Markdown editor (Story insight). Vendored from the gem's shipped
# `*-full.esm.js` bundles (Stimulus included) so no external CDN is needed and
# the strict `script-src 'self'` CSP holds. See TODO_MARKDOWN_STORIES.md.
pin "marksmith", to: "marksmith_controller.js"
pin "list-continuation", to: "list_continuation_controller.js"
