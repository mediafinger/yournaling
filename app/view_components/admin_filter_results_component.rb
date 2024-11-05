class AdminFilterResultsComponent < ApplicationComponent
  erb_template <<-ERB
    <% if @results.present? %>
      <ul>
      <% @results.each do |result| %>
          <li>
            <%= result.as_json %>
          </li>
      <% end %>
      </ul>
    <% end %>
  ERB

  def initialize(results:)
    @results = results
  end

  def before_render
    # TODO
  end
end
