# frozen_string_literal: true

# Email verification is deliberately modelled as a nullable timestamp rather than a boolean:
# it answers both "is this address verified?" and "since when?", and it doubles as the
# invalidation salt for the :email_verification token (see User).
#
class AddEmailVerifiedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_verified_at, :datetime
  end
end
