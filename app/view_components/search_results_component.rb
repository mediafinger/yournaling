class SearchResultsComponent < ApplicationComponent
  erb_template <<~ERB
    <% if @results.present? %>
      <ul>
      <% @results.each do |result| %>
          <li>
            <%= @record_links[result["searchable_id"]] %>
            -
            <%# result["content"] %>
            <i>(updated_at: <%= DateTime.parse(result["updated_at"]).to_formatted_s(:db) %>)</i>
          </li>
      <% end %>
      </ul>
    <% end %>
  ERB

  def initialize(results:)
    @results = results
  end

  def before_render
    @record_links = @results&.each_with_object({}) do |result, hash|
      record = ApplicationRecordYidEnabled.fynd(result["searchable_id"])
      link_text = "#{record.class.name}: #{record.name}"
      link_path = send(:"current_team_#{record.class.name.tableize.singularize}_path", record)
      hash[result["searchable_id"]] = link_to(link_text, link_path)
    end
  end
end
