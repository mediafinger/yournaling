# frozen_string_literal: true

module Yui
  # Shared superclass for every component in the "Warm Editorial" design language.
  #
  # It deliberately inherits straight from ViewComponent::Base (NOT
  # ApplicationComponent) so the design-language components stay self-contained:
  # no authentication, no policies, no app-specific helpers. They only need a
  # renderer and the example.css stylesheet.
  class BaseComponent < ViewComponent::Base
    # Join an arbitrary list of class fragments, dropping blanks/nils/false.
    #
    #   ex_class("ex-btn", "ex-btn--#{variant}", full_width && "ex-btn--block")
    #   # => "ex-btn ex-btn--primary ex-btn--block"
    def ex_class(*fragments)
      fragments.flatten.compact.reject { |fragment| fragment == false || fragment.to_s.strip.empty? }.join(" ")
    end

    # Coerce a user supplied variant/size to a known token, falling back safely.
    def ex_token(value, allowed:, default:)
      token = value.to_s.to_sym
      allowed.include?(token) ? token : default
    end
  end
end
