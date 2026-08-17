# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChronicleEntryComponent, type: :component do
  let(:team) { FactoryBot.create(:team) }
  let(:chronicle) { FactoryBot.create(:chronicle, team: team) }
  let(:thought) { FactoryBot.create(:thought, team: team, text: "A deep philosophical insight") }
  let(:location) { FactoryBot.create(:location, team: team, name: "Sierra Nevada") }
  let(:picture) { FactoryBot.create(:picture, team: team, name: "Sunset View") }
  let(:weblink) { FactoryBot.create(:weblink, team: team, name: "Trail Guide") }
  let(:memory) { FactoryBot.create(:memory, team: team, memo: "Remember this moment") }

  context "when in current_team scope" do
    it "renders thought entries without action buttons" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "current_team"))

      expect(rendered.to_html).to include("A deep philosophical insight")
      expect(rendered.to_html).not_to include("Open")
      expect(rendered.to_html).not_to include("Rewrite")
      expect(rendered.to_html).not_to include("dropdown")
    end

    it "renders location entries without action buttons" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: location)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "current_team"))

      expect(rendered.to_html).to include("Sierra Nevada")
      expect(rendered.to_html).not_to include("Open")
      expect(rendered.to_html).not_to include("Rewrite")
      expect(rendered.to_html).not_to include("dropdown")
    end

    it "renders picture entries without action buttons" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: picture)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "current_team"))

      expect(rendered.to_html).to include("Sunset View")
      expect(rendered.to_html).not_to include("Open")
      expect(rendered.to_html).not_to include("Rewrite")
      expect(rendered.to_html).not_to include("dropdown")
    end

    it "renders weblink entries without action buttons" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: weblink)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "current_team"))

      expect(rendered.to_html).to include("Trail Guide")
      expect(rendered.to_html).not_to include("Open")
      expect(rendered.to_html).not_to include("Rewrite")
      expect(rendered.to_html).not_to include("dropdown")
    end

    it "renders memory entries without action buttons" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: memory)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "current_team"))

      expect(rendered.to_html).to include("Remember this moment")
      expect(rendered.to_html).not_to include("Open")
      expect(rendered.to_html).not_to include("Rewrite")
      expect(rendered.to_html).not_to include("dropdown")
    end
  end

  context "when in team browse scope" do
    it "renders entries in browse mode" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "team", team: team))

      expect(rendered.to_html).to include("A deep philosophical insight")
    end
  end

  context "when in admin scope" do
    it "renders entries in admin mode" do
      entry = FactoryBot.create(:chronicle_entry, chronicle: chronicle, team: team, entry: thought)
      rendered = render_inline(described_class.new(chronicle_entry: entry, scope: "admin"))

      expect(rendered.to_html).to include("A deep philosophical insight")
    end
  end

  context "when partial is missing" do
    it "raises an error in test/local environment" do
      fake_entry = instance_double(Thought, id: "thot_123", team: team)
      entry = instance_double(ChronicleEntry, entry: fake_entry, entry_type: "UnknownType", team: team)

      expect {
        render_inline(described_class.new(chronicle_entry: entry, scope: "current_team"))
      }.to raise_error(RuntimeError, /Missing partial/)
    end
  end
end
