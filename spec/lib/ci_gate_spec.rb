# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/tasks/support/ci_gate")

RSpec.describe CIGate do
  describe ".run_group" do
    it "returns true when every gate exits 0" do
      result = silence_stdout do
        described_class.run_group("demo", { "a" => %w[true], "b" => %w[echo hi] })
      end

      expect(result).to be(true)
    end

    it "returns false when any gate exits non-zero" do
      result = silence_stdout do
        described_class.run_group("demo", { "ok" => %w[true], "bad" => %w[false] })
      end

      expect(result).to be(false)
    end

    it "returns false (does not raise) when a gate command is missing" do
      result = silence_stdout do
        described_class.run_group("demo", { "gone" => %w[definitely-not-a-real-binary-xyz] })
      end

      expect(result).to be(false)
    end

    it "prints a status line for every gate and the failing gate's buffered output" do
      expect do
        described_class.run_group("demo", { "boom" => ["sh", "-c", "echo problem-marker; exit 1"] })
      end.to output(/── ci:demo ──.*boom.*── boom.*problem-marker/m).to_stdout
    end

    it "hides a passing gate's output by default" do
      expect do
        described_class.run_group("demo", { "quiet" => %w[echo hidden-marker] })
      end.not_to output(/hidden-marker/).to_stdout
    end

    it "shows passing output when CI_VERBOSE is set" do
      with_env("CI_VERBOSE" => "1") do
        expect do
          described_class.run_group("demo", { "loud" => %w[echo shown-marker] })
        end.to output(/shown-marker/).to_stdout
      end
    end

    it "ends with a pass/fail summary line" do
      expect do
        described_class.run_group("demo", { "a" => %w[true], "b" => %w[false] })
      end.to output(/ci:demo — 1 ✓  1 ✗/).to_stdout
    end

    it "passes CI_PARALLELISM through to Parallel as the worker count" do
      with_env("CI_PARALLELISM" => "1") do
        expect(Parallel).to receive(:map).with(anything, hash_including(in_threads: 1)).and_call_original

        silence_stdout { described_class.run_group("demo", { "a" => %w[true], "b" => %w[true] }) }
      end
    end

    it "clamps the worker count to the number of gates" do
      with_env("CI_PARALLELISM" => "16") do
        expect(Parallel).to receive(:map).with(anything, hash_including(in_threads: 2)).and_call_original

        silence_stdout { described_class.run_group("demo", { "a" => %w[true], "b" => %w[true] }) }
      end
    end
  end

  def silence_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def with_env(pairs)
    previous = pairs.transform_values { |_| :__unset__ }
    pairs.each_key { |k| previous[k] = ENV.fetch(k, :__unset__) }
    pairs.each { |k, v| ENV[k] = v }
    yield
  ensure
    previous.each { |k, v| v == :__unset__ ? ENV.delete(k) : ENV[k] = v }
  end
end
