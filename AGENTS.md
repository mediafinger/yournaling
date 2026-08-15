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
