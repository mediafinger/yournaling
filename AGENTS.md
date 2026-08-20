# Agent Guidelines for Yournaling

## Ruby Environment & Execution Helpers

This project provides self-contained wrapper scripts in `bin/` that automatically initialize the required Ruby environment via `chruby` and `.ruby-version`. Always prefer these scripts when running Ruby, Rake, RSpec, and console commands:

- **Full CI suite (Tests + Linters + Security Analysis)**:
  ```bash
  bin/mcp_rake_ci
  ```
- **Rake tasks**:
  ```bash
  bin/mcp_rake <task_name> [args...]
  # Examples:
  bin/mcp_rake db:migrate
  bin/mcp_rake ci
  ```
- **RSpec test execution**:
  ```bash
  bin/mcp_rspec [spec_files_or_options...]
  # Examples:
  bin/mcp_rspec                                      # Runs all specs
  bin/mcp_rspec spec/models/chronicle_spec.rb        # Runs single spec file
  bin/mcp_rspec spec/requests/searches_spec.rb:15    # Runs single example
  ```
- **RuboCop & Autocorrection**:
  ```bash
  bin/mcp_rubocop [options] [files...]
  # Examples:
  bin/mcp_rubocop -a                                 # Safe autocorrect on all files
  bin/mcp_rubocop -A app/models/chronicle.rb         # Full autocorrect on specific file(s)
  ```
- **Rails Commands (runner, server, console, etc.)**:
  ```bash
  bin/mcp_rails <command> [args...]
  # Examples:
  bin/mcp_rails runner "puts Chronicle.count"
  bin/mcp_rails server
  bin/mcp_rails c --sandbox
  ```
- **Rails Sandbox Console**:
  ```bash
  bin/mcp_console
  ```

If running arbitrary Ruby commands without a dedicated `bin/mcp_...` script, prefix with:
```bash
source /opt/homebrew/share/chruby/chruby.sh && chruby $(cat .ruby-version 2>/dev/null) && <command>
```

---

## Code Quality & Verification Rules

1. **Ruby Change Validation**:
   - Always run `bin/mcp_rake_ci` to confirm all changes pass before concluding a task.
   - Follow strict TDD: plan first, write failing specs first, then implement changes.
   - For every bug or regression discovered, add a regression test.

2. **RuboCop Auto-correction**:
   - After modifying any Ruby file and before running tests or CI, run safe auto-correct:
     ```bash
     bin/mcp_rubocop -A <modified_files>
     ```

3. **Domain Hierarchy**:
   Keep domain models aligned with the content hierarchy:
   $$\text{Team} \longrightarrow \text{Journey} \longrightarrow \text{Experience} \longrightarrow \text{Chronicle} \longrightarrow \text{Memory} \longrightarrow \text{Insights}$$

## UI, Stylesheets, Assets

Yournaling uses Propshaft - therefore assets need precompiling to be available:

* https://raw.githubusercontent.com/rails/propshaft/refs/heads/main/README.md

Propshaft makes all the assets from all the paths it's been configured with through config.assets.paths available for serving and will copy all of them into public/assets when precompiling. This is unlike Sprockets, which did not copy over assets that hadn't been explicitly included in one of the bundled assets.

You can however exempt directories that have been added through the config.assets.excluded_paths. This is useful if you're for example using app/assets/stylesheets exclusively as a set of inputs to a compiler like Dart Sass for Rails, and you don't want these input files to be part of the load path. (Remember you need to add full paths, like `Rails.root.join("app/assets/stylesheets"))`.

These assets can be referenced through their logical path using the normal helpers like asset_path, image_tag, javascript_include_tag, and all the other asset helper tags. These logical references are automatically converted into digest-aware paths in production when `assets:precompile` has been run (through a JSON mapping file found in public/assets/.manifest.json).

### Bulk stylesheet inclusion with SRI

Propshaft extends stylesheet_link_tag with special symbols for bulk inclusion:

```erb
<%= stylesheet_link_tag :all, integrity: true %>  <!-- All stylesheets -->
<%= stylesheet_link_tag :app, integrity: true %>  <!-- Only app/assets stylesheets -->
```

### Improving performance in development

Before every request Propshaft checks if any asset was updated to decide if a cache sweep is needed. This verification is done using the application's configured file watcher which, by default, is ActiveSupport::FileUpdateChecker.

If you have a lot of assets in your project, you can improve performance by adding the listen gem to the development group in your Gemfile, and this line to the development.rb environment file:

`config.file_watcher = ActiveSupport::EventedFileUpdateChecker`
