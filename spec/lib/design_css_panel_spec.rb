# frozen_string_literal: true

require "rails_helper"

RSpec.describe DesignCssPanel do
  describe ".name_for" do
    it "maps a component preview to its dedicated design/*.css file" do
      expect(described_class.name_for("Yui::ButtonComponentPreview"))
        .to eq(Rails.root.join("app/assets/stylesheets/design/button.css"))
    end

    it "dasherises multi-word component names" do
      expect(described_class.name_for("MemoryCardComponentPreview").basename.to_s).to eq("memory-card.css")
      expect(described_class.name_for("ChronicleCardComponentPreview").basename.to_s).to eq("chronicle-card.css")
    end

    it "falls back to the shared layer file for primitives with no dedicated sheet" do
      expect(described_class.name_for("Yui::HeadlineComponentPreview").basename.to_s).to eq("typography.css")
      expect(described_class.name_for("Yui::DividerComponentPreview").basename.to_s).to eq("layout.css")
    end

    it "returns nil when nothing matches" do
      expect(described_class.name_for("Yui::NonexistentComponentPreview")).to be_nil
    end

    it "resolves every registered Yui primitive preview to a real file" do
      previews = Rails.root.glob("spec/view_components/previews/yui/*_preview.rb")
        .map { |f| "Yui::#{File.basename(f, '.rb').camelize}" }

      previews.each do |klass|
        path = described_class.name_for(klass)
        expect(path).to be_present, "no design/*.css mapping for #{klass}"
        expect(path).to exist
      end
    end
  end
end
