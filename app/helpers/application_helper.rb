module ApplicationHelper
  include ActionView::Helpers::NumberHelper # for number_to_human_size
  include Authentication # makes current_user available
  include TeamScope # makes current_team & current_member available
  # include RequestContext # makes the Current.objects available

  # to highlight the active link in the navbar
  def active_path?(given_path)
    request.path.start_with?(given_path)
  end

  def render_svg(svg_name, options = {})
    svg = Rails.application.assets.load_path.find("#{svg_name}.svg")&.content
    raise ArgumentError.new("SVG image file does not exist: #{svg_name}") if Rails.env.local && svg.blank?

    klazz  = options[:class] if options&.key?(:class)
    style  = options[:style] if options&.key?(:style)

    svg.sub!("<svg", "<svg class=\"#{klazz}\"") if klazz
    svg.sub!("<svg", "<svg style=\"#{style}\"") if style

    raw(svg) # rubocop:disable Rails/OutputSafety
  end
end
