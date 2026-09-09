require "slim/smart" # https://github.com/slim-template/slim/blob/main/doc/smart.md

Slim::Engine.set_options(
  pretty: true, # keeps indentation of the HTML output, useful for debugging in development
  sort_attrs: true, # sorts attributes alphabetically

  implicit_text: true, # allows to omit the | before plain text in the slim template
  smart_text: true, # automatically html-escapes plain text in the slim template
)
