# frozen_string_literal: true

# A read-only "CSS" inspector panel in Lookbook that shows the stylesheet for
# the previewed primitive (TODO_UI_DESIGN.md Phase 2). The mapping lives here
# (not env-guarded, so it is spec-able); the panel is only registered in
# development, where Lookbook is loaded.
module DesignCssPanel
  DESIGN_DIR = Rails.root.join("app/assets/stylesheets/design")

  # Primitives with no dedicated file — their rules live in a shared layer file.
  SHARED = {
    "headline" => "typography", "eyebrow" => "typography", "emphasis" => "typography",
    "quote" => "typography", "prose" => "typography", "blockquote" => "typography",
    "divider" => "layout",
    "choice" => "field", "label" => "field"
  }.freeze

  # @param preview [#preview_class] a Lookbook::PreviewEntity
  # @return [Pathname, nil] the design/*.css file backing the preview's component
  def self.file_for(preview)
    return nil unless preview.respond_to?(:preview_class)

    name_for(preview.preview_class.name)
  end

  # @param class_name [String] e.g. "Yui::MemoryCardComponentPreview"
  def self.name_for(class_name)
    base = class_name.to_s.demodulize.delete_suffix("ComponentPreview").underscore.dasherize
    direct = DESIGN_DIR.join("#{base}.css")
    return direct if direct.exist?

    shared = SHARED[base.tr("-", "_")]
    file = DESIGN_DIR.join("#{shared}.css") if shared
    file if file&.exist?
  end
end

if Rails.env.development? && defined?(Lookbook)
  Lookbook.add_panel("css", "lookbook/panels/css",
    { label: "CSS", hotkey: "c" })
end
