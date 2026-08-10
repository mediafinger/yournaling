# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recurring::CleanupArchivedRecordsJob, type: :job do
  before do
    ActiveRecord::Base.connection.create_table :test_archivable_records, force: true do |t|
      t.string :name
      t.datetime :archived_at
      t.timestamps
    end

    test_model = Class.new(ApplicationRecord) do
      self.table_name = "test_archivable_records"

      include Archivable

      self.archived_retention_period = 30.days
    end

    stub_const("TestArchivableRecord", test_model)
  end

  after do
    if ActiveRecord::Base.connection.table_exists?(:test_archivable_records)
      ActiveRecord::Base.connection.drop_table :test_archivable_records
    end
  end

  describe "queue configuration" do
    it "queues in default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end

  describe "#perform" do
    let!(:old_archived_record) do
      TestArchivableRecord.create!(name: "Old Record").tap do |record|
        record.update_column(:archived_at, 35.days.ago)
      end
    end
    let!(:recent_archived_record) do
      TestArchivableRecord.create!(name: "Recent Record").tap do |record|
        record.update_column(:archived_at, 10.days.ago)
      end
    end
    let!(:active_record) do
      TestArchivableRecord.create!(name: "Active Record")
    end

    it "destroys records archived before the retention period" do
      expect {
        described_class.perform_now
      }.to change { TestArchivableRecord.with_archived.count }.by(-1)

      expect(TestArchivableRecord.with_archived.where(id: old_archived_record.id)).not_to exist
      expect(TestArchivableRecord.with_archived.where(id: recent_archived_record.id)).to exist
      expect(TestArchivableRecord.with_archived.where(id: active_record.id)).to exist
    end

    context "when archived_retention_period is nil" do
      before do
        TestArchivableRecord.archived_retention_period = nil
      end

      after do
        TestArchivableRecord.archived_retention_period = 30.days
      end

      it "does not destroy any records" do
        expect {
          described_class.perform_now
        }.not_to(change { TestArchivableRecord.with_archived.count })
      end
    end
  end

  describe "Archivable concern methods" do
    let!(:active_record) { TestArchivableRecord.create!(name: "Active") }
    let!(:archived_record) do
      TestArchivableRecord.create!(name: "Archived").tap do |record|
        record.update_column(:archived_at, 1.day.ago)
      end
    end

    it "filters out archived records in default_scope" do
      expect(TestArchivableRecord.all).to include(active_record)
      expect(TestArchivableRecord.all).not_to include(archived_record)
    end

    it "returns all records in with_archived scope" do
      expect(TestArchivableRecord.with_archived).to include(active_record, archived_record)
    end

    it "returns only archived records in only_archived scope" do
      expect(TestArchivableRecord.only_archived).to include(archived_record)
      expect(TestArchivableRecord.only_archived).not_to include(active_record)
    end

    it "reports archived? correctly" do
      expect(active_record).not_to be_archived
      expect(archived_record).to be_archived
    end

    it "sets archived_at when archive is called" do
      freeze_time do
        active_record.archive
        expect(active_record.reload.archived_at).to eq(Time.current)
      end
    end

    it "prevents modifying archived records via validation error" do
      archived_record.name = "New Name"
      expect(archived_record).not_to be_valid
      expect(archived_record.errors[:base]).to include("archived records must not be changed")
    end
  end
end
