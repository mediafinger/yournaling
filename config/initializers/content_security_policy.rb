# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
#
# Application-wide Content Security Policy. Enabled in Phase 6 of the UI design
# migration: with Pico and the Google Fonts CDN gone, the app loads no external
# CSS / JS / fonts, so every source can be locked to `:self`.
#
# `'unsafe-inline'` is still allowed for scripts and styles because:
#   * Turbo injects an inline <style> for its progress bar, and
#   * the mounted admin engines (Blazer, Mission Control) render inline
#     <script> / <style> with no nonce.
# Dropping it (and switching to a nonce) needs those engines exempted via
# `content_security_policy(false)` in their base controllers plus a manual
# browser QA pass — tracked in TODO_UI_DESIGN.md Phase 6.
#
# Not enforced in development, where Lookbook / letter_opener / web-console
# pull in their own inline assets and a live-reload WebSocket.
unless Rails.env.development?
  Rails.application.configure do
    config.content_security_policy do |policy|
      policy.default_src :self
      policy.font_src    :self
      policy.img_src     :self, :data, :blob
      policy.object_src  :none
      policy.script_src  :self, :unsafe_inline
      policy.style_src   :self, :unsafe_inline
      policy.connect_src :self
      policy.base_uri    :self
      policy.frame_ancestors :self
      policy.form_action :self
    end
  end
end
