namespace :active_storage do
  desc "Deletes the originally uploaded pictures, keeps only the variants."
  task delete_originals: :environment do
    puts "No working solution found yet"
    # ActiveStorage::Attachment.where(record_type: "Picture").where("created_at <= ?", 1.days.ago).find_each(&:destroy)
  end

  desc "Purges unattached Active Storage blobs."
  task purge_unattached: :environment do
    ActiveStorage::Blob.unattached.where("active_storage_blobs.created_at <= ?", 1.days.ago).find_each(&:purge_later)
  end
end
