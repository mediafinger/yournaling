# frozen_string_literal: true

require "open3"
require "etc"
require "parallel"

# Runs a named group of shell-command "gates" in parallel, buffers each gate's
# combined stdout+stderr, prints a grouped report (failures only, unless
# CI_VERBOSE), and returns whether every gate passed.
#
# The building block for `rake ci` — see README_RAKE_CI.markdown.
#
#   CIGate.run_group("lint", {
#     "rubocop" => %w[bundle exec rubocop --no-server],
#     "css"     => %w[bin/css_lint],
#   }) # => true / false
#
# Knobs: CI_PARALLELISM (worker count, default Etc.nprocessors),
#        CI_VERBOSE (also print passing gates' output).
module CIGate
  Result = Struct.new(:name, :ok, :seconds, :output, keyword_init: true)

  # Neutralise a personal BASH_ENV (a chruby auto-switch, say): otherwise every
  # child bash — the asdf `node` shim included — re-sources it and, under
  # `bundle exec`, chruby floods stderr with Bundler warnings.
  CHILD_ENV = { "BASH_ENV" => nil }.freeze

  class << self
    # gates: { "name" => %w[command arg ...], ... } — returns true iff all exit 0.
    # rubocop:disable Naming/PredicateMethod -- runs the group; the boolean is its result, not a query
    def run_group(title, gates)
      started = monotonic
      results = Parallel.map(gates.to_a, in_threads: workers(gates.size)) { |name, argv| run_one(name, argv) }
      report(title, results, monotonic - started)
      results.all?(&:ok)
    end
    # rubocop:enable Naming/PredicateMethod

    private

    def run_one(name, argv)
      started = monotonic
      output, status = Open3.capture2e(CHILD_ENV, *argv, chdir: Rails.root.to_s)
      Result.new(name:, ok: status.success?, seconds: monotonic - started, output:)
    rescue SystemCallError => e
      Result.new(name:, ok: false, seconds: monotonic - started, output: "#{e.class}: #{e.message}\n")
    end

    def workers(gate_count)
      raw = ENV["CI_PARALLELISM"]
      requested = raw&.match?(/\A\d+\z/) ? raw.to_i : Etc.nprocessors
      requested.clamp(1, [gate_count, 1].max)
    end

    def verbose?
      !ENV["CI_VERBOSE"].to_s.strip.empty?
    end

    def report(title, results, wall)
      $stdout.puts
      $stdout.puts "── ci:#{title} ──"
      results.each { |r| $stdout.puts "  #{mark(r.ok)} #{r.name.ljust(18)}#{format('%6.1fs', r.seconds)}" }

      (verbose? ? results : results.reject(&:ok)).each do |r|
        next if r.output.strip.empty?

        $stdout.puts
        $stdout.puts "── #{r.name} ".ljust(64, "─")
        $stdout.puts r.output
      end

      pass = results.count(&:ok)
      $stdout.puts
      $stdout.puts "ci:#{title} — #{pass} ✓  #{results.size - pass} ✗  (#{format('%.1fs', wall)} wall)"
    end

    def mark(passed)
      return (passed ? "PASS" : "FAIL") unless color?

      passed ? "\e[32m✓\e[0m" : "\e[31m✗\e[0m"
    end

    def color?
      $stdout.tty? || ENV["CI"] == "true"
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
