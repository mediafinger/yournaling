# frozen_string_literal: true

require "rails_helper"

RSpec.describe JobsWorkerMonitor do
  describe ".worker_running?" do
    it "is false when no worker process has registered" do
      SolidQueue::Process.where(kind: "Worker").delete_all

      expect(described_class.worker_running?).to be(false)
    end

    it "is true when a worker heartbeat is within the liveness threshold" do
      SolidQueue::Process.create!(kind: "Worker", name: "worker-fresh", pid: 1,
        last_heartbeat_at: 1.second.ago)

      expect(described_class.worker_running?).to be(true)
    end

    it "is false when the only worker heartbeat is stale" do
      SolidQueue::Process.where(kind: "Worker").delete_all
      SolidQueue::Process.create!(kind: "Worker", name: "worker-stale", pid: 2,
        last_heartbeat_at: (SolidQueue.process_alive_threshold + 1.minute).ago)

      expect(described_class.worker_running?).to be(false)
    end

    it "ignores non-worker processes such as the dispatcher" do
      SolidQueue::Process.where(kind: "Worker").delete_all
      SolidQueue::Process.create!(kind: "Dispatcher", name: "dispatcher", pid: 3,
        last_heartbeat_at: 1.second.ago)

      expect(described_class.worker_running?).to be(false)
    end

    it "stays quiet (returns true) when the queue tables are unreadable" do
      allow(SolidQueue::Process).to receive(:where).and_raise(ActiveRecord::StatementInvalid)

      expect(described_class.worker_running?).to be(true)
    end
  end
end
