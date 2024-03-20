class ApplicationNavLinksComponent < ApplicationComponent
  erb_template <<-ERB
    <ul>
      <% @link_tags.each do |link_tag| %>
        <li><%= link_tag %></li>
      <% end %>
    </ul>
  ERB

  def initialize(link_sections: [])
    @link_sections = link_sections
  end

  def before_render
    @link_tags = @link_sections.map do |section|
      link_to section.titleize, send(:"#{section}_path"), role: active_path?(send(:"#{section}_path")) ? "button" : nil
    end
  end
end
