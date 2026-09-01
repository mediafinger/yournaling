# frozen_string_literal: true

module Yui
  # Shared superclass for every primitive in the "Warm Editorial" design language.
  #
  # ## These components are PURE (data-access rule — TODO_UI_DESIGN.md Phase 1)
  #
  # `Yui::*` primitives inherit `ViewComponent::Base` directly, **not**
  # `ApplicationComponent`. That is deliberate and load-bearing: they have no
  # access to `current_user`, Action Policy, `current_team`, or app helpers, and
  # they must never gain it.
  #
  # - **Callers pass plain values** — `href:`, `title:`, `author_name:`,
  #   `date: "4 Aug 2024"`, `visibility: :public`. Never a `Memory`, a `User`, or
  #   a policy object.
  # - **Authorization** (may this user see the edit link?) and **record → view
  #   model mapping** (a `Chronicle` → the `title:`/`entries:`/`href:` a
  #   `Yui::ChronicleCard` wants) happen *outside* the primitive: in an
  #   app-level wrapper component (an `ApplicationComponent` subclass that
  #   renders `Yui::*` internally), or in the controller/view.
  # - **Why:** it keeps the primitives trivially testable (no fixtures, no
  #   sign-in), reusable in Lookbook / `/example` with literal data, and immune
  #   to a future auth or model refactor. "Wrap, don't fork" (§8).
  #
  # ## Template placement (TODO_UI_DESIGN.md §7)
  #
  # - **Sidecar `.slim` is the default** — `button_component.html.slim` next to
  #   the `.rb`, for anything with a `- if` / `- each` / slots or more than a
  #   handful of lines. Sidecars are linted by `slim_lint`, get editor support,
  #   and keep markup out of the `.rb`'s `git blame`.
  # - **`def call` with `tag` / `content_tag`, no template** — for a trivial
  #   one-element wrapper (`Yui::Emphasis`, `Yui::Eyebrow`, `Yui::Quote`,
  #   `Yui::Prose`).
  # - **Inline `slim_template <<~SLIM`** — avoid for new components; keep only
  #   for a tiny, logic-free existing template. Never `<<-SLIM` / bare `<<SLIM`;
  #   `<<~'SLIM'` only when `#{...}` must reach the browser literally.
  #
  # Variant/size params go through `ex_token` so bad input degrades to the
  # default instead of raising. Treat `Yui::Field` / `Yui::Button` / `Yui::Card`
  # as stable API — changes go through a deprecation cycle (§8).
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
