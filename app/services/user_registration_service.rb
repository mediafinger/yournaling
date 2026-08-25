# frozen_string_literal: true

# Registers a new User from untrusted input and sends the email verification mail.
#
# Deliberately does NOT create a Team or a Member: team creation is a separate, explicit user
# action owned by TeamsController. A user without any team is a valid state.
#
# Returns the User. It is persisted on success and carries validation errors on failure, which is
# exactly what the caller needs to re-render the form.
#
class UserRegistrationService
  # The service does not trust its caller: even if strong parameters were bypassed, only these
  # attributes can ever be set at registration time. Notably `role` and `email_verified_at` are
  # not among them.
  REGISTRABLE_ATTRIBUTES = %i[name email password].freeze

  class << self
    def call(attributes:)
      user = User.new(registrable(attributes))

      User.create_with_event(record: user, event_params: { team: nil, user: user })

      # Enqueued only after the user is safely committed. The queue lives in its own database and
      # would not roll back with the record, so sending a verification link for a user that does
      # not exist is the one failure mode worth designing out. The reverse (user without mail) is
      # recoverable through EmailVerificationsController#create.
      RegistrationsMailer.verify_email(user).deliver_later if user.persisted?

      user
    rescue ActiveRecord::RecordNotUnique
      # Two concurrent signups for the same address can both pass the uniqueness validation; the
      # unique index is the real guard. Present it as a form error, not a 500.
      user.errors.add(:email, "has already been taken")

      user
    end

    private

    def registrable(attributes)
      attributes.to_h.symbolize_keys.slice(*REGISTRABLE_ATTRIBUTES)
    end
  end
end
