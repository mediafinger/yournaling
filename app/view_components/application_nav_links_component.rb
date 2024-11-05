class ApplicationNavLinksComponent < ApplicationComponent
  slim_template <<~SLIM
    ul
      - @link_tags.each do |link_tag|
        li
          = link_tag
  SLIM

  def initialize(link_sections: [], scope: nil, id: {})
    @link_sections = link_sections
    @scope = scope
    @id_param = id
  end

  def before_render
    @link_tags = @link_sections.map do |section|
      path_prefix = [@scope, section].compact.join("_")
      path = send(:"#{path_prefix}_path", @id_param.presence)

      link_to section.titleize, path, role: active_path?(path) ? "button" : nil
    end
  end
end
