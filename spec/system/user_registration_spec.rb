# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Registration: sign up, confirm the emailed link, sign in", type: :system do
  let(:email) { "nina_newcomer@example.com" }
  let(:name) { "Nina Newcomer" }
  let(:password) { "foobar1234" }

  before { ActionMailer::Base.deliveries.clear }

  # The request specs cover each hop of this flow in isolation. This one exists for the seams
  # between them -- above all the verification URL, which is generated inside a mailer view and
  # therefore cannot be reached by anything short of rendering and following the actual mail.
  it "carries a visitor from the login page to a confirmed, usable account" do
    # 1. The way in. A signup funnel nobody can find from the login page is not a funnel.
    visit login_url
    click_link "Create an account"

    expect(page).to have_current_path(new_registration_path, ignore_query: true)

    # 2. Register.
    fill_in "user[name]", with: name
    fill_in "user[email]", with: email
    fill_in "user[password]", with: password
    click_button "Create your account"

    expect(page).to have_text("Welcome! Please check your email to confirm your address.")

    user = User.find_by(email: email)
    expect(user).to be_present
    expect(user).not_to be_email_verified

    # 3. Deliver the mail that registration enqueued.
    perform_enqueued_mail

    mail = ActionMailer::Base.deliveries.last
    expect(mail.to).to eq([email])
    expect(mail.subject).to eq("Please confirm your email address")

    # 4. Follow the link out of that mail, exactly as its recipient would.
    verification_url = verification_url_from(mail)
    expect(verification_url).to be_present

    visit verification_url

    expect(page).to have_text("Your email address is confirmed. Please sign in.")
    expect(user.reload).to be_email_verified

    # 5. The account works: confirmation lands on the login form, and the credentials signed up
    #    with are the credentials that get in.
    fill_in :email, with: email
    fill_in :password, with: password
    click_button "Login"

    expect(page).to have_text("👤 #{name}")
    expect(page).to have_link("Logout")
  end

  private

  # `deliver_later` enqueues into SolidQueue, and no worker runs during specs. Running the job here
  # is deliberate: minting a token by hand instead would reach past the mailer and skip the one
  # thing this spec is for.
  def perform_enqueued_mail
    ActiveJob::Base.execute(SolidQueue::Job.last.arguments)
  end

  def verification_url_from(mail)
    body = (mail.text_part || mail).decoded

    body[%r{https?://\S+/email_verification/[^\s"'<]+}]
  end
end
