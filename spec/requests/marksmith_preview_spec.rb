# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Marksmith markdown preview", type: :request do
  it "routes and renders the Markdown preview through MarkdownRenderer" do
    post "/marksmith/markdown_previews",
      params: { body: "# Hello\n\nA **world** with <script>alert(1)</script> inline.", element_id: "preview" },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:success)
    expect(response.body).to include("<h1")
    expect(response.body).to include("<strong>world</strong>")
    expect(response.body).not_to include("<script")
  end
end
